//
//  ENGTwitterPhotoSubmitter.m
//  PhotoSubmitter for Twitter
//
//  Created by ISHITOYA Kentaro on 11/12/17.
//

#import "ENGTwitterPhotoSubmitter.h"
#import "ENGTwitterPhotoSubmitterSettingTableViewController.h"
#import "ENGPhotoSubmitterLocalization.h"

#define PS_TWITTER_USERNAME @"PSTwitter%@Username"

//-----------------------------------------------------------------------------
//Private Implementations
//-----------------------------------------------------------------------------
@interface ENGTwitterPhotoSubmitter(PrivateImplementation)
- (void) setupInitialState;
- (ACAccount *)selectedAccount;
- (id) submitContent:(ENGPhotoSubmitterContentEntity *)content andOperationDelegate:(id<ENGPhotoSubmitterPhotoOperationDelegate>)delegate;
- (NSString *) usernameKey;
@end

#pragma mark - private implementations
@implementation ENGTwitterPhotoSubmitter(PrivateImplementation)
/*!
 * initializer
 */
-(void)setupInitialState{
    [self setSubmitterIsConcurrent:YES 
                      isSequencial:YES 
                     usesOperation:YES 
                   requiresNetwork:YES 
                  isAlbumSupported:NO];
    
    accountStore_ = [[ACAccountStore alloc] init];
    defaultComment_ = ENGPhotoSubmitterLocalization(@"Twitter_Default_Comment");
}

/*!
 * get selected account
 */
- (ACAccount *)selectedAccount{
    NSArray *accountsArray = self.accounts;
    for(ACAccount *account in accountsArray){
        if([account.username isEqualToString:self.selectedAccountUsername]){
            return account;
        }
    }
    if(accountsArray.count != 0){
        ACAccount *account = [accountsArray objectAtIndex:0];
        self.selectedAccountUsername = account.username;
        return account;
    }
    return nil;
}

/*!
 * get username key
 */
- (NSString *)usernameKey{
    return [NSString stringWithFormat:PS_TWITTER_USERNAME, self.account.accountHash];
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
- (id)submitContent:(ENGPhotoSubmitterContentEntity *)content andOperationDelegate:(id<ENGPhotoSubmitterPhotoOperationDelegate>)delegate{
    if(content.comment == nil){
        content.comment = defaultComment_;
    }
    
    ACAccount *twitterAccount = [self selectedAccount];
    if (twitterAccount == nil) {
        return nil;
    }
    
    NSURL *url = 
    [NSURL URLWithString:@"https://upload.twitter.com/1/statuses/update_with_media.json"];
    TWRequest *request = [[TWRequest alloc] initWithURL:url parameters:nil
                                          requestMethod:TWRequestMethodPOST];
    
    [request setAccount:twitterAccount];
    [request addMultiPartData:content.data 
                     withName:@"media[]" type:@"multipart/form-data"];
    [request addMultiPartData:[content.comment dataUsingEncoding:NSUTF8StringEncoding] 
                     withName:@"status" type:@"multipart/form-data"];
    if(content.location){
        NSLog(@"%@", [NSString stringWithFormat:@"%g", content.location.coordinate.longitude]);
        [request addMultiPartData:[[NSString stringWithFormat:@"%g", content.location.coordinate.latitude]  dataUsingEncoding:NSUTF8StringEncoding] 
                         withName:@"lat" type:@"multipart/form-data"];
        [request addMultiPartData:[[NSString stringWithFormat:@"%g", content.location.coordinate.longitude] dataUsingEncoding:NSUTF8StringEncoding] 
                         withName:@"long" type:@"multipart/form-data"];
        
    }
    
    NSURLConnection *connection = 
    [[NSURLConnection alloc] initWithRequest:request.signedURLRequest delegate:self startImmediately:NO];
    
    if(connection == nil){
        [self cancelContentSubmit:content];
        return nil;
    }
    
    if(connection != nil){
        [connection start];
    }    
    return connection;
}
@end

//-----------------------------------------------------------------------------
//Public Implementations
//-----------------------------------------------------------------------------
#pragma mark - public PhotoSubmitter Protocol implementations
@implementation ENGTwitterPhotoSubmitter
@synthesize defaultComment = defaultComment_;

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
 * login to twitter
 */
-(void)onLogin{
    ACAccountType *accountType = [accountStore_ accountTypeWithAccountTypeIdentifier:ACAccountTypeIdentifierTwitter];
    dispatch_async(dispatch_get_main_queue(), ^{
        [accountStore_ requestAccessToAccountsWithType:accountType withCompletionHandler:^(BOOL granted, NSError *error) {
            if(granted) {
                ACAccount *account = self.selectedAccount;
                dispatch_async(dispatch_get_main_queue(), ^{
                    if (account != nil){
                        [self enable];
                    }else if([[[UIDevice currentDevice] systemVersion] floatValue] < 5.09){
                        UIAlertView* alert = 
                        [[UIAlertView alloc] initWithTitle:ENGPhotoSubmitterLocalization(@"Twitter_Ask_For_Configure_Title")
                                                   message:ENGPhotoSubmitterLocalization(@"Twitter_Ask_For_Configure")
                                                  delegate:self
                                         cancelButtonTitle:ENGPhotoSubmitterLocalization(@"Twitter_Ask_For_Configure_Cancel")
                                         otherButtonTitles:ENGPhotoSubmitterLocalization(@"Twitter_Ask_For_Configure_OK"), nil];
                        [alert show];
                        [self.authDelegate photoSubmitter:self didLogout:self.account];
                    }else{
                        UIAlertView* alert = 
                        [[UIAlertView alloc] initWithTitle:ENGPhotoSubmitterLocalization(@"Twitter_Account_Error_Title")
                                                   message:ENGPhotoSubmitterLocalization(@"Twitter_Account_Error")
                                                  delegate:self
                                         cancelButtonTitle:ENGPhotoSubmitterLocalization(@"Twitter_Account_Error_OK")
                                         otherButtonTitles:nil, nil];
                        [alert show];
                        [self.authDelegate photoSubmitter:self didLogout:self.account];
                    }
                });
            }else{
                [self.authDelegate photoSubmitter:self didLogout:self.account];
            }
            [self.authDelegate photoSubmitter:self didAuthorizationFinished:self.account];
        }];
    });
}

/*!
 * alert delegate
 */
- (void)alertView:(UIAlertView *)alertView didDismissWithButtonIndex:(NSInteger)buttonIndex{
    if(buttonIndex == 1){
        [[UIApplication sharedApplication] openURL:[NSURL URLWithString:@"prefs:root=TWITTER"]];
    }
}

/*!
 * logoff from twitter
 */
- (void)onLogout{
}

/*!
 * get account list
 */
- (NSArray *)accounts{
    ACAccountType *accountType = [accountStore_ accountTypeWithAccountTypeIdentifier:ACAccountTypeIdentifierTwitter];
    return [accountStore_ accountsWithAccountType:accountType];    
}

/*!
 * set selected username
 */
- (NSString *)selectedAccountUsername{
    return [self settingForKey:self.usernameKey];
}

/*!
 * set selected username
 */
- (void)setSelectedAccountUsername:(NSString *)selectedAccountUsername{
    return [self setSetting:selectedAccountUsername forKey:self.usernameKey];
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
- (id)onSubmitPhoto:(ENGPhotoSubmitterImageEntity *)photo andOperationDelegate:(id<ENGPhotoSubmitterPhotoOperationDelegate>)delegate{
    return [self submitContent:photo andOperationDelegate:delegate];
}

/*!
 * submit video
 */
- (id)onSubmitVideo:(ENGPhotoSubmitterVideoEntity *)video andOperationDelegate:(id<ENGPhotoSubmitterPhotoOperationDelegate>)delegate{
    //return [self submitContent:video andOperationDelegate:delegate];
    return nil;
}

/*!
 * cancel content upload
 */
- (id)onCancelContentSubmit:(ENGPhotoSubmitterContentEntity *)content{
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

/*!
 * is multiple account supported
 */
- (BOOL)isMultipleAccountSupported{
    return YES;
}

#pragma mark - albums
#pragma mark - username
/*!
 * get username
 */
- (NSString *)username{ 
    return self.selectedAccount.username;
}

/*!
 * update username
 */
- (void)updateUsernameWithDelegate:(id<ENGPhotoSubmitterDataDelegate>)delegate{
    self.dataDelegate = delegate;
    [self.dataDelegate photoSubmitter:self didUsernameUpdated:self.username];
}

#pragma mark - other properties
/*!
 * get setting view
 */
- (ENGPhotoSubmitterServiceSettingTableViewController *)settingView{
    if(settingView_ == nil){
        settingView_ = [[ENGTwitterPhotoSubmitterSettingTableViewController alloc] initWithAccount:self.account];
    }
    return settingView_;
}

/*!
 * maximum comment length
 */
- (NSInteger)maximumLengthOfComment{
    return 120;
}
@end
