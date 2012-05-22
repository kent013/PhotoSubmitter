//
//  GDrivePhotoSubmitter.m
//  PhotoSubmitter for Google Drive
//
//  Created by Kentaro ISHITOYA on 12/05/20.
//  Copyright (c) 2012 cocotomo. All rights reserved.
//

#if ! __has_feature(objc_arc)
#error This file must be compiled with ARC. Use -fobjc-arc flag (or convert project to ARC).
#endif

#import "RestKit/RestKit.h"
#import "GDriveAPIKey.h"
#import "GDrivePhotoSubmitter.h"
#import "PhotoSubmitterManager.h"
#import "RegexKitLite.h"
#import "GTMOAuth2ViewControllerTouch.h"
#import "GTMHTTPUploadFetcher.h"
#import "GDrivePhotoSubmitterSettingTableViewController.h"
#import "PSLang.h"

#define PS_GDRIVE_AUTH_URL @"photosubmitter://auth/gdrive"
#define PS_GDRIVE_KEYCHAIN_NAME @"PSGDriveKeychain"
#define PS_GDRIVE_SCOPE @"https://www.googleapis.com/auth/drive.file"
#define PS_GDRIVE_PROFILE_SCOPE @"https://www.googleapis.com/auth/userinfo.profile"
#define PS_GDOCS_FEEDS_SCOPE @"https://docs.google.com/feeds/"
#define PS_GDOCS_USER_SCOPE @"https://docs.googleusercontent.com/"
#define PS_GDRIVE_ROOT_URL @"https://www.googleapis.com/upload/drive/v1/files/?uploadType=multipart"
//-----------------------------------------------------------------------------
//Private Implementations
//-----------------------------------------------------------------------------
@interface GDrivePhotoSubmitter(PrivateImplementation)
- (void) setupInitialState;
- (void) clearCredentials;
- (void) viewController:(GTMOAuth2ViewControllerTouch *)viewController
       finishedWithAuth:(GTMOAuth2Authentication *)auth
                  error:(NSError *)error;
- (void)authentication:(GTMOAuth2Authentication *)auth
               request:(NSMutableURLRequest *)request
     finishedWithError:(NSError *)error;
- (void)albumListFetchTicket:(GDataServiceTicket *)ticket
            finishedWithFeed:(GDataFeedDocList *)feed
                       error:(NSError *)error;
- (void)createAlbumTicket:(GDataServiceTicket *)ticket
        finishedWithEntry:(GDataEntryFolderDoc *)entry
                    error:(NSError *)error;
@end

@implementation GDrivePhotoSubmitter(PrivateImplementation)
#pragma mark - private implementations
/*!
 * initializer
 */
-(void)setupInitialState{
    [self setSubmitterIsConcurrent:NO 
                      isSequencial:NO 
                     usesOperation:YES 
                   requiresNetwork:YES 
                  isAlbumSupported:YES];
    
    GTMOAuth2Authentication *auth = 
    [GTMOAuth2ViewControllerTouch 
     authForGoogleFromKeychainForName:PS_GDRIVE_KEYCHAIN_NAME
     clientID:GDRIVE_SUBMITTER_API_KEY
     clientSecret:GDRIVE_SUBMITTER_API_SECRET];
    if([auth canAuthorize]){
        auth_ = auth;
    }
    
    service_ = [[GDataServiceGoogleDocs alloc] init];
    
    [service_ setShouldCacheResponseData:YES];
    [service_ setServiceShouldFollowNextLinks:YES];

    contents_ = [[NSMutableDictionary alloc] init];
    
    //-lObjC staff.
    GTMHTTPFetcher *fetcher = [[GTMHTTPUploadFetcher alloc] init];
    fetcher = nil;
}

/*!
 * clear Picasa credential
 */
- (void)clearCredentials{
    [GTMOAuth2ViewControllerTouch removeAuthFromKeychainForName:PS_GDRIVE_KEYCHAIN_NAME];
    [super clearCredentials];
}

- (void)authentication:(GTMOAuth2Authentication *)auth
               request:(NSMutableURLRequest *)request
     finishedWithError:(NSError *)error{
    
    if(error != nil){
        [self completeSubmitContentWithRequest:request andError:error];
        return;
    }
    PhotoSubmitterContentEntity *content = [contents_ objectForKey:[self photoForRequest:request]]; 
	//[request addValue:[NSString stringWithFormat:@"GoogleLogin auth=%@", auth_.accessToken] forHTTPHeaderField:@"Authorization"];
	[request setHTTPMethod:@"POST"];
	
	NSString* boundary = @"2342342352342343";
	
	[request addValue:[NSString stringWithFormat:@"multipart/form-data; boundary=%@", boundary]
   forHTTPHeaderField:@"Content-Type"];
	
	// Assemble the body.
	NSString* boundaryBreak = [NSString stringWithFormat:@"\r\n--%@\r\n", boundary];
	NSString* body = boundaryBreak;
        
    NSDateFormatter *df = [[NSDateFormatter alloc] init];
    df.dateFormat  = @"yyyyMMddHHmmssSSSS";
    NSString *filename = nil;
    NSString *mimeType = nil;
    NSString *json = nil;
    if(content.isPhoto){
        filename = [NSString stringWithFormat:@"%@.jpg", [df stringFromDate:content.timestamp]];
        mimeType = @"image/jpg";
    }else{
        filename = [NSString stringWithFormat:@"%@.mp4", [df stringFromDate:content.timestamp]];
        mimeType = @"video/mp4";
    }
    
    NSString *parentsCollection = @"";
    if(self.targetAlbum != nil){
        parentsCollection = [NSString stringWithFormat:@",\"parentsCollection\":[{\"id\":\"%@\"}]", self.targetAlbum.albumId];
    }
    NSString *description = @"";
    if(content.comment != nil){
        description = content.comment;
    }
    
    json = [NSString stringWithFormat:@"{\"title\":\"%@\",\"mimeType\":\"%@\",\"description\":\"%@\"%@}", filename, mimeType, description, parentsCollection];
	
    body = [NSString stringWithFormat:@"%@Content-Type: application/json; charset=UTF-8\r\n\r\n%@%@", body, json, boundaryBreak];
    
	body = [NSString stringWithFormat:@"%@Content-Type: %@\r\n\r\n", body, mimeType];
	
	NSMutableData* bodyData = [NSMutableData data];
	[bodyData appendData:[body dataUsingEncoding:NSUTF8StringEncoding]];
	[bodyData appendData:content.data];
	
	NSData* boundaryDataEnd = [[NSString stringWithFormat:@"\r\n--%@--\r\n", boundary] dataUsingEncoding:NSUTF8StringEncoding];
	[bodyData appendData:boundaryDataEnd];
	
	[request setHTTPBody:bodyData];
    
    id<PhotoSubmitterPhotoOperationDelegate> delegate = [self operationDelegateForRequest:request];
    [self clearRequest:request];
    NSURLConnection *connection = [NSURLConnection connectionWithRequest:request delegate:self];
    
    [self setPhotoHash:content.contentHash forRequest:connection];
    [self addRequest:connection];
    [self setOperationDelegate:delegate forRequest:connection];
    [self photoSubmitter:self willStartUpload:content.contentHash]; 
}

/*!
 * submit content
 */
- (id)onSubmitContent:(PhotoSubmitterContentEntity *)content andOperationDelegate:(id<PhotoSubmitterPhotoOperationDelegate>)delegate{
    NSString *url = PS_GDRIVE_ROOT_URL;
	NSMutableURLRequest* request = 
    [NSMutableURLRequest requestWithURL:[NSURL URLWithString:url]
                            cachePolicy:NSURLRequestReloadIgnoringLocalCacheData 
                        timeoutInterval:60];
	
    [auth_ authorizeRequest:request delegate:self didFinishSelector:@selector(authentication:request:finishedWithError:)];
    [contents_ setObject:content forKey:content.contentHash];
    [self setPhotoHash:content.contentHash forRequest:request];
    [self setOperationDelegate:delegate forRequest:request];

    return request;
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
        UIAlertView *alert =
        [[UIAlertView alloc] initWithTitle:[PSLang localized:@"GDrive_Attention_Title"] 
                                   message:[PSLang localized:@"GDrive_Attention_Message"]
                                  delegate:self 
                         cancelButtonTitle:
         [PSLang localized:@"GDrive_Attention_Button_Title"]
                         otherButtonTitles:nil];
        [alert show];
        auth_ = auth;
        [self completeLogin];
    }
}

#pragma mark - NSURLConnection delegates
/*!
 * did fail
 */
- (void)connection:(NSURLConnection *)connection didFailWithError:(NSError *)error{
    [self completeSubmitContentWithRequest:connection andError:error];
}

/*!
 * did finished
 */
-(void)connectionDidFinishLoading:(NSURLConnection *)connection{
    [self completeSubmitContentWithRequest:connection];    
}

/*!
 * progress
 */
- (void)connection:(NSURLConnection *)connection didSendBodyData:(NSInteger)bytesWritten totalBytesWritten:(NSInteger)totalBytesWritten totalBytesExpectedToWrite:(NSInteger)totalBytesExpectedToWrite{
    CGFloat progress = (float)totalBytesWritten / (float)totalBytesExpectedToWrite;
    NSString *hash = [self photoForRequest:connection];
    [self photoSubmitter:self didProgressChanged:hash progress:progress];
}


/*!
 * album creation callback
 */
- (void)createAlbumTicket:(GDataServiceTicket *)ticket
        finishedWithEntry:(GDataEntryFolderDoc *)entry
                    error:(NSError *)error {
    if(error == nil){
        NSString *resourceId = [entry.resourceID stringByMatching:@":(.+)" capture:1];
        PhotoSubmitterAlbumEntity *album = 
        [[PhotoSubmitterAlbumEntity alloc] initWithId:resourceId name:[entry.title stringValue] privacy:@""];
        self.targetAlbum = album;
        [self.albumDelegate photoSubmitter:self didAlbumCreated:album suceeded:YES withError:nil];
    }else{
        [self.albumDelegate photoSubmitter:self didAlbumCreated:nil suceeded:NO withError:nil];
    }
    [self clearRequest:ticket];    
}

/*!
 * album list fetch callback
 */
- (void)albumListFetchTicket:(GDataServiceTicket *)ticket
            finishedWithFeed:(GDataFeedDocList *)feed
                       error:(NSError *)error {
    if (error != nil) {
        NSLog(@"%@", error.debugDescription);
        return;
    }    
    
    docFeed_ = feed;

    NSMutableArray *albums = [[NSMutableArray alloc] init];
    for (id entry in docFeed_){
        if([entry isKindOfClass:[GDataEntryFolderDoc class]]){
            GDataEntryFolderDoc *a = (GDataEntryFolderDoc *)entry;
            NSString *resourceId = [a.resourceID stringByMatching:@":(.+)" capture:1];
            PhotoSubmitterAlbumEntity *album = 
            [[PhotoSubmitterAlbumEntity alloc] initWithId:resourceId name:[a.title stringValue] privacy:@""];
            [albums addObject:album];
        }
    }
    self.albumList = albums;
    [self clearRequest:ticket];
}
@end

//-----------------------------------------------------------------------------
//Public Implementations
//-----------------------------------------------------------------------------
#pragma mark - public PhotoSubmitter Protocol implementations
@implementation GDrivePhotoSubmitter
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
    
    SEL finishedSel = @selector(viewController:finishedWithAuth:error:);        
    NSString *scope = [GTMOAuth2Authentication scopeWithStrings:PS_GDRIVE_SCOPE, PS_GDRIVE_PROFILE_SCOPE, PS_GDOCS_FEEDS_SCOPE, PS_GDOCS_USER_SCOPE, nil];
    
    GTMOAuth2ViewControllerTouch *viewController = 
    [GTMOAuth2ViewControllerTouch controllerWithScope:scope
                                             clientID:GDRIVE_SUBMITTER_API_KEY
                                         clientSecret:GDRIVE_SUBMITTER_API_SECRET
                                     keychainItemName:PS_GDRIVE_KEYCHAIN_NAME
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
            authorizeFromKeychainForName:PS_GDRIVE_KEYCHAIN_NAME
            authentication:auth_];
}

#pragma mark - photo

/*!
 * submit photo with data, comment and delegate
 */
- (void)submitPhoto:(PhotoSubmitterImageEntity *)photo andOperationDelegate:(id<PhotoSubmitterPhotoOperationDelegate>)delegate{
    if(delegate.isCancelled){
        return;
    }
    [self onSubmitContent:photo andOperationDelegate:(id<PhotoSubmitterPhotoOperationDelegate>)delegate];
}

/*!
 * submit video
 */
- (void) submitVideo:(PhotoSubmitterVideoEntity *)video andOperationDelegate:(id<PhotoSubmitterPhotoOperationDelegate>)delegate{
    if(delegate.isCancelled){
        return;
    }
    [self onSubmitContent:video andOperationDelegate:(id<PhotoSubmitterPhotoOperationDelegate>)delegate];
}

/*!
 * submit photo with data, comment and delegate
 */
- (id)onSubmitPhoto:(PhotoSubmitterImageEntity *)photo andOperationDelegate:(id<PhotoSubmitterPhotoOperationDelegate>)delegate{
    return nil;
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
    NSURLConnection *connection = (NSURLConnection *)[self requestForPhoto:content.contentHash];
    [connection cancel];
    return connection;
}

#pragma mark - album
/*!
 * create album
 */
- (void)createAlbum:(NSString *)title withDelegate:(id<PhotoSubmitterAlbumDelegate>)delegate{
    self.albumDelegate = delegate;    
    GDataEntryFolderDoc *docEntry = [GDataEntryFolderDoc documentEntry];
    
    [docEntry setTitleWithString:title];
    
    if(docFeed_ == nil){
        NSLog(@"docFeed is nil, you must call updateAlbumListWithDelegate before creating album. %s", __PRETTY_FUNCTION__)
        ;
        return [self.albumDelegate photoSubmitter:self didAlbumCreated:nil suceeded:NO withError:nil];
    }

    NSURL *postURL = [[docFeed_ postLink] URL];
    
    GDataServiceTicket *ticket =
    [service_ fetchEntryByInsertingEntry:docEntry
                              forFeedURL:postURL
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
    
    NSURL *feedURL = [GDataServiceGoogleDocs docsURLForUserID:kGDataServiceDefaultUser visibility:kGDataGoogleDocsVisibilityPrivate projection:kGDataGoogleDocsProjectionFull resourceID:nil feedType:nil revisionID:nil];
    
    GDataQueryDocs *query = [GDataQueryDocs documentQueryWithFeedURL:feedURL];
    [query setMaxResults:1000];
    [query setShouldShowFolders:YES];

    GDataServiceTicket *ticket = 
    [service_ fetchFeedWithQuery:query
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

#pragma mark - other properties

/*!
 * get setting view
 */
- (PhotoSubmitterServiceSettingTableViewController *)settingView{
    if(settingView_ == nil){
        settingView_ = [[GDrivePhotoSubmitterSettingTableViewController alloc] initWithAccount:self.account];
    }
    return settingView_;
}

/*!
 * display name
 */
- (NSString *)displayName{
    return @"Google Drive";
}
@end
