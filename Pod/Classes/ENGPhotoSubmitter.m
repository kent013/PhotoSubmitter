//
//  ENGPhotoSubmitter.m
//
//  Created by ISHITOYA Kentaro on 11/12/17.
//

#import <CoreLocation/CoreLocation.h>
#import <objc/runtime.h>
#import <ImageIO/ImageIO.h>
#import "PDKeychainBindings.h"
#import "RegexKitLite.h"
#import "ENGPhotoSubmitter.h"
#import "ENGPhotoSubmitterManager.h"
#import "ENGPhotoSubmitterAccountManager.h"
#import "ENGAlbumPhotoSubmitterSettingTableViewController.h"
#import "ENGSimplePhotoSubmitterSettingTableViewController.h"
#import "UIImage+ENGDigest.h"
#import "UIImage+ENGEXIF.h"

//-----------------------------------------------------------------------------
//Private Implementations
//-----------------------------------------------------------------------------
@interface ENGPhotoSubmitter(PrivateImplementation)
@property (nonatomic, readonly) NSString *keyForEnabled;
@property (nonatomic, readonly) NSString *keyForUsername;
@property (nonatomic, readonly) NSString *keyForAlbums;
@property (nonatomic, readonly) NSString *keyForTargetAlbum;
- (NSString *) getIconImageNameWithSize:(int)size;
- (id<ENGPhotoSubmitterInstanceProtocol>) subclassInstance;
@end

@implementation ENGPhotoSubmitter(PrivateImplementation)
/*!
 * get enabled key
 */
- (NSString *)keyForEnabled{
    return [NSString stringWithFormat:@"PS%@Enabled", self.account.accountHash];
}

/*!
 * get username key
 */
- (NSString *)keyForUsername{
    return [NSString stringWithFormat:@"PS%@Username", self.account.accountHash];
}

/*!
 * get albums key
 */
- (NSString *)keyForAlbums{
    return [NSString stringWithFormat:@"PS%@Albums", self.account.accountHash];
}

/*!
 * get target album key
 */
- (NSString *)keyForTargetAlbum{
    return [NSString stringWithFormat:@"PS%@TargetAlbum", self.account.accountHash];
}

/*!
 * get icon name
 */
- (NSString *)getIconImageNameWithSize:(int)size{
    return [NSString stringWithFormat:@"%@_%d.png", 
            [self.name lowercaseString], size];
}

/*!
 * get subclass instance
 */
- (id<ENGPhotoSubmitterInstanceProtocol>)subclassInstance{
    assert([self conformsToProtocol:@protocol(ENGPhotoSubmitterInstanceProtocol)]);
    return (id<ENGPhotoSubmitterInstanceProtocol>)self;
}
@end

//-----------------------------------------------------------------------------
//Public Implementations
//-----------------------------------------------------------------------------
@implementation ENGPhotoSubmitter
@synthesize isAlbumSupported = isAlbumSupported_;
@synthesize isConcurrent = isConcurrent_;
@synthesize isSequencial = isSequencial_;
@synthesize useOperation = useOperation_;
@synthesize requiresNetwork = requiresNetwork_;
@synthesize account = account_;
@synthesize authDelegate;
@synthesize dataDelegate;
@synthesize albumDelegate;

/*!
 * initialize
 */
- (id)initWithAccount:(ENGPhotoSubmitterAccount *)account{
    self = [super init];
    if(self){
        account_ = account;
        photos_ = [[NSMutableDictionary alloc] init];
        requests_ = [[NSMutableDictionary alloc] init];
        operationDelegates_ = [[NSMutableDictionary alloc] init];
        photoDelegates_ = [[NSMutableArray alloc] init];
        
        [self recoverOldSettings];
    }
    return self;
}

/*!
 * setup flags
 */
- (void)setSubmitterIsConcurrent:(BOOL)isConcurrent isSequencial:(BOOL)isSequencial usesOperation:(BOOL)usesOperation requiresNetwork:(BOOL)requiresNetwork isAlbumSupported:(BOOL)isAlbumSupported{
    isConcurrent_ = isConcurrent;
    isSequencial_ = isSequencial;
    useOperation_ = usesOperation;
    requiresNetwork_ = requiresNetwork;
    isAlbumSupported_ = isAlbumSupported;
}

#pragma mark - PhotoSubmitterProtocol methods
#pragma mark - authorization
/*!
 * login
 */
- (void) login{
    id<ENGPhotoSubmitterInstanceProtocol> instance = [self subclassInstance];
    if(self.isSessionValid){
        [self enable];
        [self.authDelegate photoSubmitter:self didLogin:self.account];
        return;
    }
    [self.authDelegate photoSubmitter:self willBeginAuthorization:self.account];
    [instance onLogin];
}

/*!
 * logout and clear settings
 */
- (void)logout{  
    id<ENGPhotoSubmitterInstanceProtocol> instance = [self subclassInstance];
    [instance onLogout];
    [self clearCredentials];
    [self.authDelegate photoSubmitter:self didLogout:self.account];
}

/*!
 * enable
 */
- (void)enable{
    [self setSetting:[NSNumber numberWithBool:YES] forKey:[self keyForEnabled]];
    [self.authDelegate photoSubmitter:self didLogin:self.account];
}

/*!
 * disable
 */
- (void)disable{
    [self removeSettingForKey:self.keyForEnabled];
    [self.authDelegate photoSubmitter:self didLogout:self.account];
}

/*!
 * is session valid
 */
- (BOOL)isSessionValid{
    NSLog(@"Must be implemented in subclass, %s", __PRETTY_FUNCTION__);
    return NO;
}

/*!
 * check is logined
 */
- (BOOL)isLogined{
    return self.isEnabled && self.isSessionValid;
}

/*!
 * isEnabled
 */
- (BOOL)isEnabled{
    return [[self settingForKey:[self keyForEnabled]] boolValue];
}

/*!
 * check url is processable, we will not use this method in twitter
 */
- (BOOL)isProcessableURL:(NSURL *)url{
    return NO;
}

/*!
 * on open url finished, we will not use this method in twitter
 */
- (BOOL)didOpenURL:(NSURL *)url{
    return NO;
}

/*!
 * clear facebook access token key
 */
- (void)clearCredentials{
    [self removeSettingForKey:[self keyForEnabled]];
    [self removeSettingForKey:[self keyForUsername]];
    [self removeSettingForKey:[self keyForAlbums]];
    [self removeSettingForKey:[self keyForTargetAlbum]];
}

/*!
 * refresh credential
 */
- (void)refreshCredential{
    //do nothing
}

/*!
 * complete login operation and send signal to delegate
 */
- (void)completeLogin{
    [self enable]; //enable signals didLogin
    [self.authDelegate photoSubmitter:self didAuthorizationFinished:self.account];
}

/*!
 * complete login operation and send signal to delegate that login failed
 */
- (void)completeLoginFailed{
    [self clearCredentials];
    [self.authDelegate photoSubmitter:self didLogout:self.account];
    [self.authDelegate photoSubmitter:self didAuthorizationFinished:self.account];
}
/*!
 * complete logout operation and send signal to delegate
 */
- (void)completeLogout{
    [self clearCredentials];
    [self.authDelegate photoSubmitter:self didLogout:self.account];
}

#pragma mark - contents
/*!
 * cancel photo upload
 */
- (void) cancelContentSubmit:(ENGPhotoSubmitterContentEntity *)photo{
    id<ENGPhotoSubmitterInstanceProtocol> instance = [self subclassInstance];
    id request = [instance onCancelContentSubmit:photo];
    id<ENGPhotoSubmitterPhotoOperationDelegate> operationDelegate = [self operationDelegateForRequest:request];
    [operationDelegate photoSubmitterDidOperationCanceled];
    [self photoSubmitter:self didCanceled:photo.contentHash];
    [self clearRequest:request];    
}

/*!
 * complete submit photo operation and send message to delegates.
 */
- (void)completeSubmitContentWithRequest:(id)request{
    NSString *hash = [self photoForRequest:request];
    
    id<ENGPhotoSubmitterPhotoOperationDelegate> operationDelegate = [self operationDelegateForRequest:request];
    [self photoSubmitter:self didSubmitted:hash suceeded:YES message:@"Photo upload succeeded"];
    [operationDelegate photoSubmitterDidOperationFinished:YES];
    
    //delay for Dropbox
    [self performSelector:@selector(clearRequest:) withObject:request afterDelay:2.0];
}

/*!
 * complete submit photo operation and send error message to delegates.
 */
- (void)completeSubmitContentWithRequest:(id)request andError:(NSError *)error{
    NSString *hash = [self photoForRequest:request];
    [self photoSubmitter:self didSubmitted:hash suceeded:NO message:[error localizedDescription]];
    id<ENGPhotoSubmitterPhotoOperationDelegate> operationDelegate = [self operationDelegateForRequest:request];
    [operationDelegate photoSubmitterDidOperationFinished:NO];
    
    //delay for Dropbox
    [self performSelector:@selector(clearRequest:) withObject:request afterDelay:2.0];
}

#pragma mark - photos
/*!
 * submit photo with data, comment and delegate
 */
- (void)submitPhoto:(ENGPhotoSubmitterImageEntity *)photo andOperationDelegate:(id<ENGPhotoSubmitterPhotoOperationDelegate>)delegate{
    id<ENGPhotoSubmitterInstanceProtocol> instance = [self subclassInstance];
    
    if(delegate.isCancelled){
        return;
    }
    id request = [instance onSubmitPhoto:photo andOperationDelegate:(id<ENGPhotoSubmitterPhotoOperationDelegate>)delegate];
    if(request == nil){
        return;
    }
    [self setPhotoHash:photo.contentHash forRequest:request];
    [self addRequest:request];
    [self setOperationDelegate:delegate forRequest:request];
    [self photoSubmitter:self willStartUpload:photo.contentHash];    
}

/*!
 * is photo supported
 */
- (BOOL)isPhotoSupported{
    return YES;
}

#pragma mark - videos
/*!
 * submit video
 */
- (void) submitVideo:(ENGPhotoSubmitterVideoEntity *)video andOperationDelegate:(id<ENGPhotoSubmitterPhotoOperationDelegate>)delegate{
    id<ENGPhotoSubmitterInstanceProtocol> instance = [self subclassInstance];
    
    if(delegate.isCancelled){
        return;
    }
    id request = [instance onSubmitVideo:video andOperationDelegate:(id<ENGPhotoSubmitterPhotoOperationDelegate>)delegate];
    if(request == nil){
        return;
    }
    [self setPhotoHash:video.contentHash forRequest:request];
    [self addRequest:request];
    [self setOperationDelegate:delegate forRequest:request];
    [self photoSubmitter:self willStartUpload:video.contentHash];    
}

/*!
 * is photo supported
 */
- (BOOL)isVideoSupported{
    return YES;
}

/*!
 * maximum length of video
 */
- (NSInteger)maximumLengthOfVideo{
    return 0;
}

#pragma mark - albums
/*!
 * album list
 */
- (NSArray *)albumList{
    id albums = [self complexSettingForKey:[self keyForAlbums]];
    if([albums isKindOfClass:[NSArray class]]){
        return albums;
    }
    [self removeSettingForKey:[self keyForAlbums]];
    return nil;
}

/*!
 * set album list
 */
- (void) setAlbumList:(NSArray *)albumList{
    [self setComplexSetting:albumList forKey:[self keyForAlbums]];
    [self.dataDelegate photoSubmitter:self didAlbumUpdated:albumList];
}

/*!
 * selected album
 */
- (ENGPhotoSubmitterAlbumEntity *)targetAlbum{
    return [self complexSettingForKey:[self keyForTargetAlbum]];
}

/*!
 * save selected album
 */
- (void)setTargetAlbum:(ENGPhotoSubmitterAlbumEntity *)targetAlbum{
    [self setComplexSetting:targetAlbum forKey:[self keyForTargetAlbum]];
}

/*!
 * create album
 */
- (void)createAlbum:(NSString *)title withDelegate:(id<ENGPhotoSubmitterAlbumDelegate>)delegate{
    //do nothing 
    self.albumDelegate = delegate;
}

/*!
 * update album list
 */
- (void)updateAlbumListWithDelegate:(id<ENGPhotoSubmitterDataDelegate>)delegate{
    //do nothing
    self.dataDelegate = delegate;
}

#pragma mark - username
/*!
 * set username
 */
- (void)setUsername:(NSString *)username{
    [self setSetting:username forKey:[self keyForUsername]];
    [self.dataDelegate photoSubmitter:self didUsernameUpdated:username];
}

/*!
 * get username
 */
- (NSString *)username{
    return [self settingForKey:[self keyForUsername]];
    //do nothing
}

/*!
 * update username
 */
- (void)updateUsernameWithDelegate:(id<ENGPhotoSubmitterDataDelegate>)delegate{
    //do nothing
    self.dataDelegate = delegate;
}

#pragma mark - other properties
/*!
 * return type
 */
- (NSString *)type{
    return [NSString stringWithUTF8String:class_getName(self.class)];
}

/*!
 * name
 */
- (NSString *)name{
    NSString *name = [self.type stringByMatching:@"^(.+)PhotoSubmitter" capture:1L];
    assert(name != nil);
    return name;
}

/*!
 * display name
 */
- (NSString *)displayName{
    if([[ENGPhotoSubmitterAccountManager sharedManager] countAccountForType:self.type] == 1){
        return self.name; 
    }
    NSString *u = self.username;
    if(u != nil && [u isEqualToString: @""] == NO){
        return [NSString stringWithFormat:@"%@(%@)", self.name, self.username];
    }
    return self.name;
}

/*!
 * icon image
 */
- (UIImage *)icon{
    return [UIImage imageNamed:[self getIconImageNameWithSize:32]];
}

/*!
 * small icon image
 */
- (UIImage *)smallIcon{
    return [UIImage imageNamed:[self getIconImageNameWithSize:16]];
}

/*!
 * setting view
 */
- (ENGPhotoSubmitterServiceSettingTableViewController *)settingView{
    ENGPhotoSubmitterServiceSettingTableViewController *sv = [[ENGPhotoSubmitterManager sharedInstance].settingViewFactory createSettingViewWithSubmitter:self];

    if(sv){
        return sv;
    }
    return self.subclassInstance.settingViewInternal;
}

/*!
 * setting view internal
 */
- (ENGPhotoSubmitterServiceSettingTableViewController *)settingViewInternal{
    if(self.isAlbumSupported){
        return [[ENGAlbumPhotoSubmitterSettingTableViewController alloc] initWithAccount:self.account];
    }
    return [[ENGSimplePhotoSubmitterSettingTableViewController alloc] initWithAccount:self.account];
}

/*!
 * maximum comment length
 */
- (NSInteger)maximumLengthOfComment{
    return 0;
}

/*!
 * is multiple account supported
 */
- (BOOL)isMultipleAccountSupported{
    return NO;
}

/*!
 * is square
 */
- (BOOL)isSquare{
    return NO;
}

#pragma mark - UTILITY METHODS
#pragma mark - request methods
/*!
 * add request
 */
- (void)addRequest:(NSObject *)request{
    [requests_ setObject:request forKey:[NSNumber numberWithInteger:request.hash]];
}

/*!
 * remove request
 */
- (void)removeRequest:(NSObject *)request{
    [requests_ removeObjectForKey:[NSNumber numberWithInteger:request.hash]];
}

#pragma mark -
#pragma mark photo delegate methods
/*!
 * add request
 */
- (void)addPhotoDelegate:(id<ENGPhotoSubmitterPhotoDelegate>)photoDelegate{
    if([photoDelegates_ containsObject:photoDelegate]){
        return;
    }
    [photoDelegates_ addObject:photoDelegate];
}

/*!
 * remove request
 */
- (void)removePhotoDelegate: (id<ENGPhotoSubmitterPhotoDelegate>)photoDelegate{
    [photoDelegates_ removeObject:photoDelegate];
}

/*!
 * call will start upload delegate method
 */
- (void) photoSubmitter:(id<ENGPhotoSubmitterProtocol>)photoSubmitter willStartUpload:(NSString *)imageHash{
    for(id<ENGPhotoSubmitterPhotoDelegate> delegate in photoDelegates_){
        [delegate photoSubmitter:photoSubmitter willStartUpload:imageHash];
    }
}

/*!
 * call did submitted delegate method
 */
- (void) photoSubmitter:(id<ENGPhotoSubmitterProtocol>)photoSubmitter didSubmitted:(NSString *)imageHash suceeded:(BOOL)suceeded message:(NSString *)message{
    for(id<ENGPhotoSubmitterPhotoDelegate> delegate in photoDelegates_){
        [delegate photoSubmitter:photoSubmitter didSubmitted:imageHash suceeded:suceeded message:message];
    }
}

/*!
 * call did progress changed delegate method
 */
- (void) photoSubmitter:(id<ENGPhotoSubmitterProtocol>)photoSubmitter didProgressChanged:(NSString *)imageHash progress:(CGFloat)progress{
    for(id<ENGPhotoSubmitterPhotoDelegate> delegate in photoDelegates_){
        [delegate photoSubmitter:photoSubmitter didProgressChanged:imageHash progress:progress];
    }    
}

/*!
 * call did photo submitter canceled delegate methods
 */
- (void)photoSubmitter:(id<ENGPhotoSubmitterProtocol>)photoSubmitter didCanceled:(NSString *)imageHash{
    for(id<ENGPhotoSubmitterPhotoDelegate> delegate in photoDelegates_){
        [delegate photoSubmitter:photoSubmitter didCanceled:imageHash];
    }        
}

#pragma mark -
#pragma mark operation delegates
/*!
 * set operation
 */
- (void)setOperationDelegate:(id<ENGPhotoSubmitterPhotoOperationDelegate>)operation forRequest:(NSObject *)request{
    if(operation != nil){
        [operationDelegates_ setObject:operation forKey:[NSNumber numberWithInteger:request.hash]];
    }
}

/*!
 * remove operation
 */
- (void)removeOperationDelegateForRequest:(NSObject *)request{
    [operationDelegates_ removeObjectForKey:[NSNumber numberWithInteger:request.hash]];
}

/*!
 * operation for request
 */
- (id<ENGPhotoSubmitterPhotoOperationDelegate>)operationDelegateForRequest:(NSObject *)request{
    return [operationDelegates_ objectForKey:[NSNumber numberWithInteger:request.hash]];
}

#pragma mark -
#pragma mark photo hash methods
/*!
 * set photo hash
 */
- (void)setPhotoHash:(NSString *)photoHash forRequest:(NSObject *)request{
    [photos_ setObject:photoHash forKey:[NSNumber numberWithInteger:request.hash]];
}


/*!
 * remove photo hash
 */
- (void)removePhotoForRequest:(NSObject *)request{
    [photos_ removeObjectForKey:[NSNumber numberWithInteger:request.hash]];
}

/*!
 * get photo hash
 */
- (NSString *)photoForRequest:(NSObject *)request{
    return [photos_ objectForKey:[NSNumber numberWithInteger:request.hash]];
}

/*!
 * get request
 */
- (NSObject *)requestForPhoto:(NSString *)photoHash{
    NSArray *key = [photos_ allKeysForObject:photoHash];
    if(key.count == 0){
        return nil;
    }
    return [requests_ objectForKey:[key lastObject]];
}
#pragma mark - present setting view
/*!
 * present authentication view
 */
- (void) presentAuthenticationView:(UIViewController *)viewController{
	[[[ENGPhotoSubmitterManager sharedInstance].navigationControllerDelegate requestNavigationControllerForPresentAuthenticationView] pushViewController:viewController animated:YES];
}

/*!
 * present modal view
 */
- (void) presentModalViewController:(UIViewController *)viewController{
    [[[ENGPhotoSubmitterManager sharedInstance].navigationControllerDelegate requestRootViewControllerForPresentModalView] presentModalViewController:viewController animated:YES];
}

/*!
 * dismiss modal view
 */
- (void) dismissModalViewController{
    [[[ENGPhotoSubmitterManager sharedInstance].navigationControllerDelegate requestRootViewControllerForPresentModalView] dismissModalViewControllerAnimated:YES];
}

#pragma mark - util methods
/*!
 * clear request data
 */
- (void)clearRequest:(NSObject *)request{
    [self removeRequest:request];
    [self removeOperationDelegateForRequest:request];
    [self removePhotoForRequest:request];
}

/*!
 * recover old settings
 */
- (void) recoverOldSettings{
    NSString *oldEnabled = [NSString stringWithFormat:@"PS%@Enabled", self.name];
    if([self settingExistsForKey:oldEnabled] && [self settingExistsForKey:self.keyForEnabled] == NO){
        [self setSetting:[self settingForKey:oldEnabled] forKey:self.keyForEnabled];
        [self removeSettingForKey:oldEnabled];
    }
}


#pragma mark - setting methods

/*!
 * write setting to user defaults
 */
- (void)setSetting:(id)value forKey:(NSString *)key{
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    [defaults setValue:value forKey:key];
    [defaults synchronize];
}

/*!
 * read setting from user defaults
 */
- (id)settingForKey:(NSString *)key{
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    return [defaults valueForKey:key];
}
/*!
 * write complex setting to user defaults
 */
- (void)setComplexSetting:(id)value forKey:(NSString *)key{
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];    
    NSData *data = [NSKeyedArchiver archivedDataWithRootObject:value];
    [defaults setValue:data forKey:key];
    [defaults synchronize];
}

/*!
 * read complex setting from user defaults
 */
- (id)complexSettingForKey:(NSString *)key{
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    NSData *data = [defaults valueForKey:key];
    if(data == nil){
        return nil;
    }
    return [NSKeyedUnarchiver unarchiveObjectWithData:data];
}

/*!
 * remove setting from user defaults
 */
- (void)removeSettingForKey:(NSString *)key{
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    [defaults removeObjectForKey:key];
    [defaults synchronize];
}

/*!
 * setting exists
 */
- (BOOL)settingExistsForKey:(NSString *)key{
    return [self settingForKey:key] != nil;
}

#pragma mark - secure setting methods

/*!
 * write setting to user bindings
 */
- (void)setSecureSetting:(id)value forKey:(NSString *)key{
    PDKeychainBindings *bindings = [PDKeychainBindings sharedKeychainBindings];
    [bindings setObject:value forKey:key];
}

/*!
 * read setting from user bindings
 */
- (id)secureSettingForKey:(NSString *)key{
    PDKeychainBindings *bindings = [PDKeychainBindings sharedKeychainBindings];
    return [bindings objectForKey:key];
}

/*!
 * remove setting from user bindings
 */
- (void)removeSecureSettingForKey:(NSString *)key{
    PDKeychainBindings *bindings = [PDKeychainBindings sharedKeychainBindings];
    [bindings removeObjectForKey:key];
}

/*!
 * setting exists
 */
- (BOOL)secureSettingExistsForKey:(NSString *)key{
    return [self secureSettingForKey:key] != nil;
}
@end
