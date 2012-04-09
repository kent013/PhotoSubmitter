//
//  SalesforcePhotoSubmitter.m
//  tottepost
//
//  Created by Kentaro ISHITOYA on 12/04/08.
//  Copyright (c) 2012 cocotomo. All rights reserved.
//

#if ! __has_feature(objc_arc)
#error This file must be compiled with ARC. Use -fobjc-arc flag (or convert project to ARC).
#endif

#define RKLogLevelDefault RKLogLevelError

#import "SalesforceAPIKey.h"
#import "SalesforcePhotoSubmitter.h"
#import "PhotoSubmitterManager.h"
#import "RegexKitLite.h"
#import "RestKit.h"
#import "SFMappingManager.h"
#import "SFUser.h"
#import "SFAuthContext.h"
#import "SFOAuthViewController.h"
#import "SFConfig.h"

//-----------------------------------------------------------------------------
//Private Implementations
//-----------------------------------------------------------------------------
@interface SalesforcePhotoSubmitter(PrivateImplementation)
- (void) setupInitialState;
- (void) clearCredentials;
- (void) initRestKitAndUser;
- (NSString*)addTextParam:(NSString*)param value:(NSString*)value body:(NSString*)body boundary:(NSString*)boundary;
- (id)onSubmitContent:(PhotoSubmitterContentEntity *)content andOperationDelegate:(id<PhotoSubmitterPhotoOperationDelegate>)delegate;
@end

@implementation SalesforcePhotoSubmitter(PrivateImplementation)
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
    
	// Re-initialize RestKit with the current instance URL.
	[SFMappingManager initialize];
    //RKObjectManager* objectManager = [RKObjectManager sharedManager];
    //objectManager.client.baseURL = [RKURL URLWithString: SALESFORCE_SUBMITTER_API_LOGIN_SERVER];
    //objectManager.client.authenticationType = RKRequestAuthenticationTypeOAuth2;
}

/*!
 * clear Salesforce credential
 */
- (void)clearCredentials{
	[[SFAuthContext context] clear];
}

/*!
 * initialize restkit
 */
- (void)initRestKitAndUser {
	// Re-initialize RestKit with the current instance URL.
	[SFMappingManager initialize];
    self.username = [SFAuthContext context].identity.display_name;
}

/*!
 * add text param to request
 */
- (NSString*)addTextParam:(NSString*)param value:(NSString*)value body:(NSString*)body boundary:(NSString*)boundary {
	NSString* start = [NSString stringWithFormat:@"%@Content-Disposition: form-data; name=\"%@\"\r\n\r\n", body, param];
	return [NSString stringWithFormat:@"%@%@%@", start, value, boundary];
}

/*!
 * submit content
 */
- (id)onSubmitContent:(PhotoSubmitterContentEntity *)content andOperationDelegate:(id<PhotoSubmitterPhotoOperationDelegate>)delegate{
    
    NSString *url = [SFConfig addVersionPrefix:@"/chatter/feeds/news/me/feed-items"];
    
	// Post the photo to the group, using a regular HTTP POST because
	// RestKit doesn't support multipart binary posts yet.
	NSString* targetUrl = [NSString stringWithFormat:@"%@%@", [[SFAuthContext context] instanceUrl], url];
	
	// Make the request.
	NSMutableURLRequest* request = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:targetUrl]
														   cachePolicy:NSURLRequestReloadIgnoringLocalCacheData // Don't use the cache.
													   timeoutInterval:60];
	
	[[SFAuthContext context] addOAuthHeaderToNSRequest:request];
	[request setHTTPMethod:@"POST"];
	
	NSString* boundary = @"-----------------2342342352342343";
	
	[request addValue:[NSString stringWithFormat:@"multipart/form-data; boundary=%@", boundary]
   forHTTPHeaderField:@"Content-Type"];
	
	// Assemble the body.
	NSString* boundaryBreak = [NSString stringWithFormat:@"\r\n--%@\r\n", boundary];
	NSString* body = boundaryBreak;
    
    if(content.comment != nil){
        body = [self addTextParam:@"text" value:content.comment body:body boundary:boundaryBreak];
    }
	
	NSDateFormatter* dateFormat = [[NSDateFormatter alloc] init];
	[dateFormat setDateFormat:@"M/d/y h:m:s"];
    
    NSDateFormatter *df = [[NSDateFormatter alloc] init];
    df.dateFormat  = @"yyyyMMddHHmmssSSSS";
    NSString *filename = nil;
    if(content.isPhoto){
        filename = [NSString stringWithFormat:@"%@.jpg", [df stringFromDate:content.timestamp]];
    }else{
        filename = [NSString stringWithFormat:@"%@.mp4", [df stringFromDate:content.timestamp]];
    }
	
	body = [self addTextParam:@"fileName" value:filename body:body boundary:boundaryBreak];
	
	body = [NSString stringWithFormat:@"%@Content-Disposition: form-data; name=\"feedItemFileUpload\"; filename=\"%@\"\r\n", body, filename];
	body = [NSString stringWithFormat:@"%@Content-Type: application/octet-stream\r\n\r\n", body];
	
	NSMutableData* bodyData = [NSMutableData data];
	[bodyData appendData:[body dataUsingEncoding:NSUTF8StringEncoding]];
	[bodyData appendData:content.data];
	
	NSData* boundaryDataEnd = [[NSString stringWithFormat:@"\r\n--%@--\r\n", boundary] dataUsingEncoding:NSUTF8StringEncoding];
	[bodyData appendData:boundaryDataEnd];
	
	[request setHTTPBody:bodyData];
	
    NSURLConnection *connection = [NSURLConnection connectionWithRequest:request delegate:self];
    return connection;
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

@end

//-----------------------------------------------------------------------------
//Public Implementations
//-----------------------------------------------------------------------------
#pragma mark - public PhotoSubmitter Protocol implementations
@implementation SalesforcePhotoSubmitter
@synthesize authDelegate;
@synthesize dataDelegate;
@synthesize albumDelegate;
/*!
 * initialize
 */
- (id)init{
    self = [super init];
    if (self) {
        [self setupInitialState];
    }
    return self;
}

#pragma mark - authorization
/*!
 * login to Salesforce
 */
-(void)onLogin{
	SFOAuthViewController* oauthViewController = [[SFOAuthViewController alloc] init]; 
	[[[PhotoSubmitterManager sharedInstance].authControllerDelegate requestNavigationControllerToPresentAuthenticationView] pushViewController:oauthViewController animated:YES];
    [SFAuthContext context].delegate = self;
}

/*!
 * logoff from Salesforce
 */
- (void)onLogout{
    [self clearCredentials];
    [self completeLogout];
}

/*!
 * refresh credential
 */
- (void)refreshCredential{
    if([self isSessionValid] == NO){
        [SFMappingManager initialize];
        [[SFAuthContext context] load];
        [[SFAuthContext context] startGettingAccessTokenWithDelegate:self];
    }
}

/*!
 * check is session valid
 */
- (BOOL)isSessionValid{
    return [[SFAuthContext context] accessToken] != nil;
}

#pragma mark - photo
/*!
 * submit photo with data, comment and delegate
 */
- (id)onSubmitPhoto:(PhotoSubmitterImageEntity *)photo andOperationDelegate:(id<PhotoSubmitterPhotoOperationDelegate>)delegate{
    return [self onSubmitContent:photo andOperationDelegate:delegate];
}

/*!
 * submit video
 */
- (id)onSubmitVideo:(PhotoSubmitterVideoEntity *)video andOperationDelegate:(id<PhotoSubmitterPhotoOperationDelegate>)delegate{
    return [self onSubmitContent:video andOperationDelegate:delegate];
}

/*!
 * cancel content upload
 */
- (id)onCancelContentSubmit:(PhotoSubmitterContentEntity *)content{
    NSURLConnection *connection = (NSURLConnection *)[self requestForPhoto:content.contentHash];
    [connection cancel];
    return connection;
}

/*!
 * is video supported
 */
- (BOOL)isVideoSupported{
    return YES;
}

#pragma mark - album
/*!
 * is album supported
 */
- (BOOL)isAlbumSupported{
    return NO;
}

#pragma mark - RKObjectLoaderDelegate implementation.
/*!
 * objects loaded
 */
- (void)objectLoader:(RKObjectLoader *)objectLoader didLoadObjects:(NSArray *)objects {
}

/*!
 * unexpected response
 */
- (void)objectLoaderDidLoadUnexpectedResponse:(RKObjectLoader *)objectLoader {
}

/*!
 * object fetch failed
 */
- (void)objectLoader:(RKObjectLoader *)objectLoader didFailWithError:(NSError *)error {
}

#pragma mark - AccessTokenRefreshDelegate
/*!
 * access token refresh completed
 */
- (void)refreshCompleted{
    [self completeLogin];
}

/*!
 * login completed
 */
- (void)loginCompleted{
    [self initRestKitAndUser];
    [self completeLogin];
}

/*!
 * login completed
 */
- (void)loginCompletedWithError:(NSError *)error{
    NSLog(@"%s, %@", __PRETTY_FUNCTION__, error.description);
    [self completeLoginFailed];
}
@end
