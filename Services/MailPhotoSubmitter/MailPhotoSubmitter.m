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
#import "MailPhotoSubmitterSettingTableViewController.h"
#import "RegexKitLite.h"
#import "PSLang.h"
#import <MessageUI/MessageUI.h>

#define MP_COMMENT_AS_SUBJECT_KEY @"PS_COMMENTASSUBJECT_%@"
#define MP_COMMENT_AS_BODY_KEY @"PS_COMMENTASBODY_%@"
#define MP_CONFIRM_KEY @"PS_CONFIRM_KEY_%@"
#define MP_DEFAULT_SUBJECT_KEY @"PS_DEFAULTSUBJECT_%@"
#define MP_DEFAULT_BODY_KEY @"PS_DEFAULTBODY_%@"
#define MP_SENDTO_KEY @"PS_SENDTO_%@"

//-----------------------------------------------------------------------------
//Private Implementations
//-----------------------------------------------------------------------------
@interface MailPhotoSubmitter(PrivateImplementation)
- (void) setupInitialState;
- (id) submitContent:(PhotoSubmitterContentEntity *)content andOperationDelegate:(id<PhotoSubmitterPhotoOperationDelegate>)delegate;
- (NSString *) commentAsSubjectKey;
- (NSString *) commentAsBodyKey;
- (NSString *) defaultSubjectKey;
- (NSString *) defaultBodyKey;
- (NSString *) sendToKey;
- (NSString *) confirmKey;
- (void) checkForSizeConfirmWindow;
- (void)explode:(id)aView level:(int)level;

@end

#pragma mark - private implementations
@implementation MailPhotoSubmitter(PrivateImplementation)
/*!
 * initializer
 */
-(void)setupInitialState{
    [self setSubmitterIsConcurrent:NO 
                      isSequencial:YES
                     usesOperation:YES 
                   requiresNetwork:YES 
                  isAlbumSupported:NO];
    if([self settingExistsForKey:self.confirmKey] == NO){
        self.confirm = YES;
    }
    if([self settingExistsForKey:self.commentAsBodyKey] == NO){
        self.commentAsBody = YES;
    }
}

- (void)explode:(id)aView level:(int)level {
    NSLog(@"%d, %@", level, [[aView class] description]);
    NSLog(@"%d, %@", level, NSStringFromCGRect([aView frame]));
    for (UIView *subview in [aView subviews]) {
        [self explode:subview level:(level + 1)];
    }
}

#pragma mark - NSURLConnection delegates
/*!
 * submit content
 */
- (id)submitContent:(PhotoSubmitterContentEntity *)content andOperationDelegate:(id<PhotoSubmitterPhotoOperationDelegate>)delegate{
    MFMailComposeViewController *mailComposeViewController = [[MFMailComposeViewController alloc] init];
    if([MFMailComposeViewController canSendMail] == NO){
        [self completeSubmitContentWithRequest:mailComposeViewController andError:nil];
        return mailComposeViewController;
    }
    
    mailComposeViewController.mailComposeDelegate = self;
    [mailComposeViewController setToRecipients:[NSArray arrayWithObject:self.sendTo]];
    
    NSString *subject = nil;
    NSString *body = nil;
    if(content.comment == nil && self.defaultSubject != nil){
        subject = self.defaultSubject;
    }
    if(content.comment != nil && self.commentAsSubject){
        subject = content.comment;
    }
    if(content.comment == nil && self.defaultBody != nil){
        body = self.defaultBody;
    }
    if(content.comment != nil && self.commentAsBody){
        body = content.comment;
    }
    
    if(subject == nil || [subject isEqualToString:@""]){
        subject = @"tottepost photo";
    }
    [mailComposeViewController setSubject:subject];
    [mailComposeViewController setMessageBody:body isHTML:NO];
    
    
	NSDateFormatter* dateFormat = [[NSDateFormatter alloc] init];
	[dateFormat setDateFormat:@"M/d/y h:m:s"];
    
    NSDateFormatter *df = [[NSDateFormatter alloc] init];
    df.dateFormat  = @"yyyyMMddHHmmssSSSS";
    NSString *filename = nil;
    NSString *mimeType = nil;
    if(content.isPhoto){
        filename = [NSString stringWithFormat:@"%@.jpg", [df stringFromDate:content.timestamp]];
        mimeType = @"image/jpeg";
    }else{
        filename = [NSString stringWithFormat:@"%@.mp4", [df stringFromDate:content.timestamp]];
        mimeType = @"video/mp4";
    }
    
    [mailComposeViewController addAttachmentData:content.data mimeType:mimeType fileName:filename];
    if(self.confirm == NO){
        [mailComposeViewController view];
    }else{     
        dispatch_async(dispatch_get_main_queue(),^{
            [self presentModalViewController:mailComposeViewController];
        });
    }
    return mailComposeViewController;
}

/*!
 * on composed
 */
- (void) mailComposeController:(MFMailComposeViewController*)controller bodyFinishedLoadingWithResult:(NSInteger)result error:(NSError*)error
{
    if(self.confirm == NO){
        @try
        {
            id button = nil;
            for (UIView *s1 in [controller.view subviews]) {
                if([NSStringFromClass([s1 class]) isEqualToString:@"UINavigationBar"]){
                    for (UIView *s2 in [s1 subviews]) {
                        if([NSStringFromClass([s2 class]) isEqualToString:@"UINavigationButton"] && s2.frame.origin.x > 200){
                            button = s2;
                        }
                    }
                }
            }

            if(button == nil){
                return;
            }
            [button sendActionsForControlEvents:UIControlEventTouchUpInside];
            [self checkForSizeConfirmWindow];
            
        }
        @catch (NSException *e) {}
    }
}

/*!
 * select size confirm button
 */
- (void) checkForSizeConfirmWindow{
    UIActionSheet *actionsheet = nil;
    NSMutableArray *buttons = [[NSMutableArray alloc] init];
    for(UIView *s1 in [UIApplication sharedApplication].keyWindow.subviews){
        for(UIView *s2 in s1.subviews){
            if([NSStringFromClass([s2 class]) isEqualToString:@"UIActionSheet"]){
                actionsheet = (UIActionSheet *)s2;
                for(UIView *s3 in s2.subviews){
                    if([NSStringFromClass([s3 class]) isEqualToString:@"UIAlertButton"]){
                        [buttons addObject:(UIButton *)s3];
                    }
                }
            }
        }
    }
    if(actionsheet && buttons.count > 2){
        [[buttons objectAtIndex:1] sendActionsForControlEvents:UIControlEventTouchUpInside];
    }
}


/*!
 * did finish
 */
- (void)mailComposeController:(MFMailComposeViewController *)controller didFinishWithResult:(MFMailComposeResult)result error:(NSError *)error{
    [self dismissModalViewController];
    if(error != nil){
        [self completeSubmitContentWithRequest:controller andError:error];
    }else{
        [self completeSubmitContentWithRequest:controller];
    }
}

/*!
 * get key for commentAsSubject
 */
- (NSString *)commentAsSubjectKey{
    return [NSString stringWithFormat:MP_COMMENT_AS_SUBJECT_KEY, self.account.accountHash];
}

/*!
 * get key for commentAsBody
 */
- (NSString *)commentAsBodyKey{
    return [NSString stringWithFormat:MP_COMMENT_AS_BODY_KEY, self.account.accountHash];
}

/*!
 * get key for confirm
 */
- (NSString *)confirmKey{
    return [NSString stringWithFormat:MP_CONFIRM_KEY, self.account.accountHash];
}

/*!
 * get key for defaultSubject
 */
- (NSString *)defaultSubjectKey{
    return [NSString stringWithFormat:MP_DEFAULT_SUBJECT_KEY, self.account.accountHash];
}

/*!
 * get key for defaultBody
 */
- (NSString *)defaultBodyKey{
    return [NSString stringWithFormat:MP_DEFAULT_BODY_KEY, self.account.accountHash];
}

/*!
 * get key for sendTo
 */
- (NSString *)sendToKey{
    return [NSString stringWithFormat:MP_SENDTO_KEY, self.account.accountHash];
}
@end

//-----------------------------------------------------------------------------
//Public Implementations
//-----------------------------------------------------------------------------
#pragma mark - public PhotoSubmitter Protocol implementations
@implementation MailPhotoSubmitter
@synthesize commentAsBody;
@synthesize commentAsSubject;
@synthesize confirm;
@synthesize defaultBody;
@synthesize defaultSubject;
@synthesize sendTo;

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

#pragma mark - properties
/*!
 * get commentAsBody
 */
- (BOOL)commentAsBody{
    return [[self settingForKey:self.commentAsBodyKey] boolValue];
}

/*!
 * set commentAsBody
 */
- (void)setCommentAsBody:(BOOL)inCommentAsBody{
    BOOL cs = self.commentAsSubject;
    if(cs){
        cs = !inCommentAsBody;
    }
    [self setSetting:[NSNumber numberWithBool:cs] forKey:self.commentAsSubjectKey];
    [self setSetting:[NSNumber numberWithBool:inCommentAsBody] forKey:self.commentAsBodyKey];
}

/*!
 * get commentAsSubject
 */
- (BOOL)commentAsSubject{
    return [[self settingForKey:self.commentAsSubjectKey] boolValue];
}

/*!
 * set commentASSubject
 */
- (void)setCommentAsSubject:(BOOL)inCommentAsSubject{
    BOOL cb = self.commentAsBody;
    if(cb){
        cb = !inCommentAsSubject;
    }
    [self setSetting:[NSNumber numberWithBool:cb] forKey:self.commentAsBodyKey];
    [self setSetting:[NSNumber numberWithBool:inCommentAsSubject] forKey:self.commentAsSubjectKey];
}

/*!
 * get confirm
 */
- (BOOL)confirm{
    return [[self settingForKey:self.confirmKey] boolValue];
}

/*!
 * set confirm
 */
- (void)setConfirm:(BOOL)inConfirm{
    [self setSetting:[NSNumber numberWithBool:inConfirm] forKey:self.confirmKey];
}

/*!
 * get defaultSubject
 */
- (NSString *)defaultSubject{
    return [self settingForKey:self.defaultSubjectKey];
}

/*!
 * set defaultSubject
 */
- (void)setDefaultSubject:(NSString *)inDefaultSubject{
    [self setSetting:inDefaultSubject forKey:self.defaultSubjectKey];
}

/*!
 * get defaultBody
 */
- (NSString *)defaultBody{
    return [self settingForKey:self.defaultBodyKey];
}

/*!
 * set defaultSubject
 */
- (void)setDefaultBody:(NSString *)inDefaultBody{
    [self setSetting:inDefaultBody forKey:self.defaultBodyKey];
}

/*!
 * get sendTo
 */
- (NSString *)sendTo{
    return [self settingForKey:self.sendToKey];
}

/*!
 * set defaultSubject
 */
- (void)setSendTo:(NSString *)inSendTo{
    [self setSetting:inSendTo forKey:self.sendToKey];
}

/*!
 * is send to is valid
 */
- (BOOL)validSendTo{
    return [self.sendTo isMatchedByRegex:@"^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\\.[a-zA-Z]{2,6}$"];
}

#pragma mark - authorization
/*!
 * login to mail
 */
-(void)onLogin{
    if([MFMailComposeViewController canSendMail] == NO){
        UIAlertView *alert =
        [[UIAlertView alloc] initWithTitle:
         [PSLang localized:@"MailPhotoSubmitter_Alert_MailRequired_Title"] 
                                   message:
         [PSLang localized:@"MailPhotoSubmitter_Alert_MailRequired_Message"] 
                                  delegate:self 
                         cancelButtonTitle:
         [PSLang localized:@"MailPhotoSubmitter_Alert_MailRequired_Button_Title"]
                         otherButtonTitles:nil];
        [alert show];
        [self completeLoginFailed];
        return;
    }
    if(self.validSendTo == NO){
        [self presentAuthenticationView:self.settingView];
    }
    [self enable];
    [self completeLogin];
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
 * logoff from mail
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

/*!
 * multiple account supported
 */
- (BOOL)isMultipleAccountSupported{
    return YES;
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
    return [self submitContent:video andOperationDelegate:delegate];
}

/*!
 * cancel content upload
 */
- (id)onCancelContentSubmit:(PhotoSubmitterContentEntity *)content{
    MFMailComposeViewController *controller = (MFMailComposeViewController *)[self requestForPhoto:content.contentHash];
    [self dismissModalViewController];
    return controller;
}

/*!
 * is video supported
 */
- (BOOL)isVideoSupported{
    return YES;
}

#pragma mark - username
/*!
 * get username
 */
- (NSString *)username{ 
    return self.sendTo;
}

/*!
 * update username
 */
- (void)updateUsernameWithDelegate:(id<PhotoSubmitterDataDelegate>)delegate{
    self.dataDelegate = delegate;
    [self.dataDelegate photoSubmitter:self didUsernameUpdated:self.username];
}

#pragma mark - other properties
/*!
 * get setting view
 */
- (PhotoSubmitterServiceSettingTableViewController *)settingView{
    if(settingView_ == nil){
        settingView_ = [[MailPhotoSubmitterSettingTableViewController alloc] initWithAccount:self.account];
    }
    return settingView_;
}
@end
