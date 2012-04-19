//
//  MailPhotoSubmitter.m
//  PhotoSubmitter for Mail
//
//  Created by ISHITOYA Kentaro on 11/12/17.
//  Copyright (c) 2011 cocotomo. All rights reserved.
//

#if ! __has_feature(objc_arc)
#error This file must be compiled with ARC. Use -fobjc-arc flag (or convert project to ARC).
#endif

#import "MailPhotoSubmitter.h"
#import "PSLang.h"

#define PS_MAIL_USERNAME @"PSMailUsername"

//-----------------------------------------------------------------------------
//Private Implementations
//-----------------------------------------------------------------------------
@interface MailPhotoSubmitter(PrivateImplementation)
- (void) setupInitialState;
- (id) submitContent:(PhotoSubmitterContentEntity *)content andOperationDelegate:(id<PhotoSubmitterPhotoOperationDelegate>)delegate;
@end

#pragma mark - private implementations
@implementation MailPhotoSubmitter(PrivateImplementation)
/*!
 * initializer
 */
-(void)setupInitialState{
    [self setSubmitterIsConcurrent:YES 
                      isSequencial:YES 
                     usesOperation:YES 
                   requiresNetwork:YES 
                  isAlbumSupported:NO];
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
 * submit content
 */
- (id)submitContent:(PhotoSubmitterContentEntity *)content andOperationDelegate:(id<PhotoSubmitterPhotoOperationDelegate>)delegate{
}
@end

//-----------------------------------------------------------------------------
//Public Implementations
//-----------------------------------------------------------------------------
#pragma mark - public PhotoSubmitter Protocol implementations
@implementation MailPhotoSubmitter
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
 * login to twitter
 */
-(void)onLogin{
}

/*!
 * alert delegate
 */
- (void)alertView:(UIAlertView *)alertView didDismissWithButtonIndex:(NSInteger)buttonIndex{
    if(buttonIndex == 1){
        [[UIApplication sharedApplication] openURL:[NSURL URLWithString:@"prefs:root=MAIL"]];
    }
}

/*!
 * logoff from twitter
 */
- (void)onLogout{
}

/*!
 * is session valid
 */
- (BOOL)isSessionValid{
    return self.isEnabled;
}

/*!
 * check is logined
 */
- (BOOL)isLogined{
    return self.isEnabled;
}

#pragma mark - photo
/*!
 * submit photo
 */
- (id)onSubmitPhoto:(PhotoSubmitterImageEntity *)photo andOperationDelegate:(id<PhotoSubmitterPhotoOperationDelegate>)delegate{
    return [self submitContent:photo andOperationDelegate:delegate];
}

/*!
 * submit video
 */
- (id)onSubmitVideo:(PhotoSubmitterVideoEntity *)video andOperationDelegate:(id<PhotoSubmitterPhotoOperationDelegate>)delegate{
    //return [self submitContent:video andOperationDelegate:delegate];
    return nil;
}

/*!
 * cancel content upload
 */
- (id)onCancelContentSubmit:(PhotoSubmitterContentEntity *)content{
    NSURLConnection *connection = 
    (NSURLConnection *)[self requestForPhoto:content.contentHash];
    [connection cancel];
    return connection;
}

/*!
 * is video supported
 */
- (BOOL)isVideoSupported{
    return NO;
}

#pragma mark - albums
#pragma mark - username
/*!
 * get username
 */
- (NSString *)username{ 
}

/*!
 * update username
 */
- (void)updateUsernameWithDelegate:(id<PhotoSubmitterDataDelegate>)delegate{
    self.dataDelegate = delegate;
    [self.dataDelegate photoSubmitter:self didUsernameUpdated:self.username];
}
@end
