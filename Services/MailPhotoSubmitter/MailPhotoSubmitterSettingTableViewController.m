//
//  MailPhotoSubmitterSettingTableViewController.m
//  tottepost
//
//  Created by Kentaro ISHITOYA on 12/04/21.
//  Copyright (c) 2012 cocotomo All rights reserved.
//

#if ! __has_feature(objc_arc)
#error This file must be compiled with ARC. Use -fobjc-arc flag (or convert project to ARC).
#endif

#import "MailPhotoSubmitterSettingTableViewController.h"
#import "MailPhotoSubmitter.h"
#import "RegexKitLite.h"
#import "PSLang.h"

#define TSV_SECTION_COUNT 2
#define TSV_SECTION_MAIL 1
#define TSV_SECTION_MAIL_COUNT 6
#define TSV_ROW_MAIL_TO 0
#define TSV_ROW_MAIL_DEFAULT_SUBJECT 1
#define TSV_ROW_MAIL_DEFAULT_BODY 2
#define TSV_ROW_MAIL_COMMENT_AS_SUBJECT 3
#define TSV_ROW_MAIL_COMMENT_AS_BODY 4
#define TSV_ROW_MAIL_CONFIRM_MAIL 5

//-----------------------------------------------------------------------------
//Private Implementations
//-----------------------------------------------------------------------------
@interface MailPhotoSubmitterSettingTableViewController(PrivateImplementation)
- (void) setupInitialState;
- (void) didLogoutButtonTapped:(id)sender;
- (MailPhotoSubmitter *)mailSubmitter;
- (UITextField *) createTextField;
@end

@implementation MailPhotoSubmitterSettingTableViewController(PrivateImplementation)
/*!
 * initialize
 */
-(void)setupInitialState{
}

/*!
 * did logout button tapped
 */
- (void)didLogoutButtonTapped:(id)sender{
    [self.submitter logout];
    [self.navigationController popViewControllerAnimated:YES];
}

/*!
 * get submitter as mail submitter
 */
- (MailPhotoSubmitter *)mailSubmitter{
    return (MailPhotoSubmitter *)self.submitter;
}

/*!
 * create textfield
 */
- (UITextField *)createTextField{
    UITextField *textField;
    textField = [[UITextField alloc] init];
    textField.borderStyle = UITextBorderStyleNone;
    textField.clearButtonMode = UITextFieldViewModeWhileEditing;
    textField.spellCheckingType = UITextSpellCheckingTypeNo;
    textField.autocapitalizationType = UITextAutocapitalizationTypeNone;
    textField.autocorrectionType = UITextAutocorrectionTypeNo;
    textField.returnKeyType = UIReturnKeyDone;
    textField.textAlignment = UITextAlignmentLeft;
    textField.delegate = self;
    return textField;
}

/*!
 * UITextFieldDelegate
 */
-(BOOL)textFieldShouldReturn:(UITextField*)textField{
    [textField resignFirstResponder];
    return YES;
}

/*! 
 * did end editing
 */
- (void)textFieldDidEndEditing:(UITextField *)textField{
    if(textField == toTextField_){
        self.mailSubmitter.sendTo = toTextField_.text;
        NSLog(@"%@", toTextField_.text);
    }else if(textField == defaultSubjectTextField_){
        self.mailSubmitter.defaultSubject = defaultSubjectTextField_.text;
    }else if(textField == defaultBodyTextField_){
        self.mailSubmitter.defaultBody = defaultBodyTextField_.text;
    }
}
@end

//-----------------------------------------------------------------------------
//Public Implementations
//-----------------------------------------------------------------------------
@implementation MailPhotoSubmitterSettingTableViewController

#pragma mark -
#pragma mark tableview methods
/*! 
 * get section number
 */
-(NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return TSV_SECTION_COUNT;
}

/*!
 * get row number
 */
- (NSInteger)tableView:(UITableView *)table numberOfRowsInSection:(NSInteger)section
{
    switch (section) {
        case TSV_SECTION_MAIL: return TSV_SECTION_MAIL_COUNT;
    }
    return [super tableView:table numberOfRowsInSection:section];
}

/*!
 * title for section
 */
- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section{
    switch (section) {
        case SV_SECTION_ACCOUNT: return [self.submitter.name stringByAppendingString:[PSLang localized:@"Detail_Section_Account"]] ; break;
        case TSV_SECTION_MAIL: return [self.submitter.name stringByAppendingString:[PSLang localized:@"MailPhotoSubmitter_Section_Mail"]] ; break;
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
    if(indexPath.section == SV_SECTION_ACCOUNT){
        cell = [super tableView:tableView cellForRowAtIndexPath:indexPath];
    }else if(indexPath.section == TSV_SECTION_MAIL){
        switch (indexPath.row) {
            case TSV_ROW_MAIL_TO:{
                if(toTextField_ == nil){
                    toTextField_ = [self createTextField];
                    toTextField_.placeholder = [PSLang localized:@"MailPhotoSubmitter_To_Placeholder"];
                    toTextField_.frame = CGRectInset(cell.frame, 20, 12);
                    toTextField_.text = self.mailSubmitter.sendTo;
                }
                [cell.contentView addSubview:toTextField_];
                break;
            }
            case TSV_ROW_MAIL_DEFAULT_SUBJECT:{
                if(defaultSubjectTextField_ == nil){
                    defaultSubjectTextField_ = [self createTextField];
                    defaultSubjectTextField_.placeholder = [PSLang localized:@"MailPhotoSubmitter_DefaultSubject_Placeholder"];
                    defaultSubjectTextField_.frame = CGRectInset(cell.frame, 20, 12);
                    defaultSubjectTextField_.text = self.mailSubmitter.defaultSubject;                
                }
                [cell.contentView addSubview:defaultSubjectTextField_];
                    
                break;
            }
            case TSV_ROW_MAIL_DEFAULT_BODY:{
                if(defaultBodyTextField_ == nil){
                    defaultBodyTextField_ = [self createTextField];
                    defaultBodyTextField_.placeholder = [PSLang localized:@"MailPhotoSubmitter_DefaultBody_Placeholder"];
                    defaultBodyTextField_.frame = CGRectInset(cell.frame, 20, 12);
                    defaultBodyTextField_.text = self.mailSubmitter.defaultBody;
                }
                [cell.contentView addSubview:defaultBodyTextField_];
                break;
            }
            case TSV_ROW_MAIL_COMMENT_AS_BODY:{
                if(self.mailSubmitter.commentAsBody){
                    cell.accessoryType = UITableViewCellAccessoryCheckmark;
                }else{
                    cell.accessoryType = UITableViewCellAccessoryNone;
                }
                cell.textLabel.text = [PSLang localized:@"MailPhotoSubmitter_CommentAsBody_Title"];
                break;
            }
            case TSV_ROW_MAIL_COMMENT_AS_SUBJECT:{
                if(self.mailSubmitter.commentAsSubject){
                    cell.accessoryType = UITableViewCellAccessoryCheckmark;
                }else{
                    cell.accessoryType = UITableViewCellAccessoryNone;
                }
                cell.textLabel.text = [PSLang localized:@"MailPhotoSubmitter_CommentAsSubject_Title"];
                break;
            }
            case TSV_ROW_MAIL_CONFIRM_MAIL:{
                if(self.mailSubmitter.confirm){
                    cell.accessoryType = UITableViewCellAccessoryCheckmark;
                }else{
                    cell.accessoryType = UITableViewCellAccessoryNone;
                }
                cell.textLabel.text = [PSLang localized:@"MailPhotoSubmitter_ConfirmMail_Title"];
                break;
            }
        }
    }
    return cell;
}

/*!
 * on row selected
 */
- (void) tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath{
    if(indexPath.section == TSV_SECTION_MAIL){
        switch (indexPath.row) {
            case TSV_ROW_MAIL_TO:{
                break;
            }
            case TSV_ROW_MAIL_DEFAULT_SUBJECT:{
                break;
            }
            case TSV_ROW_MAIL_DEFAULT_BODY:{
                break;
            }
            case TSV_ROW_MAIL_COMMENT_AS_BODY:{
                self.mailSubmitter.commentAsBody = !self.mailSubmitter.commentAsBody;                
                break;
            }
            case TSV_ROW_MAIL_COMMENT_AS_SUBJECT:{
                self.mailSubmitter.commentAsSubject = !self.mailSubmitter.commentAsSubject;
                break;
            }
            case TSV_ROW_MAIL_CONFIRM_MAIL:{
                self.mailSubmitter.confirm = !self.mailSubmitter.confirm;
                break;
            }
        } 
        [self.tableView reloadData];
        [tableView deselectRowAtIndexPath:indexPath animated: YES];
    }else{
        [super tableView:tableView didSelectRowAtIndexPath:indexPath];
    }
}

#pragma mark - UIView delegate
/*!
 * view did appear
 */
- (void)viewDidAppear:(BOOL)animated{
    [super viewDidAppear:animated];
}

/*!
 * view did dissmiss
 */
- (void)viewWillDisappear:(BOOL)animated{
    [super viewWillDisappear:animated];
    if(attemptToDeleteAccount_){
        return;
    }
    if([toTextField_.text isMatchedByRegex:@"^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\\.[a-zA-Z]{2,6}$"] == NO){
        NSString *message = 
        [NSString stringWithFormat:[PSLang localized:@"MailPhotoSubmitter_Alert_InvalidAddress_Message"], toTextField_.text];
        if(toTextField_.text == nil || 
           [toTextField_.text isMatchedByRegex:@"(?m-s:^\\s*$)"]){
            message = [PSLang localized:@"MailPhotoSubmitter_Alert_EmptyAddress_Message"];
        }
        UIAlertView *alert =
        [[UIAlertView alloc] initWithTitle:
         [PSLang localized:@"MailPhotoSubmitter_Alert_InvalidAddress_Title"] 
                                   message:message
                                  delegate:self 
                         cancelButtonTitle:
         [PSLang localized:@"MailPhotoSubmitter_Alert_InvalidAddress_Button_Title"]
                         otherButtonTitles:nil];
        if(attemptToAddAccount_ == NO){
            [alert show];
        }
        [self.submitter disable];
        return;
    }
    self.mailSubmitter.sendTo = toTextField_.text;
    self.mailSubmitter.defaultSubject = defaultSubjectTextField_.text;
    self.mailSubmitter.defaultBody = defaultBodyTextField_.text;
}
@end
