//
//  PicasaPhotoSubmitter.m
//  PhotoSubmitter for Picasa
//
//  Created by Kentaro ISHITOYA on 12/02/10.
//  Copyright (c) 2012 cocotomo. All rights reserved.
//

#if ! __has_feature(objc_arc)
#error This file must be compiled with ARC. Use -fobjc-arc flag (or convert project to ARC).
#endif

#import "PicasaAPIKey.h"
#import "PicasaPhotoSubmitter.h"
#import "PhotoSubmitterManager.h"
#import "RegexKitLite.h"
#import "GTMOAuth2ViewControllerTouch.h"
#import "GTMHTTPUploadFetcher.h"
#import "PSLang.h"

#define PS_PICASA_AUTH_URL @"photosubmitter://auth/picasa"
#define PS_PICASA_KEYCHAIN_NAME @"PSPicasaKeychain"
#define PS_PICASA_SCOPE @"https://photos.googleapis.com/data/"
#define PS_PICASA_PROFILE_SCOPE @"https://www.googleapis.com/auth/userinfo.profile"
#define PS_PICASA_ALBUM_DROPBOX @"Drop Box"

//-----------------------------------------------------------------------------
//Private Implementations
//-----------------------------------------------------------------------------
@interface PicasaPhotoSubmitter(PrivateImplementation)
- (void) setupInitialState;
- (void) clearCredentials;
- (void)fetchSelectedAlbum: (GDataEntryPhotoAlbum *)album;
- (void) viewController:(GTMOAuth2ViewControllerTouch *)viewController
       finishedWithAuth:(GTMOAuth2Authentication *)auth
                  error:(NSError *)error;
- (void)ticket:(GDataServiceTicket *)ticket
hasDeliveredByteCount:(unsigned long long)numberOfBytesRead
ofTotalByteCount:(unsigned long long)dataLength;
- (void)addPhotoTicket:(GDataServiceTicket *)ticket
     finishedWithEntry:(GDataEntryPhoto *)photoEntry
                 error:(NSError *)error;
@end

@implementation PicasaPhotoSubmitter(PrivateImplementation)
#pragma mark - private implementations
/*!
 * initializer
 */
-(void)setupInitialState{
    [self setSubmitterIsConcurrent:YES
                      isSequencial:NO 
                     usesOperation:YES 
                   requiresNetwork:YES 
                  isAlbumSupported:YES];
    
    GTMOAuth2Authentication *auth = 
    [GTMOAuth2ViewControllerTouch 
     authForGoogleFromKeychainForName:PS_PICASA_KEYCHAIN_NAME
     clientID:PICASA_SUBMITTER_API_KEY
     clientSecret:PICASA_SUBMITTER_API_SECRET];
    if([auth canAuthorize]){
        auth_ = auth;
    }
    service_ = [[GDataServiceGooglePhotos alloc] init];
    
    [service_ setShouldCacheResponseData:YES];
    [service_ setServiceShouldFollowNextLinks:YES];
    
    //-lObjC staff.
    GTMHTTPFetcher *fetcher = [[GTMHTTPUploadFetcher alloc] init];
    fetcher = nil;
}

/*!
 * clear Picasa credential
 */
- (void)clearCredentials{
    [GTMOAuth2ViewControllerTouch removeAuthFromKeychainForName:PS_PICASA_KEYCHAIN_NAME];
    [super clearCredentials];
}

/*!
 * fetch selected album information
 */
- (void)fetchSelectedAlbum: (GDataEntryPhotoAlbum *)album{
    // fetch the photos feed
    NSURL *feedURL = album.feedLink.URL;
    if (feedURL) {
        GDataServiceTicket *ticket;
        ticket = [service_ fetchFeedWithURL:feedURL
                                   delegate:self
                          didFinishSelector:@selector(photosTicket:finishedWithFeed:error:)];
        if(ticket != nil){
            [self setPhotoHash:album.identifier forRequest:ticket];
            [self addRequest:ticket];
        }
    }
}

#pragma mark - GTMOAuth2ViewControllerTouch delegate
/*!
 * on authenticated
 */
- (void)viewController:(GTMOAuth2ViewControllerTouch *)viewController
      finishedWithAuth:(GTMOAuth2Authentication *)auth
                 error:(NSError *)error {
    if (error != nil) {
        NSLog(@"Authentication error: %@", error);
        NSData *responseData = [[error userInfo] objectForKey:@"data"];        
        if ([responseData length] > 0) {
            NSString *str = 
            [[NSString alloc] initWithData:responseData
                                  encoding:NSUTF8StringEncoding];
            NSLog(@"%@", str);
        }
        [self completeLoginFailed];
    } else {
        auth_ = auth;
        [self completeLogin];
    }
}

#pragma mark - GDataGoogleServicePhoto delegate methods
/*!
 * gdata request delegate, progress
 */
- (void)ticket:(GDataServiceTicket *)ticket
hasDeliveredByteCount:(unsigned long long)numberOfBytesRead
ofTotalByteCount:(unsigned long long)dataLength {
    CGFloat progress = (float)numberOfBytesRead / (float)dataLength;
    NSString *hash = [self photoForRequest:ticket];
    [self photoSubmitter:self didProgressChanged:hash progress:progress];
}

/*!
 * GData delegate add photo completed
 */
- (void)addPhotoTicket:(GDataServiceTicket *)ticket
     finishedWithEntry:(GDataEntryPhoto *)photoEntry
                 error:(NSError *)error {    
    if (error == nil) {
        [self completeSubmitContentWithRequest:ticket];
    } else {
        if(self.targetAlbum != nil){
            [self removeSettingForKey:self.targetAlbum.albumId];
        }
        [self completeSubmitContentWithRequest:ticket andError:error];
    }
}


/*!
 * album list fetch callback
 */
- (void)albumListFetchTicket:(GDataServiceTicket *)ticket
            finishedWithFeed:(GDataFeedPhotoUser *)feed
                       error:(NSError *)error {
    if (error != nil) {
        return;
    }    
    
    photoFeed_ = feed;
    
    NSMutableArray *albums = [[NSMutableArray alloc] init];
    for (GDataEntryPhotoAlbum *a in photoFeed_) {
        PhotoSubmitterAlbumEntity *album = 
        [[PhotoSubmitterAlbumEntity alloc] initWithId:a.identifier name:[a.title stringValue] privacy:a.access];
        [albums addObject:album];
        [self fetchSelectedAlbum:a];
    }
    self.albumList = albums;
    [self clearRequest:ticket];
}

/*!
 * album creation callback
 */
- (void)createAlbumTicket:(GDataServiceTicket *)ticket
        finishedWithEntry:(GDataEntryPhotoAlbum *)entry
                    error:(NSError *)error {
    if(error == nil){
        PhotoSubmitterAlbumEntity *album = 
        [[PhotoSubmitterAlbumEntity alloc] initWithId:entry.identifier name:[entry.title stringValue] privacy:@""];
        [self fetchSelectedAlbum:entry];
        [self.albumDelegate photoSubmitter:self didAlbumCreated:album suceeded:YES withError:nil];
    }else{
        [self.albumDelegate photoSubmitter:self didAlbumCreated:nil suceeded:NO withError:nil];
    }
    [self clearRequest:ticket];    
}

/*!
 * photo list fetch callback
 */
- (void)photosTicket:(GDataServiceTicket *)ticket
    finishedWithFeed:(GDataFeedPhotoAlbum *)feed
               error:(NSError *)error {
    if(error){
        return;
    }
    NSString *albumIdentifier = [self photoForRequest:ticket];
    [self setSetting:feed.uploadLink.URL.absoluteString forKey:albumIdentifier];
    [self clearRequest:ticket];
}
@end

//-----------------------------------------------------------------------------
//Public Implementations
//-----------------------------------------------------------------------------
#pragma mark - public PhotoSubmitter Protocol implementations
@implementation PicasaPhotoSubmitter
@synthesize authDelegate;
@synthesize dataDelegate;
@synthesize albumDelegate;
/*!
 * initialize
 */
- (id)initWithAccount:(PhotoSubmitterAccount *)account{
    self = [super initWithAccount:account];
    if (self) {
        [self setupInitialState];
    }
    return self;
}

#pragma mark - authorization
/*!
 * login to Picasa
 */
-(void)onLogin{
    if([PhotoSubmitterManager isSubmitterEnabledForType:@"gdrive"]){
        UIAlertView *alert =
        [[UIAlertView alloc] initWithTitle:[PSLang localized:@"GData_Error_Title"] 
                                   message:[PSLang localized:@"GData_Error_Message"]
                                  delegate:self 
                         cancelButtonTitle:
         [PSLang localized:@"GData_Error_Button_Title"]
                         otherButtonTitles:nil];
        [alert show];
        [self disable];
        return;
    }
    
    SEL finishedSel = @selector(viewController:finishedWithAuth:error:);        
    NSString *scope = [GTMOAuth2Authentication scopeWithStrings:PS_PICASA_SCOPE, PS_PICASA_PROFILE_SCOPE, nil];
    
    GTMOAuth2ViewControllerTouch *viewController = 
    [GTMOAuth2ViewControllerTouch controllerWithScope:scope
                                             clientID:PICASA_SUBMITTER_API_KEY
                                         clientSecret:PICASA_SUBMITTER_API_SECRET
                                     keychainItemName:PS_PICASA_KEYCHAIN_NAME
                                             delegate:self
                                     finishedSelector:finishedSel];
    
    [self presentAuthenticationView:viewController];
}

/*!
 * logoff from Picasa
 */
- (void)onLogout{  
    if ([[auth_ serviceProvider] isEqual:kGTMOAuth2ServiceProviderGoogle]) {
        [GTMOAuth2ViewControllerTouch revokeTokenForGoogleAuthentication:auth_];
    }
    [self completeLogout];
}

/*!
 * refresh credential
 */
- (void)refreshCredential{
    if([auth_ canAuthorize] && [auth_ shouldAuthorizeAllRequests]){
        [auth_ refreshToken];
    }
}

/*!
 * check is session valid
 */
- (BOOL)isSessionValid{
    return [GTMOAuth2ViewControllerTouch 
            authorizeFromKeychainForName:PS_PICASA_KEYCHAIN_NAME
            authentication:auth_];
}

#pragma mark - photo
/*!
 * submit photo with data, comment and delegate
 */
- (id)onSubmitPhoto:(PhotoSubmitterImageEntity *)photo andOperationDelegate:(id<PhotoSubmitterPhotoOperationDelegate>)delegate{
    [service_ setAuthorizer:auth_];
    
    GDataEntryPhoto *newEntry = [GDataEntryPhoto photoEntry];
    
    NSDateFormatter *df = [[NSDateFormatter alloc] init];
    df.dateFormat  = @"yyyyMMddHHmmssSSSS";
    [newEntry setTitleWithString:[df stringFromDate:photo.timestamp]];
    [newEntry setPhotoDescriptionWithString:photo.comment];
    [newEntry setTimestamp:[GDataPhotoTimestamp timestampWithDate:photo.timestamp]];
    
    [newEntry setPhotoData:photo.data];
    [newEntry setUploadSlug:photo.contentHash];
    
    NSString *mimeType = @"image/jpeg";
    [newEntry setPhotoMIMEType:mimeType];
        
    NSURL *uploadURL = nil;
    if(self.targetAlbum == nil || [self.targetAlbum.name isEqualToString:PS_PICASA_ALBUM_DROPBOX]){
        uploadURL = [NSURL URLWithString:kGDataGooglePhotosDropBoxUploadURL];
    }else{
        NSString *url = [self settingForKey:self.targetAlbum.albumId];
        if(url != nil){
            uploadURL = [NSURL URLWithString:url];
        }else{
            [self updateAlbumListWithDelegate:nil];
            //this will fail
            uploadURL = [NSURL URLWithString:self.targetAlbum.albumId];
        }
    }
    GDataServiceTicket *ticket = nil;
    @synchronized(service_){
        SEL progressSel = @selector(ticket:hasDeliveredByteCount:ofTotalByteCount:);
        [service_ setServiceUploadProgressSelector:progressSel];
        ticket = [service_ fetchEntryByInsertingEntry:newEntry
                                  forFeedURL:uploadURL
                                    delegate:self
                           didFinishSelector:@selector(addPhotoTicket:finishedWithEntry:error:)];
        [service_ setServiceUploadProgressSelector:nil];    
    };
    return ticket;
}

/*!
 * submit video
 */
- (id)onSubmitVideo:(PhotoSubmitterVideoEntity *)video andOperationDelegate:(id<PhotoSubmitterPhotoOperationDelegate>)delegate{
    return nil;
}

/*!
 * cancel content upload
 */
- (id)onCancelContentSubmit:(PhotoSubmitterContentEntity *)content{
    GDataServiceTicket *ticket = (GDataServiceTicket *)[self requestForPhoto:content.contentHash];
    [ticket cancelTicket];
    return ticket;
}

/*!
 * is video supported
 */
- (BOOL)isVideoSupported{
    return NO;
}

#pragma mark - album

/*!
 * create album
 */
- (void)createAlbum:(NSString *)title withDelegate:(id<PhotoSubmitterAlbumDelegate>)delegate{
    self.albumDelegate = delegate;
    if(photoFeed_ == nil){
        NSLog(@"photoFeed is nil, you must call updateAlbumListWithDelegate before creating album. %s", __PRETTY_FUNCTION__)
        ;
        return [self.albumDelegate photoSubmitter:self didAlbumCreated:nil suceeded:NO withError:nil];
    }
    NSString *description = [NSString stringWithFormat:@"Created %@",
                             [NSDate date]];
    
    NSString *access = kGDataPhotoAccessPrivate;
    
    GDataEntryPhotoAlbum *newAlbum = [GDataEntryPhotoAlbum albumEntry];
    [newAlbum setTitleWithString:title];
    [newAlbum setPhotoDescriptionWithString:description];
    [newAlbum setAccess:access];
    
    NSURL *postLink = [photoFeed_ postLink].URL;        
    GDataServiceTicket *ticket = 
    [service_ fetchEntryByInsertingEntry:newAlbum
                              forFeedURL:postLink
                                delegate:self
                       didFinishSelector:@selector(createAlbumTicket:finishedWithEntry:error:)];
    [self addRequest:ticket];
}

/*!
 * update album list
 */
- (void)updateAlbumListWithDelegate:(id<PhotoSubmitterDataDelegate>)delegate{
    self.dataDelegate = delegate;
    
    [service_ setAuthorizer:auth_];
    
    NSURL *feedURL = 
    [GDataServiceGooglePhotos photoFeedURLForUserID:auth_.userEmail
                                            albumID:nil
                                          albumName:nil
                                            photoID:nil
                                               kind:nil
                                             access:nil];
    GDataServiceTicket *ticket = 
    [service_ fetchFeedWithURL:feedURL
                      delegate:self
             didFinishSelector:@selector(albumListFetchTicket:finishedWithFeed:error:)];
    [self addRequest:ticket];
}

#pragma mark - username
/*!
 * update username
 */
- (void)updateUsernameWithDelegate:(id<PhotoSubmitterDataDelegate>)delegate{
    self.dataDelegate = delegate;
    self.username = auth_.userEmail;
}
@end
