//
//  SimplePhotoSubmitterSettingTableViewController.m
//  tottepost
//
//  Created by Kentaro ISHITOYA on 12/02/13.
//  Copyright (c) 2012 cocotomo All rights reserved.
//

#if ! __has_feature(objc_arc)
#error This file must be compiled with ARC. Use -fobjc-arc flag (or convert project to ARC).
#endif

#import "SimplePhotoSubmitterSettingTableViewController.h"
#import "PhotoSubmitterServiceSettingTableViewController.h"
#import "MAConfirmButton.h"
#import "PSLang.h"
#import "PhotoSubmitterAccountManager.h"

//-----------------------------------------------------------------------------
//Private Implementations
//-----------------------------------------------------------------------------
@interface SimplePhotoSubmitterSettingTableViewController(PrivateImplementation)
- (void) setupInitialState;
- (void) didLogoutButtonTapped:(id)sender;
- (void) requestForAddAccount:(PhotoSubmitterAccount *)account;
- (void) requestForDeleteAccount:(PhotoSubmitterAccount *)account;
@end

@implementation SimplePhotoSubmitterSettingTableViewController(PrivateImplementation)
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
    MAConfirmButton *button = (MAConfirmButton *)sender;
    [button cancel];
}

/*!
 * call delegate after delay
 */
- (void)requestForAddAccount:(PhotoSubmitterAccount *)account{
    [self.settingDelegate didRequestForAddAccount:account];
}
/*!
 * call delegate after delay
 */
- (void)requestForDeleteAccount:(PhotoSubmitterAccount *)account{
    [self.settingDelegate didRequestForDeleteAccount:account];
}
@end

//-----------------------------------------------------------------------------
//Public Implementations
//-----------------------------------------------------------------------------
@implementation SimplePhotoSubmitterSettingTableViewController

#pragma mark -
#pragma mark tableview methods
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
    switch (section) {
        case SV_SECTION_ACCOUNT: 
            if(self.submitter.isMultipleAccountSupported){
                int count = [[PhotoSubmitterAccountManager sharedManager] countAccountForType:self.submitter.type];
                if(count > 1){
                    return 4;
                }else{
                    return 3;
                }
            }
            return 2;
    }
    return 0;
}

/*!
 * title for section
 */
- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section{
    switch (section) {
        case SV_SECTION_ACCOUNT: return [self.submitter.name stringByAppendingString:[PSLang localized:@"Detail_Section_Account"]] ; break;
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
        if(indexPath.row == SV_ROW_ACCOUNT_NAME){
            cell.textLabel.text = [PSLang localized:@"Detail_Row_AccountName"];
            UILabel *label = [[UILabel alloc] init];
            label.text = self.submitter.username;
            label.font = [UIFont systemFontOfSize:15.0];
            [label sizeToFit];
            label.backgroundColor = [UIColor clearColor];
            cell.accessoryView = label;
        }else if(indexPath.row == SV_ROW_ACCOUNT_LOGOUT){
            cell.textLabel.text = [PSLang localized:@"Detail_Row_Logout"];
            MAConfirmButton *button = [MAConfirmButton buttonWithTitle:[PSLang localized:@"Detail_Row_LogoutButtonTitle"] confirm:[PSLang localized:@"Detail_Row_LogoutButtonConfirm"]];
            [button setTintColor:[UIColor colorWithRed:0.694 green:0.184 blue:0.196 alpha:1]];
            [button addTarget:self action:@selector(didLogoutButtonTapped:) forControlEvents:UIControlEventTouchUpInside];
            cell.accessoryView = button;
        }else if(indexPath.row == SV_ROW_ACCOUNT_ADD){
            cell.textLabel.text = [PSLang localized:@"Detail_Row_AddAccount"];
            cell.accessoryType = UITableViewCellAccessoryDetailDisclosureButton;
        }else if(indexPath.row == SV_ROW_ACCOUNT_DELETE){
            cell.textLabel.text = [PSLang localized:@"Detail_Row_DeleteAccount"];
            cell.accessoryType = UITableViewCellAccessoryDetailDisclosureButton;
        }
        
    }
    return cell;
}


/*!
 * on row selected
 */
- (void) tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath{
    [tableView deselectRowAtIndexPath:indexPath animated: YES];
    if(self.submitter.isMultipleAccountSupported){
        switch(indexPath.row){
            case SV_ROW_ACCOUNT_ADD:{
                PhotoSubmitterAccount *account = [[PhotoSubmitterAccountManager sharedManager] createAccountForType:self.submitter.type];
                [self.navigationController popViewControllerAnimated:YES];
                [self performSelector:@selector(requestForAddAccount:) withObject:account afterDelay:1];
                break;
            }
            case SV_ROW_ACCOUNT_DELETE:{
                [self.navigationController popViewControllerAnimated:YES];
                [self performSelector:@selector(requestForDeleteAccount:) withObject:self.account afterDelay:1];
                break;                
            }
        }
    }
}

#pragma mark -
#pragma mark UIView delegate
/*!
 * albums
 */
- (void)viewDidAppear:(BOOL)animated{
    [super viewDidAppear:animated];
    [self.submitter updateUsernameWithDelegate:self];
}

#pragma mark -
#pragma mark PhotoSubmitterAlbumDelegate methods
/*!
 * album
 */
- (void)photoSubmitter:(id<PhotoSubmitterProtocol>)photoSubmitter didAlbumUpdated:(NSMutableArray *)albums{
    //Do nothing
}

/*!
 * username
 */
- (void) photoSubmitter:(id<PhotoSubmitterProtocol>)photoSubmitter didUsernameUpdated:(NSString *)username{
    [self.tableView reloadData];
}
@end
