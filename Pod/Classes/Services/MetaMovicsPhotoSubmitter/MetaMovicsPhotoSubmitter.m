//
//  MetaMovicsPhotoSubmitter.m
//  PhotoSubmitter for MetaMovics
//
//  Created by Kentaro ISHITOYA on 12/02/22.
//  Copyright (c) 2012 cocotomo. All rights reserved.
//

#if ! __has_feature(objc_arc)
#error This file must be compiled with ARC. Use -fobjc-arc flag (or convert project to ARC).
#endif

#import <AVFoundation/AVFoundation.h>
#import "MetaMovicsPhotoSubmitter.h"
#import "MetaMovicsAPIKey.h"
#import "PhotoSubmitterAccountTableViewController.h"
#import "PhotoSubmitterManager.h"
#import "ZipArchive.h"

#define PS_METAMOVICS_AUTH_USERID @"PSMetaMovicsUserId"
#define PS_METAMOVICS_AUTH_PASSWORD @"PSMetaMovicsPassword"
#define PS_METAMOVICS_AUTH_TOKEN @"PSMetaMovicsToken"

static NSString *kDefaultAlbum = @"tottepost";
static NSString *kMetaMovicsTempVideoURL = @"kMetaMovicsTempVideoDirURL";

//-----------------------------------------------------------------------------
//Private Implementations
//-----------------------------------------------------------------------------
@interface MetaMovicsPhotoSubmitter(PrivateImplementation)
- (void) setupInitialState;
- (void) clearCredentials;
- (void) loadCredentials;
- (void) getUserInfomation;
- (id) submitContent:(PhotoSubmitterContentEntity *)content uploadId:(NSString *)uploadId andDelegate:(id<PhotoSubmitterPhotoOperationDelegate>)delegate;
- (NSData *) createZipFileFromVideo:(PhotoSubmitterVideoEntity *)video;
- (NSURL *)tempZipURL;
- (UIImage *)generateImageForUrl:(NSURL *)url time:(int)time;
@end

#pragma mark - private implementations
@implementation MetaMovicsPhotoSubmitter(PrivateImplementation)
/*!
 * initializer
 */
-(void)setupInitialState{
    [self setSubmitterIsConcurrent:YES 
                      isSequencial:NO 
                     usesOperation:YES 
                   requiresNetwork:YES 
                  isAlbumSupported:NO];
    
    self.username = [self secureSettingForKey:PS_METAMOVICS_AUTH_USERID];
    metamovics_ =[[MetaMovicsConnect alloc] initWithUsername:[self secureSettingForKey:PS_METAMOVICS_AUTH_USERID]
                                                    password:[self secureSettingForKey:PS_METAMOVICS_AUTH_USERID]
                                                       token:[self secureSettingForKey:PS_METAMOVICS_AUTH_TOKEN]
                                                 andDelegate:self];
    
    contents_ = [[NSMutableDictionary alloc] init];
    [self loadCredentials];
}

/*!
 * clear MetaMovics access token key
 */
- (void)clearCredentials{
    [self removeSecureSettingForKey:PS_METAMOVICS_AUTH_USERID];
    [self removeSecureSettingForKey:PS_METAMOVICS_AUTH_PASSWORD];
    userId_ = nil;
    password_ = nil;
    [super clearCredentials];
}

/*!
 * load saved credentials
 */
- (void)loadCredentials{
    if([self secureSettingExistsForKey:PS_METAMOVICS_AUTH_USERID]){
        userId_ = [self secureSettingForKey:PS_METAMOVICS_AUTH_USERID];
        password_ = [self secureSettingForKey:PS_METAMOVICS_AUTH_PASSWORD];
    }
}

/*!
 * get user information
 */
- (void)getUserInfomation{
    self.username = [self secureSettingForKey:PS_METAMOVICS_AUTH_USERID];
}

/*!
 * submit content
 */
- (id)submitContent:(PhotoSubmitterContentEntity *)content uploadId:(NSString *)uploadId andDelegate:(id<PhotoSubmitterPhotoOperationDelegate>)delegate{
    
    PhotoSubmitterVideoEntity *video = (PhotoSubmitterVideoEntity *)content;
    NSData *zipFile = [self createZipFileFromVideo:video];
    AVURLAsset *asset = [[AVURLAsset alloc] initWithURL:[NSURL fileURLWithPath:video.path] options:nil];
    AVAssetTrack *videoTrack = [[asset tracksWithMediaType:AVMediaTypeVideo] objectAtIndex:0];
    CGSize size = [videoTrack naturalSize];
    video.width = size.width;
    video.height = size.height;
    video.length = (int)(CMTimeGetSeconds(asset.duration) * 1000);
    
    NSString *caption = content.comment;
    if(caption == nil){
        caption = @"tottepost video";
    }
    
    MetaMovicsRequest *request = [metamovics_ uploadVideoFileWithSessionId:uploadId duration:video.length width:video.width height:video.height data:zipFile andDelegate:self];
    
    [self setPhotoHash:content.contentHash forRequest:request];
    [self addRequest:request];
    [self setOperationDelegate:delegate forRequest:request];
    [self photoSubmitter:self willStartUpload:content.contentHash];

    return  request;
}

/*!
 * create zip from content
 */
- (NSData *) createZipFileFromVideo:(PhotoSubmitterVideoEntity *)video{
    NSURL *url = [self tempZipURL];
    NSURL *videoUrl = [url URLByAppendingPathComponent:@"videos/1.mp4" isDirectory:NO];
    [video.data writeToURL:videoUrl atomically:YES];
    NSURL *thumbUrl = [url URLByAppendingPathComponent:@"thumbnail/thumbnail.jpg" isDirectory:NO];
    
    UIImage *image = [self generateImageForUrl:videoUrl time:1];
    NSData *thumbData = UIImageJPEGRepresentation(image, 1.0);
    [thumbData writeToURL:thumbUrl atomically:YES];
    
    NSURL *zipUrl = [url URLByAppendingPathComponent:@"videos/video.zip" isDirectory:NO];
    NSLog(@"%@", zipUrl);
    ZipArchive *zip = [[ZipArchive alloc] init];
    [zip CreateZipFile2:zipUrl.path];
    [zip addFileToZip:videoUrl.path newname:@"videos/1.mp4"];
    [zip addFileToZip:thumbUrl.path newname:@"thumbnail/thumbnail.jpg"];
    [zip CloseZipFile2];
    video.path = videoUrl.path;
    return [NSData dataWithContentsOfURL:zipUrl];
}

- (UIImage *)generateImageForUrl:(NSURL *)url time:(int)time
{
    AVURLAsset *asset = [[AVURLAsset alloc] initWithURL:url options:nil];
    AVAssetImageGenerator *generate = [[AVAssetImageGenerator alloc] initWithAsset:asset];
    generate.appliesPreferredTrackTransform = YES;
    generate.maximumSize = CGSizeMake(224, 126);
    NSError *err = NULL;
    CMTime cmtime = CMTimeMake(0, time);
    CGImageRef imgRef = [generate copyCGImageAtTime:cmtime actualTime:NULL error:&err];
    return [[UIImage alloc] initWithCGImage:imgRef];
}



/*!
 * get temp zip URL
 */
- (NSURL *)tempZipURL{
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    NSNumber *num = [defaults objectForKey:kMetaMovicsTempVideoURL];
    int n = [num intValue];
    if(n > 5){
        n = 0;
    }else{
        n++;
    }
    
    NSFileManager *manager = [NSFileManager defaultManager];
    NSString *dirname = [NSString stringWithFormat:@"%@/tmp/metamovics/%d/", NSHomeDirectory(), n];
    
    NSURL *url = [NSURL fileURLWithPath:dirname];
    @synchronized(self){
        if([manager fileExistsAtPath:url.path]){
            [manager removeItemAtURL:url error:nil];
        }
        while([manager fileExistsAtPath:url.path]){
            [NSThread sleepForTimeInterval:1];
        }
        //NSLog(@"deleted");
        [defaults setObject:[NSNumber numberWithInt:n] forKey:kMetaMovicsTempVideoURL];
    };
    
    NSError *error;
    if([manager fileExistsAtPath:dirname] == NO){
        [manager createDirectoryAtPath:dirname withIntermediateDirectories:YES attributes:nil error:&error];
    }
    [manager createDirectoryAtPath:[dirname stringByAppendingString:@"videos"] withIntermediateDirectories:YES attributes:nil error:&error];
    
    [manager createDirectoryAtPath:[dirname stringByAppendingString:@"thumbnail"] withIntermediateDirectories:YES attributes:nil error:&error];
    
    return url;
}
@end

//-----------------------------------------------------------------------------
//Public Implementations
//-----------------------------------------------------------------------------
#pragma mark - public implementations
@implementation MetaMovicsPhotoSubmitter
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
 * login to MetaMovics
 */
-(void)onLogin{
    authController_ = [[PhotoSubmitterAccountTableViewController alloc] init];
    authController_.delegate = self;
    [self presentAuthenticationView:authController_];
}

/*!
 * logoff from MetaMovics
 */
- (void)onLogout{  
    [metamovics_ logout];
}

/*!
 * refresh credential
 */
- (void)refreshCredential{
    if([metamovics_ isSessionValid] == NO){
        userId_ = [self secureSettingForKey:PS_METAMOVICS_AUTH_USERID];
        password_ = [self secureSettingForKey:PS_METAMOVICS_AUTH_PASSWORD];
        [metamovics_ refreshCredentialWithUsername:userId_ password:password_ andPermission:nil];
    }
}

- (BOOL)isSessionValid{
    return [metamovics_ isSessionValid];
}

#pragma mark - content
/*!
 * submit photo
 */
- (void) submitPhoto:(PhotoSubmitterImageEntity *)photo andOperationDelegate:(id<PhotoSubmitterPhotoOperationDelegate>)delegate{
    return;
}

/*!
 * submit video
 */
- (void) submitVideo:(PhotoSubmitterVideoEntity *)video andOperationDelegate:(id<PhotoSubmitterPhotoOperationDelegate>)delegate{
    if(delegate.isCancelled){
        return;
    }

    MetaMovicsRequest *request = [metamovics_ getUploadSessionTokenWithDelegate:self];

    [contents_ setObject:video forKey:video.contentHash];
    [self setPhotoHash:video.contentHash forRequest:request];
    [self setOperationDelegate:delegate forRequest:request];
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
    MetaMovicsRequest *request = (MetaMovicsRequest *)[self requestForPhoto:content.contentHash];
    [request cancel];
    return request;
}

#pragma mark - username
/*!
 * update username
 */
- (void)updateUsernameWithDelegate:(id<PhotoSubmitterDataDelegate>)delegate{
    self.dataDelegate = delegate;
    [delegate photoSubmitter:self didUsernameUpdated:[self secureSettingForKey:PS_METAMOVICS_AUTH_USERID]];
}

#pragma mark - MetaMovicsConnectSessionDelegate
/*!
 * did login to metamovics
 */
-(void)metamovicsDidLogin{
    self.username = [self secureSettingForKey:PS_METAMOVICS_AUTH_USERID];
    userId_ = [self secureSettingForKey:PS_METAMOVICS_AUTH_USERID];
    password_ = [self secureSettingForKey:PS_METAMOVICS_AUTH_PASSWORD];
    [self setSecureSetting:metamovics_.token forKey:PS_METAMOVICS_AUTH_TOKEN];
    [authController_ didLogin];
    [self completeLogin];
}

/*!
 * did logout from metamovics
 */
- (void)metamovicsDidLogout{
    [authController_ didLoginFailed];
    [self completeLogout];
}

/*!
 * attempt to login, but not logined
 */
- (void)metamovicsDidNotLogin{
    [authController_ didLoginFailed];
    [self completeLoginFailed];
    
}

#pragma mark - PhotoSubmitterPasswordAuthDelegate
/*!
 * did canceled
 */
- (void)didCancelPasswordAuthView:(UIViewController *)passwordAuthViewController{
    [self disable];
}

/*!
 * did present user id
 */
- (void)passwordAuthView:(UIView *)passwordAuthView didPresentUserId:(NSString *)userId password:(NSString *)password{
    [self setSecureSetting:userId forKey:PS_METAMOVICS_AUTH_USERID];
    [self setSecureSetting:password forKey:PS_METAMOVICS_AUTH_PASSWORD];
    [metamovics_ loginWithUsername:userId password:password andPermission:nil];

}

#pragma mark - PhotoSubmitterDataDelegate
/*!
 * did album updated
 */
- (void)photoSubmitter:(id<PhotoSubmitterProtocol>)photoSubmitter didAlbumUpdated:(NSArray *)albums{
}

/*!
 * did username updated
 */
- (void)photoSubmitter:(id<PhotoSubmitterProtocol>)photoSubmitter didUsernameUpdated:(NSString *)username{
}

#pragma mark - PhotoSubmitterMetaMovicsRequestDelegate
/*!
 * did load
 */
- (void)request:(MetaMovicsRequest *)request didLoad:(id)result{
    PhotoSubmitterVideoEntity *content =
        [contents_ objectForKey:[self photoForRequest:request]];
    
    id<PhotoSubmitterPhotoOperationDelegate> delegate =
        [self operationDelegateForRequest:request];
    
    if([request.tag isEqualToString:kMetaMovicsRequestGetSessionToken]){
        [self clearRequest:request];        
        [self submitContent:content uploadId:[[result objectForKey:@"id"] stringValue] andDelegate:delegate];
    }else if([request.tag isEqualToString:kMetaMovicsRequestUpload]){
        [self clearRequest:request];
        
        MetaMovicsRequest *r = [metamovics_ createPageWithVideoId: [[result objectForKey:@"id"] stringValue]
                                categoryId:@"73"
                                   caption:content.comment
                               andDelegate:self];
        
        [self setPhotoHash:content.contentHash forRequest:r];
        [self addRequest:r];
        [self setOperationDelegate:delegate forRequest:r];
    }else if([request.tag isEqualToString:kMetaMovicsRequestCreatePage]){
        [self completeSubmitContentWithRequest:request];
    }else{
        NSLog(@"%s", __PRETTY_FUNCTION__);
    }
}

/*!
 * request failed
 */
- (void)request:(MetaMovicsRequest *)request didFailWithError:(NSError *)error{
    if([request.tag isEqualToString:kMetaMovicsRequestGetSessionToken] ||
       [request.tag isEqualToString:kMetaMovicsRequestUpload] ||
       [request.tag isEqualToString:kMetaMovicsRequestCreatePage]){
        [self completeSubmitContentWithRequest:request andError:error];
        NSLog(@"%s, %@", __PRETTY_FUNCTION__, error);
    }else{
        NSLog(@"%s, %@", __PRETTY_FUNCTION__, error);
        if(error.code == 401){
            [self logout];
        }
    }
    [self clearRequest:request];
}

/*!
 * progress
 */
- (void)request:(MetaMovicsRequest *)request didSendBodyData:(NSInteger)bytesWritten totalBytesWritten:(NSInteger)totalBytesWritten totalBytesExpectedToWrite:(NSInteger)totalBytesExpectedToWrite{
    if([request.tag isEqualToString:kMetaMovicsRequestUpload]){
        CGFloat progress = (float)totalBytesWritten / (float)totalBytesExpectedToWrite;
        NSString *hash = [self photoForRequest:request];
        [self photoSubmitter:self didProgressChanged:hash progress:progress];
    }
}
@end
