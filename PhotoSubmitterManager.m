//
//  PhotoSubmitter.m
//  tottepost
//
//  Created by ISHITOYA Kentaro on 11/12/13.
//  Copyright (c) 2011 cocotomo. All rights reserved.
//

#if ! __has_feature(objc_arc)
#error This file must be compiled with ARC. Use -fobjc-arc flag (or convert project to ARC).
#endif

#import <objc/runtime.h>
#import <objc/message.h>
#import "PhotoSubmitterManager.h"
#import "PhotoSubmitterFactory.h"
#import "FBNetworkReachability.h"
#import "RegexKitLite.h"
#import "PhotoSubmitterSettings.h"
#import "PhotoSubmitterAccountManager.h"

#define PS_OPERATIONS @"PSOperations"

/*!
 * singleton instance
 */
static PhotoSubmitterManager* PhotoSubmitterSingletonInstance_ = nil;
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
@interface PhotoSubmitterManager(PrivateImplementation)
- (void) setupInitialState;
- (void) addOperation: (PhotoSubmitterOperation *)operation;
- (PhotoSubmitterSequencialOperationQueue *) sequencialOperationQueueForType: (NSString *) type;
- (void) pauseFinished;
- (void) didChangeNetworkReachability:(NSNotification*)notification;
@end

@implementation PhotoSubmitterManager(PrivateImplementation)
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
- (PhotoSubmitterSequencialOperationQueue *)sequencialOperationQueueForType:(NSString *)type{
    PhotoSubmitterSequencialOperationQueue *queue = 
        [sequencialOperationQueues_ objectForKey:type];
    if(queue == nil){
        queue = [[PhotoSubmitterSequencialOperationQueue alloc] initWithPhotoSubmitterType:type andDelegate:self];
        [sequencialOperationQueues_ setObject:queue forKey:type];
    }
    return queue;
}

/*!
 * add operation
 */
- (void)addOperation:(PhotoSubmitterOperation *)operation{
    [operation addDelegate: self];
    [operations_ setObject:operation forKey:[NSNumber numberWithInt:operation.hash]];
    
    if(isConnected_){
        if(operation.submitter.isSequencial){
            PhotoSubmitterSequencialOperationQueue *queue = [self sequencialOperationQueueForType:operation.submitter.type];
            [queue enqueue:operation];
        }else{
            [operationQueue_ addOperation:operation];
        }
    }
    for(id<PhotoSubmitterManagerDelegate> delegate in delegates_){
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

@implementation PhotoSubmitterManager
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
- (id<PhotoSubmitterProtocol>)submitterForAccount:(PhotoSubmitterAccount *)account{
    id <PhotoSubmitterProtocol> submitter = [submitters_ objectForKey:account.accountHash];
    if(submitter){
        return submitter;
    }
    submitter = [PhotoSubmitterFactory createWithAccount:account];
    if(submitter == nil){
        for(NSString *type in registeredPhotoSubmitterTypes){
            if([type isEqualToString:account.type]){
                @throw [[NSException alloc] initWithName:@"PhotoSubmitterNotFoundException" reason:[NSString stringWithFormat:@"type %@ not found.", account.type] userInfo:nil];       
            }else{
                //if PhotoSubmitter not found because unregistered, remove the account from manage.
                [[PhotoSubmitterAccountManager sharedManager] removeAccount:account];
                return nil;
            }
        }
    }
    if(submitter){
        [submitters_ setObject:submitter forKey:account.accountHash];
    }
    [submitter addPhotoDelegate:self];
    for(id<PhotoSubmitterPhotoDelegate> d in photoDelegates_){
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
- (void)removeSubmitterForAccount:(PhotoSubmitterAccount *)account{
    if([submitters_ objectForKey:account.accountHash]){
        [submitters_ removeObjectForKey:account.accountHash];
        [[PhotoSubmitterAccountManager sharedManager] removeAccount:account];
    }
}

/*!
 * submitter for type
 */
- (NSArray *)submittersForType:(NSString *)type{
    NSArray *accounts = [[PhotoSubmitterAccountManager sharedManager] accountsForType:type];
    NSMutableArray *typedAccounts = [[NSMutableArray alloc] init];
    for(PhotoSubmitterAccount *account in accounts){
        if([submitters_ objectForKey:account.accountHash]){
            [typedAccounts addObject:[submitters_ objectForKey:account.accountHash]];
        }
    }
    return typedAccounts;
}

/*!
 * submit photo to social app
 */
- (void)submitPhoto:(PhotoSubmitterImageEntity *)photo{
    @try{
        if(self.enableGeoTagging){
            photo.location = self.location;
        }
        [photo preprocess];
        NSArray *accounts = [PhotoSubmitterAccountManager sharedManager].accounts;
        for(PhotoSubmitterAccount *account in accounts){
            id<PhotoSubmitterProtocol> submitter = [PhotoSubmitterManager submitterForAccount:account];
            if(submitter.isPhotoSupported && [submitter isLogined]){
                if(self.submitPhotoWithOperations && submitter.useOperation){
                    PhotoSubmitterOperation *operation = [[PhotoSubmitterOperation alloc] initWithSubmitter:submitter andContent:photo];
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
- (void)submitVideo:(PhotoSubmitterVideoEntity *)video{
    @try{
        if(self.enableGeoTagging){
            video.location = self.location;
        }
        NSArray *accounts = [PhotoSubmitterAccountManager sharedManager].accounts;
        for(PhotoSubmitterAccount *account in accounts){
            id<PhotoSubmitterProtocol> submitter = [PhotoSubmitterManager submitterForAccount:account];
            if(submitter.isVideoSupported && [submitter isLogined]){
                if(self.submitPhotoWithOperations && submitter.useOperation){
                    PhotoSubmitterOperation *operation = [[PhotoSubmitterOperation alloc] initWithSubmitter:submitter andContent:video];
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
- (void)setAuthenticationDelegate:(id<PhotoSubmitterAuthenticationDelegate>)delegate{
    NSArray *accounts = [PhotoSubmitterAccountManager sharedManager].accounts;
    authDelegate_ = delegate;
    for(PhotoSubmitterAccount *account in accounts){
        id<PhotoSubmitterProtocol> submitter = [PhotoSubmitterManager submitterForAccount:account];
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
        NSArray *accounts = [[PhotoSubmitterAccountManager sharedManager] accountsForType:type];
        if(accounts.count){
            for(PhotoSubmitterAccount *account in accounts){
                [self submitterForAccount:account];
            }
        }else{
            PhotoSubmitterAccount *account = [[PhotoSubmitterAccountManager sharedManager] createAccountForType:type];
            [self submitterForAccount:account];            
        }
    }
}

/*!
 * refresh credentials
 */
- (void)refreshCredentials{
    @try{
        NSArray *accounts = [PhotoSubmitterAccountManager sharedManager].accounts;
        for(PhotoSubmitterAccount *account in accounts){
            id<PhotoSubmitterProtocol> submitter = [PhotoSubmitterManager submitterForAccount:account];
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
    NSArray *accounts = [PhotoSubmitterAccountManager sharedManager].accounts;
    for(PhotoSubmitterAccount *account in accounts){
        id<PhotoSubmitterProtocol> submitter = [PhotoSubmitterManager submitterForAccount:account];
        if([submitter isProcessableURL:url]){
            return [submitter didOpenURL:url];
        }
    }
    return NO; 
}

/*!
 * get uploadOperationCount
 */
- (int)uploadOperationCount{
    return [operations_ count];
}

/*!
 * get number of enabled Submitters
 */
- (int)enabledSubmitterCount{
    int i = 0;
    NSArray *accounts = [PhotoSubmitterAccountManager sharedManager].accounts;
    for(PhotoSubmitterAccount *account in accounts){
        id<PhotoSubmitterProtocol> submitter = [PhotoSubmitterManager submitterForAccount:account];
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
            PhotoSubmitterOperation *operation = [operations_ objectForKey:key];
            if(operation.isExecuting && operation.isCancelled == NO && 
               operation.isFailed == NO){
                return YES;
            }
        }
    }
    for(NSNumber *key in sequencialOperationQueues_){
        PhotoSubmitterSequencialOperationQueue *queue = [sequencialOperationQueues_ objectForKey:key];
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
    NSArray *accounts = [PhotoSubmitterAccountManager sharedManager].accounts;
    for(PhotoSubmitterAccount *account in accounts){
        id<PhotoSubmitterProtocol> submitter = [PhotoSubmitterManager submitterForAccount:account];
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
    int max = 0;
    NSArray *accounts = [PhotoSubmitterAccountManager sharedManager].accounts;
    for(PhotoSubmitterAccount *account in accounts){
        id<PhotoSubmitterProtocol> submitter = [PhotoSubmitterManager submitterForAccount:account];
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
    NSArray *accounts = [PhotoSubmitterAccountManager sharedManager].accounts;
    for(PhotoSubmitterAccount *account in accounts){
        id<PhotoSubmitterProtocol> submitter = [PhotoSubmitterManager submitterForAccount:account];
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
- (void)photoSubmitter:(id<PhotoSubmitterProtocol>)photoSubmitter willStartUpload:(NSString *)imageHash{
    //NSLog(@"start");
}

/*!
 * upload finished
 */
- (void)photoSubmitter:(id<PhotoSubmitterProtocol>)photoSubmitter didSubmitted:(NSString *)imageHash suceeded:(BOOL)suceeded message:(NSString *)message{
    if(suceeded == NO){
        isError_ = YES;
        errorOperationCount_ += 1;
    }
    //NSLog(@"submitted");
}

/*!
 * progress changed
 */
- (void)photoSubmitter:(id<PhotoSubmitterProtocol>)photoSubmitter didProgressChanged:(NSString *)imageHash progress:(CGFloat)progress{
    //NSLog(@"progress:%f", progress);
}

/*!
 * upload canceled
 */
- (void)photoSubmitter:(id<PhotoSubmitterProtocol>)photoSubmitter didCanceled:(NSString *)imageHash{
    
}

#pragma mark -
#pragma mark operation delegate
/*!
 * operation finished
 */
- (void)photoSubmitterOperation:(PhotoSubmitterOperation *)operation didFinished:(BOOL)suceeeded{
    if(suceeeded){
        [operations_ removeObjectForKey:[NSNumber numberWithInt:operation.hash]];
    }else if(self.isUploading == NO){
        for(id<PhotoSubmitterManagerDelegate> delegate in delegates_){
            [delegate didUploadCanceled];
        }
    }
}

/*!
 * operation canceled
 */
- (void)photoSubmitterOperationDidCanceled:(PhotoSubmitterOperation *)operation{
    if(self.isUploading == NO){
        for(id<PhotoSubmitterManagerDelegate> delegate in delegates_){
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
        PhotoSubmitterOperation *operation = [ops objectForKey:key];
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
        PhotoSubmitterOperation *operation = [operations_ objectForKey:key];
        [operation pause];
    }
    for(NSNumber *key in sequencialOperationQueues_){
        PhotoSubmitterSequencialOperationQueue *queue = [sequencialOperationQueues_ objectForKey:key];
        [queue cancel];
    }
    
    [self performSelector:@selector(pauseFinished) withObject:nil afterDelay:2];
}

/*!
 * cancel
 */
- (void) cancel{
    for(NSNumber *key in sequencialOperationQueues_){
        PhotoSubmitterSequencialOperationQueue *queue = [sequencialOperationQueues_ objectForKey:key];
        [queue cancel];
    }
    errorOperationCount_ = 0;
    isError_ = NO;
    [sequencialOperationQueues_ removeAllObjects];
    [operationQueue_ cancelAllOperations];
    [operations_ removeAllObjects];
    for(id<PhotoSubmitterManagerDelegate> delegate in delegates_){
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
        PhotoSubmitterOperation *operation = [PhotoSubmitterOperation operationWithOperation:[ops objectForKey:key]];
        [operation resume];
        [self addOperation:operation];
    }
}


#pragma mark -
#pragma mark PhotoSubmitterSequencialOperationQueue delegate
/*!
 * did sequencial operation queue peeked next operation
 */
- (void)sequencialOperationQueue:(PhotoSubmitterSequencialOperationQueue *)sequencialOperationQueue didPeeked:(PhotoSubmitterOperation *)operation{    
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
- (void)addDelegate:(id<PhotoSubmitterManagerDelegate>)delegate{
    if([delegates_ containsObject:delegate]){
        return;
    }
    [delegates_ addObject:delegate];
}

/*!
 * remove delegate
 */
- (void)removeDelegate:(id<PhotoSubmitterManagerDelegate>)delegate{
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
- (void)addPhotoDelegate:(id<PhotoSubmitterPhotoDelegate>)photoDelegate{
    if([photoDelegates_ containsObject:photoDelegate]){
        return;
    }
    [photoDelegates_ addObject:photoDelegate];
    NSArray *accounts = [PhotoSubmitterAccountManager sharedManager].accounts;
    for(PhotoSubmitterAccount *account in accounts){
        id<PhotoSubmitterProtocol> submitter = [PhotoSubmitterManager submitterForAccount:account];
        if(submitter == nil){
            continue;
        }
        for(id<PhotoSubmitterPhotoDelegate> d in photoDelegates_){
            [submitter addPhotoDelegate:d];
        }
    }
}

/*!
 * remove photo delegate
 */
- (void)removePhotoDelegate: (id<PhotoSubmitterPhotoDelegate>)photoDelegate{
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
+ (PhotoSubmitterManager *)sharedInstance{
    if(PhotoSubmitterSingletonInstance_ == nil){
        PhotoSubmitterSingletonInstance_ = [[PhotoSubmitterManager alloc] init];
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
+ (id<PhotoSubmitterProtocol>)submitterForAccount:(PhotoSubmitterAccount *)account{
    return [[PhotoSubmitterManager sharedInstance] submitterForAccount:account];
}

+ (void) removeSubmitterForAccount:(PhotoSubmitterAccount *)account{
    [[PhotoSubmitterManager sharedInstance] removeSubmitterForAccount:account];
}

/*!
 * photo submitter count
 */
+ (int)registeredPhotoSubmitterCount{
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
    type = [PhotoSubmitterManager normalizeTypeName:type];
    
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
    type = [PhotoSubmitterManager normalizeTypeName:type];
    
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
        [PhotoSubmitterManager registerPhotoSubmitterWithTypeName:type];
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
    type = [PhotoSubmitterManager normalizeTypeName:type];
    PhotoSubmitterManager *manager = [PhotoSubmitterManager sharedInstance];
    NSArray *submitters = [manager submittersForType:type];
    for(id<PhotoSubmitterProtocol> submitter in submitters){
        if(submitter.isLogined){
            return YES;
        }
    }
    return NO;
}
@end
