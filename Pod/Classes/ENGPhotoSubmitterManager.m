//
//  ENGPhotoSubmitterManager.m
//
//  Created by ISHITOYA Kentaro on 11/12/13.
//

#import <objc/runtime.h>
#import <objc/message.h>
#import "FBNetworkReachability.h"
#import "RegexKitLite.h"
#import "ENGPhotoSubmitterManager.h"
#import "ENGPhotoSubmitterFactory.h"
#import "ENGPhotoSubmitterSettings.h"
#import "ENGPhotoSubmitterAccountManager.h"

#define PS_OPERATIONS @"PSOperations"

/*!
 * singleton instance
 */
static ENGPhotoSubmitterManager* PhotoSubmitterSingletonInstance_ = nil;
/*!
 * custom schema suffix value
 */
static NSString *PhotoSubmitterCustomSchemaSuffix_ = @"";

/*!
 * photo submitter supported types
 */
static NSMutableArray* registeredPhotoSubmitterTypes = nil;

//-----------------------------------------------------------------------------
//Private Implementations
//-----------------------------------------------------------------------------
@interface ENGPhotoSubmitterManager(PrivateImplementation)
- (void) setupInitialState;
- (void) addOperation: (ENGPhotoSubmitterOperation *)operation;
- (ENGPhotoSubmitterSequencialOperationQueue *) sequencialOperationQueueForType: (NSString *) type;
- (void) pauseFinished;
- (void) didChangeNetworkReachability:(NSNotification*)notification;
@end

@implementation ENGPhotoSubmitterManager(PrivateImplementation)
/*!
 * initialize
 */
-(void)setupInitialState{
    submitters_ = [[NSMutableDictionary alloc] init];
    operations_ = [[NSMutableDictionary alloc] init];
    delegates_ = [[NSMutableArray alloc] init];
    photoDelegates_ = [[NSMutableArray alloc] init];
    sequencialOperationQueues_ = [[NSMutableDictionary alloc] init];

    operationQueue_ = [[NSOperationQueue alloc] init];
    operationQueue_.maxConcurrentOperationCount = 6;
    self.submitPhotoWithOperations = NO;
    isPausingOperation_ = NO;
    
    [[NSNotificationCenter defaultCenter]
     addObserver:self
     selector:@selector(didChangeNetworkReachability:)
     name:FBNetworkReachabilityDidChangeNotification
     object:nil];
    if([FBNetworkReachability sharedInstance].connectionMode == FBNetworkReachableNon){
        isConnected_ = NO;
    }else{
        isConnected_ = YES;
    }
    [[FBNetworkReachability sharedInstance] startNotifier];
}

/*!
 * get sequenctial operation queue for type
 */
- (ENGPhotoSubmitterSequencialOperationQueue *)sequencialOperationQueueForType:(NSString *)type{
    ENGPhotoSubmitterSequencialOperationQueue *queue = 
        [sequencialOperationQueues_ objectForKey:type];
    if(queue == nil){
        queue = [[ENGPhotoSubmitterSequencialOperationQueue alloc] initWithPhotoSubmitterType:type andDelegate:self];
        [sequencialOperationQueues_ setObject:queue forKey:type];
    }
    return queue;
}

/*!
 * add operation
 */
- (void)addOperation:(ENGPhotoSubmitterOperation *)operation{
    [operation addDelegate: self];
    [operations_ setObject:operation forKey:[NSNumber numberWithInteger:operation.hash]];
    
    if(isConnected_){
        if(operation.submitter.isSequencial){
            ENGPhotoSubmitterSequencialOperationQueue *queue = [self sequencialOperationQueueForType:operation.submitter.type];
            [queue enqueue:operation];
        }else{
            [operationQueue_ addOperation:operation];
        }
    }
    for(id<ENGPhotoSubmitterManagerDelegate> delegate in delegates_){
        [delegate photoSubmitterManager:self didOperationAdded:operation];
    }
}

/*!
 * cancel operation finished
 */
- (void)pauseFinished{
    isPausingOperation_ = NO;
}

/*!
 * check for connection
 */
- (void)didChangeNetworkReachability:(NSNotification *)notification
{
    FBNetworkReachability *reachability = (FBNetworkReachability *)[notification object];
    BOOL oldValue = isConnected_;
    isConnected_ = (reachability.connectionMode != FBNetworkReachableNon);
    if(oldValue == NO && isConnected_){
        [self restart];
    }else if(oldValue == YES && isConnected_ == NO){
        [self pause];
    }
}
@end

//-----------------------------------------------------------------------------
//Public Implementations
//-----------------------------------------------------------------------------

@implementation ENGPhotoSubmitterManager
@synthesize submitPhotoWithOperations;
@synthesize location = location_;
@synthesize isUploading;
@synthesize isError = isError_;
@synthesize isSquarePhotoRequired;
@synthesize errorOperationCount = errorOperationCount_;
@synthesize isPausingOperation = isPausingOperation_;
@synthesize navigationControllerDelegate;
@synthesize settingViewFactory;
@synthesize submitters;
@dynamic authenticationDelegate;

/*!
 * initializer
 */
- (id)init{
    self = [super init];
    if(self){
        [self setupInitialState];
    }
    return self;
}

/*!
 * get submitter
 */
- (id<ENGPhotoSubmitterProtocol>)submitterForAccount:(ENGPhotoSubmitterAccount *)account{
    id <ENGPhotoSubmitterProtocol> submitter = [submitters_ objectForKey:account.accountHash];
    if(submitter){
        return submitter;
    }
    submitter = [ENGPhotoSubmitterFactory createWithAccount:account];
    if(submitter == nil){
        for(NSString *type in registeredPhotoSubmitterTypes){
            if([type isEqualToString:account.type]){
                @throw [[NSException alloc] initWithName:@"PhotoSubmitterNotFoundException" reason:[NSString stringWithFormat:@"type %@ not found.", account.type] userInfo:nil];       
            }else{
                //if PhotoSubmitter not found because unregistered, remove the account from manage.
                [[ENGPhotoSubmitterAccountManager sharedManager] removeAccount:account];
                return nil;
            }
        }
    }
    if(submitter){
        [submitters_ setObject:submitter forKey:account.accountHash];
    }
    [submitter addPhotoDelegate:self];
    for(id<ENGPhotoSubmitterPhotoDelegate> d in photoDelegates_){
        [submitter addPhotoDelegate:d];
    }
    if(authDelegate_){
        submitter.authDelegate = authDelegate_;
    }
    return submitter;
}

/*!
 * remove submitter
 */
- (void)removeSubmitterForAccount:(ENGPhotoSubmitterAccount *)account{
    if([submitters_ objectForKey:account.accountHash]){
        [submitters_ removeObjectForKey:account.accountHash];
        [[ENGPhotoSubmitterAccountManager sharedManager] removeAccount:account];
    }
}

/*!
 * submitter for type
 */
- (NSArray *)submittersForType:(NSString *)type{
    NSArray *accounts = [[ENGPhotoSubmitterAccountManager sharedManager] accountsForType:type];
    NSMutableArray *typedAccounts = [[NSMutableArray alloc] init];
    for(ENGPhotoSubmitterAccount *account in accounts){
        if([submitters_ objectForKey:account.accountHash]){
            [typedAccounts addObject:[submitters_ objectForKey:account.accountHash]];
        }
    }
    return typedAccounts;
}

/*!
 * submit photo to social app
 */
- (void)submitPhoto:(ENGPhotoSubmitterImageEntity *)photo{
    @try{
        if(self.enableGeoTagging){
            photo.location = self.location;
        }
        [photo preprocess];
        NSArray *accounts = [ENGPhotoSubmitterAccountManager sharedManager].accounts;
        for(ENGPhotoSubmitterAccount *account in accounts){
            id<ENGPhotoSubmitterProtocol> submitter = [ENGPhotoSubmitterManager submitterForAccount:account];
            if(submitter.isPhotoSupported && [submitter isLogined]){
                if(self.submitPhotoWithOperations && submitter.useOperation){
                    ENGPhotoSubmitterOperation *operation = [[ENGPhotoSubmitterOperation alloc] initWithSubmitter:submitter andContent:photo];
                    [self addOperation:operation];
                }else{
                    [submitter submitPhoto:photo andOperationDelegate:nil];
                }
            }
        }
    }@catch(NSException *e){
        NSLog(@"%@", e);
    }
}

/*!
 * submit photo to social app
 */
- (void)submitVideo:(ENGPhotoSubmitterVideoEntity *)video{
    @try{
        if(self.enableGeoTagging){
            video.location = self.location;
        }
        NSArray *accounts = [ENGPhotoSubmitterAccountManager sharedManager].accounts;
        for(ENGPhotoSubmitterAccount *account in accounts){
            id<ENGPhotoSubmitterProtocol> submitter = [ENGPhotoSubmitterManager submitterForAccount:account];
            if(submitter.isVideoSupported && [submitter isLogined]){
                if(self.submitPhotoWithOperations && submitter.useOperation){
                    ENGPhotoSubmitterOperation *operation = [[ENGPhotoSubmitterOperation alloc] initWithSubmitter:submitter andContent:video];
                    [self addOperation:operation];
                }else{
                    [submitter submitVideo:video andOperationDelegate:nil];
                }
            }
        }
    }@catch(NSException *e){
        NSLog(@"%@", e);
    }
}

/*!
 * set authentication delegate to submitters
 */
- (void)setAuthenticationDelegate:(id<ENGPhotoSubmitterAuthenticationDelegate>)delegate{
    NSArray *accounts = [ENGPhotoSubmitterAccountManager sharedManager].accounts;
    authDelegate_ = delegate;
    for(ENGPhotoSubmitterAccount *account in accounts){
        id<ENGPhotoSubmitterProtocol> submitter = [ENGPhotoSubmitterManager submitterForAccount:account];
        submitter.authDelegate = delegate;
    }
}

/*!
 * load selected submitters
 */
- (void)loadSubmitters{
    registeredPhotoSubmitterTypes = [[NSMutableArray alloc] init];
    
    int numClasses;
    Class *classes = NULL;
    
    classes = NULL;
    numClasses = objc_getClassList(NULL, 0);
    
    if (numClasses > 0 )
    {
        classes = (__unsafe_unretained Class *)malloc(sizeof(Class) * numClasses);
        numClasses = objc_getClassList(classes, numClasses);
        for (int i = 0; i < numClasses; i++) {
            Class cls = classes[i];
            NSString *className = [NSString stringWithUTF8String:class_getName(cls)];
            if([className isMatchedByRegex:@"^(.+?)PhotoSubmitter$"]){
                [registeredPhotoSubmitterTypes addObject:className];
            }
        }
        free(classes);
    }
    
    for(NSString *type in registeredPhotoSubmitterTypes){
        NSArray *accounts = [[ENGPhotoSubmitterAccountManager sharedManager] accountsForType:type];
        if(accounts.count){
            for(ENGPhotoSubmitterAccount *account in accounts){
                [self submitterForAccount:account];
            }
        }else{
            ENGPhotoSubmitterAccount *account = [[ENGPhotoSubmitterAccountManager sharedManager] createAccountForType:type];
            [self submitterForAccount:account];            
        }
    }
}

/*!
 * refresh credentials
 */
- (void)refreshCredentials{
    @try{
        NSArray *accounts = [ENGPhotoSubmitterAccountManager sharedManager].accounts;
        for(ENGPhotoSubmitterAccount *account in accounts){
            id<ENGPhotoSubmitterProtocol> submitter = [ENGPhotoSubmitterManager submitterForAccount:account];
            if([submitter isEnabled]){
                [submitter refreshCredential];
            }
        }
    }@catch(NSException *e){
        NSLog(@"%@", e);
    }

}

/*!
 * on url loaded
 */
- (BOOL)didOpenURL:(NSURL *)url{
    NSArray *accounts = [ENGPhotoSubmitterAccountManager sharedManager].accounts;
    for(ENGPhotoSubmitterAccount *account in accounts){
        id<ENGPhotoSubmitterProtocol> submitter = [ENGPhotoSubmitterManager submitterForAccount:account];
        if([submitter isProcessableURL:url]){
            return [submitter didOpenURL:url];
        }
    }
    return NO; 
}

/*!
 * get uploadOperationCount
 */
- (NSInteger)uploadOperationCount{
    return [operations_ count];
}

/*!
 * get number of enabled Submitters
 */
- (NSInteger)enabledSubmitterCount{
    NSInteger i = 0;
    NSArray *accounts = [ENGPhotoSubmitterAccountManager sharedManager].accounts;
    for(ENGPhotoSubmitterAccount *account in accounts){
        id<ENGPhotoSubmitterProtocol> submitter = [ENGPhotoSubmitterManager submitterForAccount:account];
        if(submitter.isLogined){
            i++;
        }
    }
    return i;
}

/*!
 * geo tagging enabled
 */
- (BOOL)enableGeoTagging{
    return geoTaggingEnabled_; 
}

/*!
 * check is uploading
 */
- (BOOL)isUploading{
    if(operations_.count != 0){
        for(NSNumber *key in operations_){
            ENGPhotoSubmitterOperation *operation = [operations_ objectForKey:key];
            if(operation.isExecuting && operation.isCancelled == NO && 
               operation.isFailed == NO){
                return YES;
            }
        }
    }
    for(NSNumber *key in sequencialOperationQueues_){
        ENGPhotoSubmitterSequencialOperationQueue *queue = [sequencialOperationQueues_ objectForKey:key];
        if(queue.count != 0){
            
            return YES;
        }
    }
    return NO;
}

/*!
 * set enable geo tagging
 */
- (void)setEnableGeoTagging:(BOOL)enableGeoTagging{
    if(locationManager_ == nil){
        locationManager_ = [[CLLocationManager alloc] init];
        locationManager_.delegate = self;
        locationManager_.desiredAccuracy = kCLLocationAccuracyBest;
        locationManager_.distanceFilter = kCLDistanceFilterNone; 
        if(enableGeoTagging){
            [locationManager_ startUpdatingLocation];
        }
    }else if(enableGeoTagging != geoTaggingEnabled_){
        if(enableGeoTagging){
            [locationManager_ startUpdatingLocation];
        }else{
            [locationManager_ stopUpdatingLocation];
        }
    }
    geoTaggingEnabled_ = enableGeoTagging;
}

/*!
 * location did changed
 */
- (void)locationManager:(CLLocationManager *)manager didUpdateToLocation:(CLLocation *)newLocation fromLocation:(CLLocation *)oldLocation{
    location_ = newLocation;
    //NSLog(@"%@, %@", location_.coordinate.longitude, location_.coordinate.latitude);
}

/*!
 * requires network
 */
- (BOOL)requiresNetwork{
    NSArray *accounts = [ENGPhotoSubmitterAccountManager sharedManager].accounts;
    for(ENGPhotoSubmitterAccount *account in accounts){
        id<ENGPhotoSubmitterProtocol> submitter = [ENGPhotoSubmitterManager submitterForAccount:account];
        if(submitter.isEnabled && submitter.requiresNetwork){
            return YES;
        }
    }
    return NO;
}

/*!
 * max comment length
 */
- (NSInteger)maxCommentLength{
    NSInteger max = 0;
    NSArray *accounts = [ENGPhotoSubmitterAccountManager sharedManager].accounts;
    for(ENGPhotoSubmitterAccount *account in accounts){
        id<ENGPhotoSubmitterProtocol> submitter = [ENGPhotoSubmitterManager submitterForAccount:account];
        if(submitter.isEnabled && submitter.requiresNetwork &&
           submitter.maximumLengthOfComment > max){
            max = submitter.maximumLengthOfComment;
        }
    }
    return max;
    
}

/*!
 * is square photo required
 */
- (BOOL)isSquarePhotoRequired{
    NSArray *accounts = [ENGPhotoSubmitterAccountManager sharedManager].accounts;
    for(ENGPhotoSubmitterAccount *account in accounts){
        id<ENGPhotoSubmitterProtocol> submitter = [ENGPhotoSubmitterManager submitterForAccount:account];
        if(submitter.isEnabled && submitter.isSquare){
            return YES;
        }
    }
    return NO;
    
}

/*!
 * submitters
 */
- (NSArray *)submitters{
    return [submitters_ allValues];
}

#pragma mark -
#pragma mark PhotoSubmitterPhotoDelegate methods
/*!
 * upload started
 */
- (void)photoSubmitter:(id<ENGPhotoSubmitterProtocol>)photoSubmitter willStartUpload:(NSString *)imageHash{
    //NSLog(@"start");
}

/*!
 * upload finished
 */
- (void)photoSubmitter:(id<ENGPhotoSubmitterProtocol>)photoSubmitter didSubmitted:(NSString *)imageHash suceeded:(BOOL)suceeded message:(NSString *)message{
    if(suceeded == NO){
        isError_ = YES;
        errorOperationCount_ += 1;
    }
    //NSLog(@"submitted");
}

/*!
 * progress changed
 */
- (void)photoSubmitter:(id<ENGPhotoSubmitterProtocol>)photoSubmitter didProgressChanged:(NSString *)imageHash progress:(CGFloat)progress{
    //NSLog(@"progress:%f", progress);
}

/*!
 * upload canceled
 */
- (void)photoSubmitter:(id<ENGPhotoSubmitterProtocol>)photoSubmitter didCanceled:(NSString *)imageHash{
    
}

#pragma mark -
#pragma mark operation delegate
/*!
 * operation finished
 */
- (void)photoSubmitterOperation:(ENGPhotoSubmitterOperation *)operation didFinished:(BOOL)suceeeded{
    if(suceeeded){
        [operations_ removeObjectForKey:[NSNumber numberWithInteger:operation.hash]];
    }else if(self.isUploading == NO){
        for(id<ENGPhotoSubmitterManagerDelegate> delegate in delegates_){
            [delegate didUploadCanceled];
        }
    }
}

/*!
 * operation canceled
 */
- (void)photoSubmitterOperationDidCanceled:(ENGPhotoSubmitterOperation *)operation{
    if(self.isUploading == NO){
        for(id<ENGPhotoSubmitterManagerDelegate> delegate in delegates_){
            [delegate didUploadCanceled];
        }
    }
}

#pragma mark -
#pragma mark suspend
/*!
 * save operations and suspend
 */
- (void)suspend{
    if(operations_.count == 0){
        return;
    }
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];    
    NSData *data = [NSKeyedArchiver archivedDataWithRootObject:operations_];
    [defaults setValue:data forKey:PS_OPERATIONS];
    [defaults synchronize];
}

/*!
 * load operations and wakeup
 */
- (void)wakeup{
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    NSData *data = [defaults valueForKey:PS_OPERATIONS];
    if(data == nil){
        return;
    }
    [defaults removeObjectForKey:PS_OPERATIONS];
    [defaults synchronize];
    NSMutableDictionary *ops = [NSKeyedUnarchiver unarchiveObjectWithData:data];
    for(NSNumber *key in ops){
        ENGPhotoSubmitterOperation *operation = [ops objectForKey:key];
        [self addOperation:operation];
    }
}

/*!
 * pause
 */
- (void) pause{
    if(isPausingOperation_){
        return;
    }
    isPausingOperation_ = YES;
    [operationQueue_ cancelAllOperations];
    for(NSNumber *key in operations_){
        ENGPhotoSubmitterOperation *operation = [operations_ objectForKey:key];
        [operation pause];
    }
    for(NSNumber *key in sequencialOperationQueues_){
        ENGPhotoSubmitterSequencialOperationQueue *queue = [sequencialOperationQueues_ objectForKey:key];
        [queue cancel];
    }
    
    [self performSelector:@selector(pauseFinished) withObject:nil afterDelay:2];
}

/*!
 * cancel
 */
- (void) cancel{
    for(NSNumber *key in sequencialOperationQueues_){
        ENGPhotoSubmitterSequencialOperationQueue *queue = [sequencialOperationQueues_ objectForKey:key];
        [queue cancel];
    }
    errorOperationCount_ = 0;
    isError_ = NO;
    [sequencialOperationQueues_ removeAllObjects];
    [operationQueue_ cancelAllOperations];
    [operations_ removeAllObjects];
    for(id<ENGPhotoSubmitterManagerDelegate> delegate in delegates_){
        [delegate didUploadCanceled];
    }
}

/*!
 * restart operations
 */
- (void)restart{
    if(isPausingOperation_){
        return;
    }
    errorOperationCount_ = 0;
    isError_ = NO;
    [operationQueue_ cancelAllOperations];
    operationQueue_ = [[NSOperationQueue alloc] init];
    operationQueue_.maxConcurrentOperationCount = 6;
    NSMutableDictionary *ops = operations_;
    operations_ = [[NSMutableDictionary alloc] init];
    for(NSNumber *key in ops){
        ENGPhotoSubmitterOperation *operation = [ENGPhotoSubmitterOperation operationWithOperation:[ops objectForKey:key]];
        [operation resume];
        [self addOperation:operation];
    }
}


#pragma mark -
#pragma mark PhotoSubmitterSequencialOperationQueue delegate
/*!
 * did sequencial operation queue peeked next operation
 */
- (void)sequencialOperationQueue:(ENGPhotoSubmitterSequencialOperationQueue *)sequencialOperationQueue didPeeked:(ENGPhotoSubmitterOperation *)operation{    
    if(operation.isCancelled){
        return;
    }
    [operationQueue_ addOperation:operation];
}

#pragma mark -
#pragma mark delegate methods

/*!
 * add delegate
 */
- (void)addDelegate:(id<ENGPhotoSubmitterManagerDelegate>)delegate{
    if([delegates_ containsObject:delegate]){
        return;
    }
    [delegates_ addObject:delegate];
}

/*!
 * remove delegate
 */
- (void)removeDelegate:(id<ENGPhotoSubmitterManagerDelegate>)delegate{
    [delegates_ removeObject:delegate];
}

/*!
 * clear delegate
 */
- (void)clearDelegate{
    [delegates_ removeAllObjects];
}

/*!
 * add photo delegate
 */
- (void)addPhotoDelegate:(id<ENGPhotoSubmitterPhotoDelegate>)photoDelegate{
    if([photoDelegates_ containsObject:photoDelegate]){
        return;
    }
    [photoDelegates_ addObject:photoDelegate];
    NSArray *accounts = [ENGPhotoSubmitterAccountManager sharedManager].accounts;
    for(ENGPhotoSubmitterAccount *account in accounts){
        id<ENGPhotoSubmitterProtocol> submitter = [ENGPhotoSubmitterManager submitterForAccount:account];
        if(submitter == nil){
            continue;
        }
        for(id<ENGPhotoSubmitterPhotoDelegate> d in photoDelegates_){
            [submitter addPhotoDelegate:d];
        }
    }
}

/*!
 * remove photo delegate
 */
- (void)removePhotoDelegate: (id<ENGPhotoSubmitterPhotoDelegate>)photoDelegate{
    [photoDelegates_ removeObject:photoDelegate];
}

/*!
 * clear photo delegate
 */
- (void)clearPhotoDelegate{
    [photoDelegates_ removeAllObjects];
}


#pragma mark -
#pragma mark static methods
/*!
 * singleton method
 */
+ (ENGPhotoSubmitterManager *)sharedInstance{
    if(PhotoSubmitterSingletonInstance_ == nil){
        PhotoSubmitterSingletonInstance_ = [[ENGPhotoSubmitterManager alloc] init];
        [PhotoSubmitterSingletonInstance_ loadSubmitters];
    }
    return PhotoSubmitterSingletonInstance_;
}

/*!
 * get PhotoSubmitter's custom schema suffix
 */
+ (NSString *)photoSubmitterCustomSchemaSuffix{
    return PhotoSubmitterCustomSchemaSuffix_;
}

/*!
 * set PhotoSubmitter's custom schema suffix
 */
+ (void)setPhotoSubmitterCustomSchemaSuffix:(NSString *)suffix{
    PhotoSubmitterCustomSchemaSuffix_ = suffix;
}

/*!
 * get submitter
 */
+ (id<ENGPhotoSubmitterProtocol>)submitterForAccount:(ENGPhotoSubmitterAccount *)account{
    return [[ENGPhotoSubmitterManager sharedInstance] submitterForAccount:account];
}

+ (void) removeSubmitterForAccount:(ENGPhotoSubmitterAccount *)account{
    [[ENGPhotoSubmitterManager sharedInstance] removeSubmitterForAccount:account];
}

/*!
 * photo submitter count
 */
+ (NSInteger)registeredPhotoSubmitterCount{
    [self sharedInstance];
    return registeredPhotoSubmitterTypes.count;
}

/*!
 * get photo submitters
 */
+ (NSArray *)registeredPhotoSubmitters{
    [self sharedInstance];
    return registeredPhotoSubmitterTypes;
}

/*!
 * unregister all submitters
 */
+ (void) unregisterAllPhotoSubmitters{
    [self sharedInstance];
    [registeredPhotoSubmitterTypes removeAllObjects];
}

/*!
 * unregister submitter with type
 */
+ (void) unregisterPhotoSubmitterWithTypeName:(NSString *)type{
    [self sharedInstance];
    int i = 0;
    int found = -1;
    type = [ENGPhotoSubmitterManager normalizeTypeName:type];
    
    for(NSString *t in registeredPhotoSubmitterTypes){
        if([t isEqualToString:type]){
            found = i;
        }
    }
    if(found != -1){
        [registeredPhotoSubmitterTypes removeObjectAtIndex:found];
    }
}

/*!
 * register photo submitter with type name
 */
+ (void)registerPhotoSubmitterWithTypeName:(NSString *)type{
    [self sharedInstance];
    type = [ENGPhotoSubmitterManager normalizeTypeName:type];
    
    for(NSString * t in registeredPhotoSubmitterTypes){
        if([t isEqualToString:type]){
            //already registered
            return;
        }
    }
        
    [registeredPhotoSubmitterTypes addObject:type];
}

/*!
 * register submitters with array of NSString type names
 */
+ (void)registerPhotoSubmitterWithTypeNames:(NSArray *)types{
    for(NSString *type in types){
        [ENGPhotoSubmitterManager registerPhotoSubmitterWithTypeName:type];
    }
}

/*!
 * return normalized typename
 */
+ (NSString *)normalizeTypeName:(NSString *)type{
    if([type isMatchedByRegex:@"^(.+?)PhotoSubmitter$"] == NO){
        type = [NSString stringWithFormat:@"%@PhotoSubmitter", [type capitalizedString]];
    }
    return type;
}

/*!
 * check if submitter for type enabled
 */
+ (BOOL)isSubmitterEnabledForType:(NSString *)type{
    type = [ENGPhotoSubmitterManager normalizeTypeName:type];
    ENGPhotoSubmitterManager *manager = [ENGPhotoSubmitterManager sharedInstance];
    NSArray *submitters = [manager submittersForType:type];
    for(id<ENGPhotoSubmitterProtocol> submitter in submitters){
        if(submitter.isLogined){
            return YES;
        }
    }
    return NO;
}
@end
