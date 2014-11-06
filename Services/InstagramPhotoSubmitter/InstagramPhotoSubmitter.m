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
#import "PSLang.h"

#define PS_INSTAGRAM_URL @"instagram://app"

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
                  isAlbumSupported:NO];
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
    if (![[UIApplication sharedApplication] canOpenURL:[NSURL URLWithString:PS_INSTAGRAM_URL]]) {
        UIAlertView *alert =
        [[UIAlertView alloc] initWithTitle:[PSLang localized:@"Instagram_AppNotFound_Title"] 
                                   message:[PSLang localized:@"Instagram_AppNotFound_Message"]
                                  delegate:self 
                         cancelButtonTitle:
         [PSLang localized:@"Instagram_AppNotFound_Button_Title"]
                         otherButtonTitles:nil];
        [alert show];
        [self completeLoginFailed];
        return;
    }
    [self completeLogin];
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
    return self.isEnabled;
}

#pragma mark - photo
/*!
 * submit photo with data, comment and delegate
 */
- (void)submitPhoto:(PhotoSubmitterImageEntity *)photo andOperationDelegate:(id<PhotoSubmitterPhotoOperationDelegate>)delegate{
    if(delegate.isCancelled){
        return;
    }
    
    NSDateFormatter *df = [[NSDateFormatter alloc] init];
    df.dateFormat  = @"yyyyMMddHHmmssSSSS";
    NSString *dir = [NSString stringWithFormat:@"%@/Documents/", NSHomeDirectory()];
    NSString *filename = [NSString stringWithFormat:@"instagram_%@.igo", [df stringFromDate:photo.timestamp]];
    NSString *path = [dir stringByAppendingString:filename];
    photo.contentHash = path;
    [[photo squareData:CGSizeMake(612, 612)] writeToFile:path atomically:NO];
    
    interactionController_ = [UIDocumentInteractionController interactionControllerWithURL:[NSURL fileURLWithPath:path]];
    interactionController_.delegate = self;
    interactionController_.UTI = @"com.instagram.exclusivegram";
    
    if(photo.comment != nil){
        interactionController_.annotation = [NSDictionary dictionaryWithObject:photo.comment forKey:@"InstagramCaption"];
    }
    
    UIViewController *vc = [[PhotoSubmitterManager sharedInstance].navigationControllerDelegate requestRootViewControllerForPresentModalView];
    [interactionController_ presentOpenInMenuFromRect:vc.view.frame inView:vc.view animated:YES];

    [delegate photoSubmitterDidOperationFinished:YES];
}

/*!
 * submit photo with data, comment and delegate
 */
- (id) onSubmitPhoto:(PhotoSubmitterImageEntity *)photo andOperationDelegate:(id<PhotoSubmitterPhotoOperationDelegate>)delegate{
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

#pragma mark - other properties
/*!
 * is square
 */
- (BOOL)isSquare{
    return YES;
}

/*!
 * username
 */
- (NSString *)username{
    return @"----";
}
@end
