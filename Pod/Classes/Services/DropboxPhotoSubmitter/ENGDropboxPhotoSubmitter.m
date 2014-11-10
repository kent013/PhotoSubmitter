//
//  ENGDropboxPhotoSubmitter.m
//  PhotoSubmitter for Dropbox
//
//  Created by ISHITOYA Kentaro on 11/12/22.
//

#import "ENGDropboxPhotoSubmitter.h"
#import "ENGPhotoSubmitterManager.h"
#import "RegexKitLite.h"

#define PS_DROPBOX_AUTH_URL @"db-"

#define PS_DROPBOX_API_CHECK_TOKEN @"check_token"
#define PS_DROPBOX_API_REQUEST_TOKEN @"request_token"
#define PS_DROPBOX_API_GET_TOKEN @"get_token"
#define PS_DROPBOX_API_UPLOAD_IMAGE @"upload_image"

static NSString *kDefaultAlbum = @"/";
static NSString *ENGPhotoSubmitterDropboxAPIKey;
static NSString *ENGPhotoSubmitterDropboxAPISecret;

//-----------------------------------------------------------------------------
//Private Implementations
//-----------------------------------------------------------------------------
@interface ENGDropboxPhotoSubmitter(PrivateImplementation)
- (void) setupInitialState;
- (void) cleanupCache;
- (id) submitContent:(ENGPhotoSubmitterContentEntity *)content andOperationDelegate:(id<ENGPhotoSubmitterPhotoOperationDelegate>)delegate;
@end

#pragma mark - private implementations
@implementation ENGDropboxPhotoSubmitter(PrivateImplementation)
/*!
 * initializer
 */
-(void)setupInitialState{
    [self setSubmitterIsConcurrent:YES 
                      isSequencial:NO 
                     usesOperation:YES 
                   requiresNetwork:YES 
                  isAlbumSupported:YES];
    
    DBSession* dbSession = [[DBSession alloc] initWithAppKey:ENGPhotoSubmitterDropboxAPIKey appSecret:ENGPhotoSubmitterDropboxAPISecret root:kDBRootAppFolder];
    dbSession.delegate = self;
    [DBSession setSharedSession:dbSession];
    
    [self cleanupCache];
}

/*!
 * clean up cache
 */
- (void)cleanupCache{
    NSFileManager *manager = [NSFileManager defaultManager];
    NSString *dir = [NSString stringWithFormat:@"%@/tmp/", NSHomeDirectory()];
    NSDirectoryEnumerator *enumerator = [manager enumeratorAtPath:dir];
    NSString *file = nil;
    while(file = [enumerator nextObject]){
        if([[file pathExtension] isEqualToString:@"jpg"]){
            NSString *fullpath = [dir stringByAppendingString:file];
            [manager removeItemAtPath:fullpath error:nil];
        }
    }
}

/*!
 * submit content
 */
- (id)submitContent:(ENGPhotoSubmitterContentEntity *)content andOperationDelegate:(id<ENGPhotoSubmitterPhotoOperationDelegate>)delegate{
    DBRestClient *restClient = 
    [[DBRestClient alloc] initWithSession:[DBSession sharedSession]];
    restClient.delegate = self;
    
    NSDateFormatter *df = [[NSDateFormatter alloc] init];
    df.dateFormat  = @"yyyyMMddHHmmssSSSS";
    NSString *dir = [NSString stringWithFormat:@"%@/tmp/", NSHomeDirectory()];
    NSString *filename = nil;
    if(content.isVideo){
        filename = [NSString stringWithFormat:@"%@.mp4", [df stringFromDate:content.timestamp]];
    }else{
        filename = [NSString stringWithFormat:@"%@.jpg", [df stringFromDate:content.timestamp]];
    }
    NSString *path = [dir stringByAppendingString:filename];
    content.path = path;
    
    NSString *toPath = @"/";
    if(self.targetAlbum){
        toPath = self.targetAlbum.name;
    }
    content.contentHash = path;
    [content.data writeToFile:path atomically:NO];
    [restClient uploadFile:filename toPath:toPath withParentRev:nil fromPath:path];
    return restClient;
}

#pragma mark - DBRestClientDelegate methods
#pragma mark - upload file
/*!
 * Dropbox delegate, upload finished
 */
- (void)restClient:(DBRestClient*)client uploadedFile:(NSString*)destPath from:(NSString*)srcPath metadata:(DBMetadata*)metadata{
    NSFileManager *fm = [NSFileManager defaultManager];
    [fm removeItemAtPath:srcPath error:nil];
    [self completeSubmitContentWithRequest:client];
}

/*!
 * Dropbox delegate, upload failed
 */
- (void)restClient:(DBRestClient*)client uploadFileFailedWithError:(NSError *)error{
    [self completeSubmitContentWithRequest:client andError:error];
}

/*!
 * Dropbox delegate, upload progress
 */
- (void)restClient:(DBRestClient*)client uploadProgress:(CGFloat)progress forFile:(NSString*)destPath from:(NSString*)srcPath{
    NSString *hash = [self photoForRequest:client];
    [self photoSubmitter:self didProgressChanged:hash progress:progress];
}

#pragma mark - load account info
/*!
 * Dropbox delegate, account info loaded
 */
- (void)restClient:(DBRestClient *)client loadedAccountInfo:(DBAccountInfo *)info{
    self.username = info.displayName;    
    [self performSelector:@selector(clearRequest:) withObject:client afterDelay:2.0];
}

/*!
 * when the load account finished
 */
- (void)restClient:(DBRestClient *)client loadAccountInfoFailedWithError:(NSError *)error{
    NSLog(@"%@", error.description);
    [self performSelector:@selector(clearRequest:) withObject:client afterDelay:2.0];
}

#pragma mark - load metadata
/*!
 * when the metadata loaded
 */
- (void)restClient:(DBRestClient *)client loadedMetadata:(DBMetadata *)metadata{
    NSMutableArray *albums = [[NSMutableArray alloc] init];
    for (DBMetadata *m in metadata.contents){
        if(m.isDirectory && m.isDeleted == NO){
            ENGPhotoSubmitterAlbumEntity *album =
            [[ENGPhotoSubmitterAlbumEntity alloc] initWithId:m.hash name:m.path privacy:@""];
            [albums addObject:album];
        }
    } 
    ENGPhotoSubmitterAlbumEntity *album =
    [[ENGPhotoSubmitterAlbumEntity alloc] initWithId:@"/" name:@"/" privacy:@""];
    [albums addObject:album];
    
    self.albumList = albums;    
    [self performSelector:@selector(clearRequest:) withObject:client afterDelay:2.0];
}

/*!
 * when the metadata load failed
 */
- (void)restClient:(DBRestClient *)client loadMetadataFailedWithError:(NSError *)error{
    [self performSelector:@selector(clearRequest:) withObject:client afterDelay:2.0];   
}

#pragma mark - create folder
/*!
 * create folder
 */
- (void)restClient:(DBRestClient *)client createdFolder:(DBMetadata *)folder{
    ENGPhotoSubmitterAlbumEntity *album =
    [[ENGPhotoSubmitterAlbumEntity alloc] initWithId:folder.hash name:folder.path privacy:@""];
    [self.albumDelegate photoSubmitter:self didAlbumCreated:album suceeded:YES withError:nil];
    [self performSelector:@selector(clearRequest:) withObject:client afterDelay:2.0];
}

/*!
 * create folder failed
 */
- (void)restClient:(DBRestClient *)client createFolderFailedWithError:(NSError *)error{
    [self.albumDelegate photoSubmitter:self didAlbumCreated:nil suceeded:NO withError:error];
    [self performSelector:@selector(clearRequest:) withObject:client afterDelay:2.0];
}
@end

//-----------------------------------------------------------------------------
//Public Implementations
//-----------------------------------------------------------------------------
#pragma mark - public implementations
@implementation ENGDropboxPhotoSubmitter
@synthesize authDelegate;
@synthesize dataDelegate;
@synthesize albumDelegate;
/*!
 * initialize
 */
- (id)initWithAccount:(ENGPhotoSubmitterAccount *)account{
    self = [super initWithAccount:account];
    if (self) {
        [self setupInitialState];
    }
    return self;
}

#pragma mark - authorization
/*!
 * login to Dropbox
 */
-(void)onLogin{
    UIViewController *rv = [[ENGPhotoSubmitterManager sharedInstance].navigationControllerDelegate requestNavigationControllerForPresentAuthenticationView];
    [[DBSession sharedSession] linkFromController:rv];
    [self completeLogin];
}

/*!
 * logoff from Dropbox
 */
- (void)onLogout{  
    [[DBSession sharedSession] unlinkAll];
    [self completeLogout];
}

/*!
 * refresh credential
 */
- (void)refreshCredential{
    if([[DBSession sharedSession] isLinked] == NO){
        UIViewController *rv = [[ENGPhotoSubmitterManager sharedInstance].navigationControllerDelegate requestNavigationControllerForPresentAuthenticationView];
        [[DBSession sharedSession] linkFromController:rv];
    }
}

/*!
 * check url is processable
 */
- (BOOL)isProcessableURL:(NSURL *)url{
    if([url.absoluteString isMatchedByRegex:PS_DROPBOX_AUTH_URL]){
        return YES;    
    }
    return NO;
}

/*!
 * on open url finished
 */
- (BOOL)didOpenURL:(NSURL *)url{
    [[DBSession sharedSession] handleOpenURL:url];
    BOOL result = NO;
    if([[DBSession sharedSession] isLinked]){
        [self enable];
        result = YES;
    }else{
        [self disable];
        [self.authDelegate photoSubmitter:self didLogout:self.account];
    }
    [self.authDelegate photoSubmitter:self didAuthorizationFinished:self.account];
    return result;
}

/*!
 * is session valid
 */
- (BOOL)isSessionValid{
    return [[DBSession sharedSession] isLinked];
}

#pragma mark - contents
/*!
 * submit photo
 */
- (id)onSubmitPhoto:(ENGPhotoSubmitterImageEntity *)photo andOperationDelegate:(id<ENGPhotoSubmitterPhotoOperationDelegate>)delegate{
    return [self submitContent:photo andOperationDelegate:delegate];
}

/*!
 * submit video
 */
- (id)onSubmitVideo:(ENGPhotoSubmitterVideoEntity *)video andOperationDelegate:(id<ENGPhotoSubmitterPhotoOperationDelegate>)delegate{
    return [self submitContent:video andOperationDelegate:delegate];
}

/*!
 * cancel content upload
 */
- (id)onCancelContentSubmit:(ENGPhotoSubmitterContentEntity *)content{
    DBRestClient *request = (DBRestClient *)[self requestForPhoto:content.contentHash];
    [request cancelFileUpload:content.contentHash];
    return request;
}

#pragma mark - album
/*!
 * create album
 */
- (void)createAlbum:(NSString *)title withDelegate:(id<ENGPhotoSubmitterAlbumDelegate>)delegate{
    self.albumDelegate = delegate;
    DBRestClient *restClient = 
    [[DBRestClient alloc] initWithSession:[DBSession sharedSession]];
    restClient.delegate = self;
    [restClient createFolder:[NSString stringWithFormat:@"/%@", title]];
    [self addRequest:restClient];
}

/*!
 * update album list
 */
- (void)updateAlbumListWithDelegate:(id<ENGPhotoSubmitterDataDelegate>)delegate{
    self.dataDelegate = delegate;
    DBRestClient *restClient = 
    [[DBRestClient alloc] initWithSession:[DBSession sharedSession]];
    restClient.delegate = self;
    [restClient loadMetadata:@"/"];
    [self addRequest:restClient];
}

#pragma mark - username
/*!
 * update username
 */
- (void)updateUsernameWithDelegate:(id<ENGPhotoSubmitterDataDelegate>)delegate{
    self.dataDelegate = delegate;
    if([DBSession sharedSession].isLinked){
        DBRestClient *restClient = 
        [[DBRestClient alloc] initWithSession:[DBSession sharedSession]];
        restClient.delegate = self;
        [restClient loadAccountInfo];
        [self addRequest:restClient];
    }
    //do nothing
}

#pragma mark - DBSessionDelegate methods
/*!
 * authorization failed
 */
- (void)sessionDidReceiveAuthorizationFailure:(DBSession *)session userId:(NSString *)userId{       
    [self completeLoginFailed];
}

/*!
 * set facebook API Key
 */
+ (void)setDropboxAPIKey:(NSString *)APIKey andSecret:(NSString *)APISecret{
    ENGPhotoSubmitterDropboxAPIKey = APIKey;
    ENGPhotoSubmitterDropboxAPISecret = APISecret;
}

@end
