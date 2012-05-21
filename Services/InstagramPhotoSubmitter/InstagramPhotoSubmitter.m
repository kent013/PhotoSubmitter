//
//  InstagramPhotoSubmitter.m
//  PhotoSubmitter for Instagram
//
//  Created by Kentaro ISHITOYA on 12/05/20.
//  Copyright (c) 2012 cocotomo. All rights reserved.
//

#if ! __has_feature(objc_arc)
#error This file must be compiled with ARC. Use -fobjc-arc flag (or convert project to ARC).
#endif

#import "InstagramPhotoSubmitter.h"
#import "PhotoSubmitterManager.h"
#import "RegexKitLite.h"

//-----------------------------------------------------------------------------
//Private Implementations
//-----------------------------------------------------------------------------
@interface InstagramPhotoSubmitter(PrivateImplementation)
- (void) setupInitialState;
@end

@implementation InstagramPhotoSubmitter(PrivateImplementation)
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
}
@end

//-----------------------------------------------------------------------------
//Public Implementations
//-----------------------------------------------------------------------------
#pragma mark - public PhotoSubmitter Protocol implementations
@implementation InstagramPhotoSubmitter
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
 * login to Instagram
 */
-(void)onLogin{
}

/*!
 * logoff from Instagram
 */
- (void)onLogout{  
    [self completeLogout];
}

/*!
 * refresh credential
 */
- (void)refreshCredential{
}

/*!
 * check is session valid
 */
- (BOOL)isSessionValid{
    return YES;
}

#pragma mark - photo
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
    return nil;
}

/*!
 * is video supported
 */
- (BOOL)isVideoSupported{
    return NO;
}

#pragma mark - album
/*!
 * is album supported
 */
- (BOOL)isAlbumSupported{
    return NO;
}
@end
