//
//  PhotoSubmitterAccountView.m
//  tottepost
//
//  Created by Kentaro ISHITOYA on 12/02/18.
//  Copyright (c) 2012 cocotomo. All rights reserved.
//

#if ! __has_feature(objc_arc)
#error This file must be compiled with ARC. Use -fobjc-arc flag (or convert project to ARC).
#endif

#import "PhotoSubmitterAccountTableViewController.h"
#import "PSLang.h"
#import "SVProgressHUD.h"

#define ASV_SECTION_USERNAME 0
#define ASV_SECTION_PASSWORD 1

//-----------------------------------------------------------------------------
//Private Implementations
//-----------------------------------------------------------------------------
@interface PhotoSubmitterAccountTableViewController(PrivateImplementation)
- (void) setupInitialState;
- (void) handleDoneButtonTapped:(UIBarButtonItem *)sender;
- (void) login;
@end

@implementation PhotoSubmitterAccountTableViewController(PrivateImplementation)
/*!
 * initialize
 */
-(void)setupInitialState{
    UIBarButtonItem *doneButton = [[UIBarButtonItem alloc ] initWithBarButtonSystemItem:UIBarButtonSystemItemSave target:self action:@selector(handleDoneButtonTapped:)];
    
    [self.navigationItem setTitle:[PSLang localized:@"Account_Navigation_Title"]];
    [self.navigationItem setRightBarButtonItem:doneButton animated:YES];
}

/*!
 * handle barbutton tapped
 */
- (void)handleDoneButtonTapped:(UIBarButtonItem *)sender{
    [self login];
}

/*!
 * login
 */
- (void)login{
    if(usernameTextField_.text == nil || passwordTextField_.text == nil ||
       [usernameTextField_.text isEqualToString:@""] ||
       [passwordTextField_.text isEqualToString:@""]){
        return;
    }
    isDone_ = YES;
    [self.delegate passwordAuthView:self didPresentUserId:usernameTextField_.text password:passwordTextField_.text];
    [SVProgressHUD showWithMaskType:SVProgressHUDMaskTypeBlack];
}

/*!
 * should return
 */
- (BOOL)textFieldShouldReturn:(UITextField *)textField{
    if(textField == passwordTextField_ && usernameTextField_.text.length > 0){
        [self login];
    }
    return YES;
}
@end

//-----------------------------------------------------------------------------
//Public Implementations
//-----------------------------------------------------------------------------
@implementation PhotoSubmitterAccountTableViewController
@synthesize delegate;
/*!
 * initialize with frame
 */
- (id) init{
    self = [super initWithStyle:UITableViewStyleGrouped];
    if(self){
        [self setupInitialState];
    }
    return self;
}

/*!
 * login finished
 */
- (void)didLogin{
    [self.navigationController popViewControllerAnimated:YES];
    [SVProgressHUD dismissWithSuccess:@"Login suceeded"];
}

/*!
 * did not login
 */
- (void)didLoginFailed{
    [SVProgressHUD dismissWithError:@"Login failed"];
}

#pragma mark - tableview methods
/*! 
 * get section number
 */
-(NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 2;
}

/*!
 * get row number
 */
- (NSInteger)tableView:(UITableView *)table numberOfRowsInSection:(NSInteger)section
{
    return 1;
}

/*!
 * title for section
 */
- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section{
    switch (section) {
        case ASV_SECTION_USERNAME: return [PSLang localized:@"Account_Section_Username"];
        case ASV_SECTION_PASSWORD: return [PSLang localized:@"Account_Section_Password"];
    }
    return nil;
}

/*!
 * footer for section
 */
- (NSString *)tableView:(UITableView *)tableView titleForFooterInSection:(NSInteger)section{
    return nil;    
}

/*!
 * create cell
 */
-(UITableViewCell *) tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{    
    UITableViewCell *cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleValue1 reuseIdentifier:nil];
    UITextField *textField = [[UITextField alloc] init];
    textField.frame = CGRectInset(cell.frame, 20, 12);
    textField.borderStyle = UITextBorderStyleNone;
    textField.clearButtonMode = UITextFieldViewModeWhileEditing;
    textField.returnKeyType = UIReturnKeyDone;
    textField.textAlignment = UITextAlignmentLeft;
    textField.delegate = self;
    textField.autocapitalizationType = UITextAutocapitalizationTypeNone;
    textField.autocorrectionType = UITextAutocorrectionTypeNo;
    textField.keyboardType = UIKeyboardTypeAlphabet;
    
    switch (indexPath.section) {
        case ASV_SECTION_USERNAME : 
            textField.placeholder = [PSLang localized:@"Account_Section_Username_Placeholder"];
            usernameTextField_ = textField;
            break;
        case ASV_SECTION_PASSWORD : 
            textField.placeholder = [PSLang localized:@"Account_Section_Password_Placeholder"];
            textField.secureTextEntry = YES;
            passwordTextField_ = textField;
            break;
    }
    [cell.contentView addSubview:textField];
    return cell;
}

/*!
 * on row selected
 */
- (void) tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath{
    switch (indexPath.section) {
        case ASV_SECTION_USERNAME:
            [usernameTextField_ becomeFirstResponder];
            break;
        case ASV_SECTION_PASSWORD:
            [passwordTextField_ becomeFirstResponder];
            break;
    }
    [tableView deselectRowAtIndexPath:indexPath animated: YES];
}

#pragma mark - UIView delegate
/*!
 * auto rotation
 */
- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
    if(interfaceOrientation == UIInterfaceOrientationPortrait ||
       interfaceOrientation == UIInterfaceOrientationPortraitUpsideDown){
        return YES;
    }
    return NO;
}

/*!
 * register first responder
 */
- (void)viewWillAppear:(BOOL)animated {
    [usernameTextField_ becomeFirstResponder];
    isDone_ = NO;
}

/*!
 * remove first responder
 */
- (void)viewWillDisappear:(BOOL)animated {
    if(isDone_ == NO){
        [self.delegate didCancelPasswordAuthView:self];
    }
    [usernameTextField_ resignFirstResponder];
}
@end
