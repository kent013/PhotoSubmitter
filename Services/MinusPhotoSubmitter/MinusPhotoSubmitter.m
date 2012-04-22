//
//  MinusPhotoSubmitter.m
//  PhotoSubmitter for Minus
//
//  Created by Kentaro ISHITOYA on 12/02/22.
//  Copyright (c) 2012 cocotomo. All rights reserved.
//

#if ! __has_feature(objc_arc)
#error This file must be compiled with ARC. Use -fobjc-arc flag (or convert project to ARC).
#endif

#import "MinusPhotoSubmitter.h"
#import "MinusAPIKey.h"
#import "PhotoSubmitterAccountTableViewController.h"
#import "PhotoSubmitterManager.h"

#define PS_MINUS_AUTH_USERID @"PSMinusUserId"
#define PS_MINUS_AUTH_PASSWORD @"PSMinusPassword"

static NSString *kDefaultAlbum = @"tottepost";

//-----------------------------------------------------------------------------
//Private Implementations
//-----------------------------------------------------------------------------
@interface MinusPhotoSubmitter(PrivateImplementation)
- (void) setupInitialState;
- (void) clearCredentials;
- (void) loadCredentials;
- (void) getUserInfomation;
- (id) submitContent:(PhotoSubmitterContentEntity *)content andOperationDelegate:(id<PhotoSubmitterPhotoOperationDelegate>)delegate;
@end

#pragma mark - private implementations
@implementation MinusPhotoSubmitter(PrivateImplementation)
/*!
 * initializer
 */
-(void)setupInitialState{
    [self setSubmitterIsConcurrent:YES 
                      isSequencial:NO 
                     usesOperation:YES 
                   requiresNetwork:YES 
                  isAlbumSupported:YES];
    
    minus_ = [[MinusConnect alloc] 
              initWithClientId:MINUS_SUBMITTER_CLIENT_ID
              clientSecret:MINUS_SUBMITTER_CLIENT_SECRET
              andDelegate:self];
    [self loadCredentials];
}

/*!
 * clear Minus access token key
 */
- (void)clearCredentials{
    [self removeSecureSettingForKey:PS_MINUS_AUTH_USERID];
    [self removeSecureSettingForKey:PS_MINUS_AUTH_PASSWORD];
    userId_ = nil;
    password_ = nil;
    [super clearCredentials];
}

/*!
 * load saved credentials
 */
- (void)loadCredentials{
    if([self secureSettingExistsForKey:PS_MINUS_AUTH_USERID]){
        userId_ = [self secureSettingForKey:PS_MINUS_AUTH_USERID];
        password_ = [self secureSettingForKey:PS_MINUS_AUTH_PASSWORD];
    }
}

/*!
 * get user information
 */
- (void)getUserInfomation{
    MinusRequest *request = [minus_ activeUserWithDelegate:self];
    [self addRequest:request];
}

/*!
 * submit content
 */
- (id)submitContent:(PhotoSubmitterContentEntity *)content andOperationDelegate:(id<PhotoSubmitterPhotoOperationDelegate>)delegate{
    NSString *folderId = @"";
    if(self.targetAlbum){
        folderId = self.targetAlbum.albumId;
    }
    NSDateFormatter *df = [[NSDateFormatter alloc] init];
    df.dateFormat  = @"yyyyMMddHHmmss";
    NSString *filename = nil;
    NSString *contentType = nil;
    if(content.isPhoto){
        filename = [NSString stringWithFormat:@"%@.jpg", [df stringFromDate:content.timestamp]];
        contentType = @"image/jpeg";
    }else{
        filename = [NSString stringWithFormat:@"%@.mp4", [df stringFromDate:content.timestamp]];
        contentType = @"video/quicktime";
    }
    MinusRequest *request = [minus_ createFileWithFolderId:folderId caption:content.comment filename:filename data:content.data dataContentType:contentType andDelegate:self];
    return  request;
}
@end

//-----------------------------------------------------------------------------
//Public Implementations
//-----------------------------------------------------------------------------
#pragma mark - public implementations
@implementation MinusPhotoSubmitter
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
 * login to Minus
 */
-(void)onLogin{
    authController_ = [[PhotoSubmitterAccountTableViewController alloc] init];
    authController_.delegate = self;
    [self presentAuthenticationView:authController_];
}

/*!
 * logoff from Minus
 */
- (void)onLogout{  
    [minus_ logout];
}

/*!
 * refresh credential
 */
- (void)refreshCredential{
    if([minus_ isSessionValid] == NO){
        userId_ = [self secureSettingForKey:PS_MINUS_AUTH_USERID];
        password_ = [self secureSettingForKey:PS_MINUS_AUTH_PASSWORD];
        [minus_ refreshCredentialWithUsername:userId_ password:password_ andPermission:[NSArray arrayWithObjects:@"read_all", @"upload_new", nil]];
    }
}

- (BOOL)isSessionValid{
    return [minus_ isSessionValid];
}

#pragma mark - content
/*!
 * submit photo with data, comment and delegate
 */
- (id)onSubmitPhoto:(PhotoSubmitterImageEntity *)photo andOperationDelegate:(id<PhotoSubmitterPhotoOperationDelegate>)delegate{
    return [self submitContent:photo andOperationDelegate:delegate];
}    

/*!
 * submit video
 */
- (id)onSubmitVideo:(PhotoSubmitterVideoEntity *)video andOperationDelegate:(id<PhotoSubmitterPhotoOperationDelegate>)delegate{
    return [self submitContent:video andOperationDelegate:delegate];
}

/*!
 * cancel content upload
 */
- (id)onCancelContentSubmit:(PhotoSubmitterContentEntity *)content{
    MinusRequest *request = (MinusRequest *)[self requestForPhoto:content.contentHash];
    [request cancel];
    return request;
}

#pragma mark - album
/*!
 * create album
 */
- (void)createAlbum:(NSString *)title withDelegate:(id<PhotoSubmitterAlbumDelegate>)delegate{
    self.albumDelegate = delegate;
    MinusRequest *request = [minus_ createFolderWithUsername:userId_ name:title isPublic:NO andDelegate:self];
    [self addRequest:request];
}

/*!
 * update album list
 */
- (void)updateAlbumListWithDelegate:(id<PhotoSubmitterDataDelegate>)delegate{
    self.dataDelegate = delegate;
    MinusRequest *request = [minus_ foldersWithUsername:userId_ andDelegate:self];
    [self addRequest:request];
}

#pragma mark - username
/*!
 * update username
 */
- (void)updateUsernameWithDelegate:(id<PhotoSubmitterDataDelegate>)delegate{
    self.dataDelegate = delegate;
    [self getUserInfomation];
}

#pragma mark - MinusConnectSessionDelegate
/*!
 * did login to minus
 */
-(void)minusDidLogin{
    userId_ = [self secureSettingForKey:PS_MINUS_AUTH_USERID];
    password_ = [self secureSettingForKey:PS_MINUS_AUTH_PASSWORD];
    [authController_ didLogin];
    [self getUserInfomation];
    [self completeLogin];
    
    if(self.targetAlbum == nil){
        [self updateAlbumListWithDelegate:self];
    }
}

/*!
 * did logout from minus
 */
- (void)minusDidLogout{
    [authController_ didLoginFailed];
    [self completeLogout];
}

/*!
 * attempt to login, but not logined
 */
- (void)minusDidNotLogin{
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
    [self setSecureSetting:userId forKey:PS_MINUS_AUTH_USERID];
    [self setSecureSetting:password forKey:PS_MINUS_AUTH_PASSWORD];
    [minus_ loginWithUsername:userId password:password andPermission:[NSArray arrayWithObjects:@"read_all", @"upload_new", nil]];

}

#pragma mark - PhotoSubmitterAlbumDelegate
/*!
 * did album created
 */
- (void)photoSubmitter:(id<PhotoSubmitterProtocol>)photoSubmitter didAlbumCreated:(PhotoSubmitterAlbumEntity *)album suceeded:(BOOL)suceeded withError:(NSError *)error{
    if(suceeded){
        self.targetAlbum = album;
    }else{
        NSLog(@"album creation error:%s, %@", __PRETTY_FUNCTION__, error.description);
    }
}

#pragma mark - PhotoSubmitterDataDelegate
/*!
 * did album updated
 */
- (void)photoSubmitter:(id<PhotoSubmitterProtocol>)photoSubmitter didAlbumUpdated:(NSArray *)albums{
    if(self.targetAlbum == nil){
        for(PhotoSubmitterAlbumEntity *album in albums){
            if([album.name isEqualToString:kDefaultAlbum]){
                self.targetAlbum = album;
                break;
            }
        }
    }
    if(self.targetAlbum == nil){
        [self createAlbum:kDefaultAlbum withDelegate:self];
    }
}

/*!
 * did username updated
 */
- (void)photoSubmitter:(id<PhotoSubmitterProtocol>)photoSubmitter didUsernameUpdated:(NSString *)username{
}

#pragma mark - PhotoSubmitterMinusRequestDelegate
/*!
 * did load
 */
- (void)request:(MinusRequest *)request didLoad:(id)result{
    if([request.tag isEqualToString:kMinusRequestActiveUser]){
        if ([result isKindOfClass:[NSArray class]]) {
            result = [result objectAtIndex:0];
        }
        self.username = [result objectForKey:@"display_name"];
    }else if([request.tag isEqualToString:kMinusRequestCreateFile]){
        [self completeSubmitContentWithRequest:request];
    }else if([request.tag isEqualToString:kMinusRequestCreateFolder]){
        [self.albumDelegate photoSubmitter:self didAlbumCreated:nil suceeded:YES withError:nil];
        [self clearRequest:request];
    }else if([request.tag isEqualToString:kMinusRequestFoldersWithUsername]){
        NSArray *as = [result objectForKey:@"results"];
        NSMutableArray *albums = [[NSMutableArray alloc] init];
        for(NSDictionary *a in as){
            NSString *privacy = @"private";
            if([a objectForKey:@"is_public"]){
                privacy = @"public";
            }
            PhotoSubmitterAlbumEntity *album = 
            [[PhotoSubmitterAlbumEntity alloc] initWithId:[a objectForKey:@"id"] name:[a objectForKey:@"name"] privacy:privacy];
            [albums addObject:album];
        }
        self.albumList = albums;
    }else{
        NSLog(@"%s", __PRETTY_FUNCTION__);
    }
}

/*!
 * request failed
 */
- (void)request:(MinusRequest *)request didFailWithError:(NSError *)error{
    if([request.tag isEqualToString:kMinusRequestActiveUser]){
    }else if([request.tag isEqualToString:kMinusRequestCreateFile]){
        [self completeSubmitContentWithRequest:request andError:error];
    }else if([request.tag isEqualToString:kMinusRequestCreateFolder]){
    }else if([request.tag isEqualToString:kMinusRequestFoldersWithUsername]){
        [self.albumDelegate photoSubmitter:self didAlbumCreated:nil suceeded:NO withError:error];
    }else{
        NSLog(@"%s", __PRETTY_FUNCTION__);
        if(error.code == 401){
            [self logout];
        }
    }
    [self clearRequest:request];
}

/*!
 * progress
 */
- (void)request:(MinusRequest *)request didSendBodyData:(NSInteger)bytesWritten totalBytesWritten:(NSInteger)totalBytesWritten totalBytesExpectedToWrite:(NSInteger)totalBytesExpectedToWrite{
    if([request.tag isEqualToString:kMinusRequestCreateFile]){
        CGFloat progress = (float)totalBytesWritten / (float)totalBytesExpectedToWrite;
        NSString *hash = [self photoForRequest:request];
        [self photoSubmitter:self didProgressChanged:hash progress:progress];
    }
}
@end
