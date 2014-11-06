//
//  FacebookPhotoSubmitter.m
//  PhotoSubmitter for Facebook
//
//  Created by ISHITOYA Kentaro on 11/12/13.
//  Copyright (c) 2011 cocotomo. All rights reserved.
//

#if ! __has_feature(objc_arc)
#error This file must be compiled with ARC. Use -fobjc-arc flag (or convert project to ARC).
#endif

#import "FacebookAPIKey.h"
#import "FacebookPhotoSubmitter.h"
#import "RegexKitLite.h"
#import "PhotoSubmitterAlbumEntity.h"
#import "PhotoSubmitterManager.h"

#define PS_FACEBOOK_AUTH_TOKEN_KEY @"PSFacebook%@AccessTokenKey"
#define PS_FACEBOOK_AUTH_EXPIRATION_DATE_KEY @"PSFacebook%@ExpirationDateKey"

#define PS_FACEBOOK_PHOTO_WIDTH 960
#define PS_FACEBOOK_PHOTO_HEIGHT 720

static NSString *PhotoSubmitterFacebookAuthRequestAccount;

//-----------------------------------------------------------------------------
//Private Implementations
//-----------------------------------------------------------------------------
@interface FacebookPhotoSubmitter(PrivateImplementation)
- (void) setupInitialState;
- (void) getUserInfomation;
- (NSString *) accessTokenKey;
- (NSString *) expirationKey;
@end

#pragma mark - private implementations
@implementation FacebookPhotoSubmitter(PrivateImplementation)
/*!
 * initializer
 */
-(void)setupInitialState{
    [self setSubmitterIsConcurrent:YES 
                      isSequencial:NO 
                     usesOperation:YES 
                   requiresNetwork:YES 
                  isAlbumSupported:YES];
    facebook_ = [[Facebook alloc] initWithAppId:PHOTO_SUBMITTER_FACEBOOK_API_ID urlSchemeSuffix:[PhotoSubmitterManager photoSubmitterCustomSchemaSuffix] andDelegate:self];
    if ([self settingExistsForKey:self.accessTokenKey] 
        && [self settingExistsForKey:self.expirationKey]) {
        facebook_.accessToken = [self settingForKey:self.accessTokenKey];
        facebook_.expirationDate = [self settingForKey:self.expirationKey];
    }
}

/*!
 * recover old settings
 */
- (void) recoverOldSettings{
    [super recoverOldSettings];
    if([self settingExistsForKey:@"PSFacebookAccessTokenKey"] && 
       [self settingExistsForKey:self.accessTokenKey] == NO){
        [self setSetting:[self settingForKey:@"PSFacebookAccessTokenKey"] forKey:self.accessTokenKey];
        [self removeSettingForKey:@"PSFacebookAccessTokenKey"];
    }
}

/*!
 * clear facebook access token key
 */
- (void)clearCredentials{
    if ([self settingExistsForKey:self.accessTokenKey]) {
        [self removeSettingForKey:self.accessTokenKey];
        [self removeSettingForKey:self.expirationKey];
    } 
    [super clearCredentials];
}

/*!
 * get user information
 */
- (void)getUserInfomation{
    [facebook_ requestWithGraphPath:@"me" andDelegate:self];
}

/*!
 * get authtoken key
 */
- (NSString *)accessTokenKey{
    return [NSString stringWithFormat:PS_FACEBOOK_AUTH_TOKEN_KEY, self.account.accountHash];
}

/*!
 * get expiration key
 */
- (NSString *)expirationKey{
    return [NSString stringWithFormat:PS_FACEBOOK_AUTH_EXPIRATION_DATE_KEY, self.account.accountHash];
}

#pragma mark - FBRequestWithUploadProgressDelegate
/*!
 * facebook request delegate, did load
 */
- (void)request:(FBRequest *)request didLoad:(id)result {
    if([request.url isMatchedByRegex:@"me$"]){
        if ([result isKindOfClass:[NSArray class]]) {
            result = [result objectAtIndex:0];
        }
        NSString *username = [[result objectForKey:@"name"] stringByReplacingOccurrencesOfRegex:@" +" withString:@" "];
        self.username = username;
    }else if([request.url isMatchedByRegex:@"photos$"] ||
             [request.url isMatchedByRegex:@"videos$"]){
        [self completeSubmitContentWithRequest:request];
    }else if([request.url isMatchedByRegex:@"albums$"] && 
             [request.httpMethod isEqualToString:@"POST"]){
        NSDictionary *a = [result objectForKey:@"data"];
        PhotoSubmitterAlbumEntity *album = 
        [[PhotoSubmitterAlbumEntity alloc] initWithId:[a objectForKey:@"id"] name:@"" privacy:@""];
        [self.albumDelegate photoSubmitter:self didAlbumCreated:album suceeded:YES withError:nil];
    }else if([request.url isMatchedByRegex:@"albums$"] && 
             [request.httpMethod isEqualToString:@"GET"]){
        NSArray *as = [result objectForKey:@"data"];
        NSMutableArray *albums = [[NSMutableArray alloc] init];
        for(NSDictionary *a in as){
            PhotoSubmitterAlbumEntity *album = 
            [[PhotoSubmitterAlbumEntity alloc] initWithId:[a objectForKey:@"id"] name:[a objectForKey:@"name"] privacy:[a objectForKey:@"privacy"]];
            [albums addObject:album];
            if(self.targetAlbum != nil && [self.targetAlbum.albumId isEqualToString:album.albumId]){
                self.targetAlbum = album;
            }
        }
        self.albumList = albums;
    }else{
        NSLog(@"%s", __PRETTY_FUNCTION__);
    }
    [self clearRequest:request];
};

/*!
 * facebook request delegate, did fail
 */
- (void)request:(FBRequest *)request didFailWithError:(NSError *)error {
    NSLog(@"%@, %@", request.url, error.description);
    if([request.url isMatchedByRegex:@"me$"]){
    }else if([request.url isMatchedByRegex:@"albums$"] && 
             [request.httpMethod isEqualToString:@"GET"]){
    }else if([request.url isMatchedByRegex:@"albums$"] && 
             [request.httpMethod isEqualToString:@"POST"]){
        [self.albumDelegate photoSubmitter:self didAlbumCreated:nil suceeded:NO withError:error];
    }else if([request.url isMatchedByRegex:@"photos$"] ||
             [request.url isMatchedByRegex:@"videos$"]){
        [self completeSubmitContentWithRequest:request andError:error];
    }
    [self clearRequest:request];
};

/*!
 * facebook request delegate, upload progress
 */
- (void)request:(FBRequest *)request didSendBodyData:(NSInteger)bytesWritten totalBytesWritten:(NSInteger)totalBytesWritten totalBytesExpectedToWrite:(NSInteger)totalBytesExpectedToWrite{
    CGFloat progress = (float)totalBytesWritten / (float)totalBytesExpectedToWrite;
    NSString *hash = [self photoForRequest:request];
    [self photoSubmitter:self didProgressChanged:hash progress:progress];
}
@end

//-----------------------------------------------------------------------------
//Public Implementations
//-----------------------------------------------------------------------------
#pragma mark - public PhotoSubmitter Protocol implementations
@implementation FacebookPhotoSubmitter
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
 * login to facebook
 */
-(void)onLogin{
    NSArray *permissions = 
    [NSArray arrayWithObjects:@"publish_stream", @"user_location", @"user_photos", @"offline_access", @"user_videos", nil];
    [facebook_ authorize:permissions];
    PhotoSubmitterFacebookAuthRequestAccount = self.account.accountHash;
}

/*!
 * logoff from facebook
 */
- (void)onLogout{
    [facebook_ logout:self];   
}

/*!
 * refresh credential
 */
- (void)refreshCredential{
    [facebook_ extendAccessTokenIfNeeded];
}

/*!
 * check url is processable
 */
- (BOOL)isProcessableURL:(NSURL *)url{
    if([url.absoluteString isMatchedByRegex:@"^fb[0-9]+"] &&
       [PhotoSubmitterFacebookAuthRequestAccount isEqualToString:self.account.accountHash]){
        return YES;
    }
    return NO;
}

/*!
 * on open url finished
 */
- (BOOL)didOpenURL:(NSURL *)url{
    return [facebook_ handleOpenURL:url];
}

/*!
 * is session valid
 */
- (BOOL)isSessionValid{
    if ([self settingForKey:self.accessTokenKey]) {
        return YES;
    }
    return NO;
}

/*!
 * multiple account support
 */
- (BOOL)isMultipleAccountSupported{
    return YES;
}

#pragma mark - contents
/*!
 * submit photo with data, comment and delegate
 */
- (id)onSubmitPhoto:(PhotoSubmitterImageEntity *)photo andOperationDelegate:(id<PhotoSubmitterPhotoOperationDelegate>)delegate{
    CGSize size = CGSizeMake(PS_FACEBOOK_PHOTO_WIDTH, PS_FACEBOOK_PHOTO_HEIGHT);
    if(photo.image.size.width < photo.image.size.height){
        size = CGSizeMake(PS_FACEBOOK_PHOTO_HEIGHT, PS_FACEBOOK_PHOTO_WIDTH);
    }
    
    NSMutableDictionary *params = 
    [NSMutableDictionary dictionaryWithObjectsAndKeys: 
     [photo resizedImage:size], @"source", 
     photo.comment, @"name",
     nil];
    NSString *path = @"me/photos";
    if(self.targetAlbum != nil){
        path = [NSString stringWithFormat:@"%@/photos", self.targetAlbum.albumId];
    }
    FBRequest *request = [facebook_ requestWithGraphPath:path andParams:params andHttpMethod:@"POST" andDelegate:self];
    return request;
}

/*!
 * submit video
 */
- (id)onSubmitVideo:(PhotoSubmitterVideoEntity *)video andOperationDelegate:(id<PhotoSubmitterPhotoOperationDelegate>)delegate{    
    NSMutableDictionary *params = 
    [NSMutableDictionary dictionaryWithObjectsAndKeys: 
     video.data, @"source", 
     video.comment, @"title",
     nil];
    NSString *path = @"me/videos";
    FBRequest *request = [facebook_ requestWithGraphPath:path andParams:params andHttpMethod:@"POST" andDelegate:self];
    return request;
}

/*!
 * cancel content upload
 */
- (id)onCancelContentSubmit:(PhotoSubmitterContentEntity *)content{
    FBRequest *request = (FBRequest *)[self requestForPhoto:content.contentHash];
    [request.connection cancel];
    return request;
}

/*!
 * maximum video length
 */
- (NSInteger)maximumLengthOfVideo{
    return 180 * 60;
}

#pragma mark - albums
/*!
 * create album
 */
- (void)createAlbum:(NSString *)title withDelegate:(id<PhotoSubmitterAlbumDelegate>)delegate{
    self.albumDelegate = delegate;
    NSMutableDictionary *params = 
    [NSMutableDictionary dictionaryWithObjectsAndKeys: 
     @"", @"message", 
     title, @"name",
     nil];
    NSString *path = @"me/albums";
    FBRequest *request = [facebook_ requestWithGraphPath:path andParams:params andHttpMethod:@"POST" andDelegate:self];
    [self addRequest:request];
}

/*!
 * update album list
 */
- (void)updateAlbumListWithDelegate:(id<PhotoSubmitterDataDelegate>)delegate{
    self.dataDelegate = delegate;
    [facebook_ requestWithGraphPath:@"me/albums" andDelegate:self];
}

#pragma mark - username
/*!
 * update username
 */
- (void)updateUsernameWithDelegate:(id<PhotoSubmitterDataDelegate>)delegate{
    self.dataDelegate = delegate;
    [self getUserInfomation];
}

#pragma mark - FBSessionDelegate methods
/*!
 * facebook delegate, did login suceeded
 */
- (void)fbDidLogin {
    [self setSetting:[facebook_ accessToken] forKey:self.accessTokenKey];
    [self setSetting:[facebook_ expirationDate] forKey:self.expirationKey];
    
    [self completeLogin];
    [self getUserInfomation];
}

/*!
 * facebook delegate, if not login
 */
-(void)fbDidNotLogin:(BOOL)cancelled {
    [self completeLoginFailed];
}

/*!
 * facebook delegate, if logout
 */
- (void) fbDidLogout {
    [self completeLogout];
}

/*!
 * facebook session invalidated
 */
- (void) fbSessionInvalidated{
    [facebook_ extendAccessTokenIfNeeded];
}

/*!
 * facebook session extended
 */
- (void)fbDidExtendToken:(NSString *)accessToken expiresAt:(NSDate *)expiresAt{
}
@end
