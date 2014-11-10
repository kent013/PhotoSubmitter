//
//  ENGSimplePhotoSubmitterSettingTableViewController.m
//
//  Created by Kentaro ISHITOYA on 12/02/13.
//

#import "MAConfirmButton.h"
#import "ENGSimplePhotoSubmitterSettingTableViewController.h"
#import "ENGPhotoSubmitterServiceSettingTableViewController.h"
#import "ENGPhotoSubmitterAccountManager.h"
#import "ENGPhotoSubmitterLocalization.h"

//-----------------------------------------------------------------------------
//Private Implementations
//-----------------------------------------------------------------------------
@interface ENGSimplePhotoSubmitterSettingTableViewController(PrivateImplementation)
- (void) setupInitialState;
- (void) didLogoutButtonTapped:(id)sender;
- (void) requestForAddAccount:(ENGPhotoSubmitterAccount *)account;
- (void) requestForDeleteAccount:(ENGPhotoSubmitterAccount *)account;
@end

@implementation ENGSimplePhotoSubmitterSettingTableViewController(PrivateImplementation)
/*!
 * initialize
 */
-(void)setupInitialState{
}

/*!
 * did logout button tapped
 */
- (void)didLogoutButtonTapped:(id)sender{
    if([[ENGPhotoSubmitterAccountManager sharedManager] countAccountForType:self.submitter.type] > 1){
        attemptToDeleteAccount_ = YES;
        [self performSelector:@selector(requestForDeleteAccount:) withObject:self.account afterDelay:1.5];
    }else{
        MAConfirmButton *button = (MAConfirmButton *)sender;
        #pragma clang diagnostic push
        #pragma GCC diagnostic ignored "-Wundeclared-selector"
        [button performSelector:@selector(cencel)];
        #pragma clang diagnostic pop
        [self.submitter logout];
    }
    [self.navigationController popViewControllerAnimated:YES];
}

/*!
 * call delegate after delay
 */
- (void)requestForAddAccount:(ENGPhotoSubmitterAccount *)account{
    [self.settingDelegate didRequestForAddAccount:account];
}
/*!
 * call delegate after delay
 */
- (void)requestForDeleteAccount:(ENGPhotoSubmitterAccount *)account{
    [self.settingDelegate didRequestForDeleteAccount:account];
}
@end

//-----------------------------------------------------------------------------
//Public Implementations
//-----------------------------------------------------------------------------
@implementation ENGSimplePhotoSubmitterSettingTableViewController
@synthesize attemptToAddAccount = attemptToAddAccount_;
@synthesize attemptToDeleteAccount = attemptToDeleteAccount_;

#pragma mark -
#pragma mark tableview methods
/*! 
 * get section number
 */
-(NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    if(self.tableViewDelegate){
        NSInteger count = [self.tableViewDelegate settingViewController:self numberOfSectionsInTableView:tableView];
        if(count >= 0){
            return count;
        }
    }
    return 2;
}

/*!
 * get row number
 */
- (NSInteger)tableView:(UITableView *)table numberOfRowsInSection:(NSInteger)section
{
    if(self.tableViewDelegate){
        NSInteger count = [self.tableViewDelegate settingViewController:self tableView:table numberOfRowsInSection:section];
        if(count >= 0){
            return count;
        }
    }
    switch (section) {
        case SV_SECTION_ACCOUNT: 
            if(self.submitter.isMultipleAccountSupported){
                return 3;
            }
            return 2;
    }
    return 0;
}

/*!
 * title for section
 */
- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section{
    NSString *title = [self.tableViewDelegate settingViewController:self tableView:tableView titleForHeaderInSection:section];
    if(title != nil){
        return title;
    }
    switch (section) {
        case SV_SECTION_ACCOUNT: return [NSString stringWithFormat:@"%@ %@", self.submitter.displayName, ENGPhotoSubmitterLocalization(@"Detail_Section_Account")]; break;
    }
    return nil;
}

/*!
 * footer for section
 */
- (NSString *)tableView:(UITableView *)tableView titleForFooterInSection:(NSInteger)section{
    NSString *title = [self.tableViewDelegate settingViewController:self tableView:tableView titleForFooterInSection:section];
    if(title != nil){
        return title;
    }
    return nil;    
}

/*!
 * create cell
 */
-(UITableViewCell *) tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{    
    UITableViewCell *cell = [self.tableViewDelegate settingViewController:self tableView:tableView cellForRowAtIndexPath:indexPath];
    
    if(cell != nil){
        return cell;
    }
    cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleValue1 reuseIdentifier:nil];
    if(indexPath.section == SV_SECTION_ACCOUNT){
        if(indexPath.row == SV_ROW_ACCOUNT_NAME){
            cell.textLabel.text = ENGPhotoSubmitterLocalization(@"Detail_Row_AccountName");
            UILabel *label = [[UILabel alloc] init];
            label.text = self.submitter.username;
            label.font = [UIFont systemFontOfSize:15.0];
            [label sizeToFit];
            label.backgroundColor = [UIColor clearColor];
            cell.accessoryView = label;
        }else if(indexPath.row == SV_ROW_ACCOUNT_LOGOUT){
            cell.textLabel.text = ENGPhotoSubmitterLocalization(@"Detail_Row_Logout");
            MAConfirmButton *button = [MAConfirmButton buttonWithTitle:ENGPhotoSubmitterLocalization(@"Detail_Row_LogoutButtonTitle") confirm:ENGPhotoSubmitterLocalization(@"Detail_Row_LogoutButtonConfirm")];
            [button setTintColor:[UIColor colorWithRed:0.694 green:0.184 blue:0.196 alpha:1]];
            [button addTarget:self action:@selector(didLogoutButtonTapped:) forControlEvents:UIControlEventTouchUpInside];
            cell.accessoryView = button;
        }else if(indexPath.row == SV_ROW_ACCOUNT_ADD){
            cell.textLabel.text = ENGPhotoSubmitterLocalization(@"Detail_Row_AddAccount");
            cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
        }
    }
    return cell;
}


/*!
 * on row selected
 */
- (void) tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath{
    [tableView deselectRowAtIndexPath:indexPath animated: YES];
    BOOL processed = [self.tableViewDelegate settingViewController:self tableView:tableView didSelectRowAtIndexPath:indexPath];
    if(processed){
        return;
    }
    if(self.submitter.isMultipleAccountSupported){
        switch(indexPath.row){
            case SV_ROW_ACCOUNT_ADD:{
                attemptToAddAccount_ = YES;
                ENGPhotoSubmitterAccount *account = [[ENGPhotoSubmitterAccountManager sharedManager] createAccountForType:self.submitter.type];
                [self.navigationController popViewControllerAnimated:YES];
                [self performSelector:@selector(requestForAddAccount:) withObject:account afterDelay:1.5];
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
    attemptToAddAccount_ = NO;
    attemptToDeleteAccount_ = NO;
}

#pragma mark -
#pragma mark ENGPhotoSubmitterAlbumDelegate methods
/*!
 * album
 */
- (void)photoSubmitter:(id<ENGPhotoSubmitterProtocol>)photoSubmitter didAlbumUpdated:(NSMutableArray *)albums{
    //Do nothing
}

/*!
 * username
 */
- (void) photoSubmitter:(id<ENGPhotoSubmitterProtocol>)photoSubmitter didUsernameUpdated:(NSString *)username{
    [self.tableView reloadData];
}
@end
