//
//  ENGPhotoSubmitterSettingTableViewController.m
//
//  Created by ISHITOYA Kentaro on 11/12/11.
//

#import "ENGPhotoSubmitterSettingTableViewController.h"
#import "ENGPhotoSubmitterSettingTableViewProtocol.h"
#import "ENGPhotoSubmitterServiceSettingTableViewController.h"
#import "ENGPhotoSubmitterSettings.h"
#import "ENGPhotoSubmitterSwitch.h"
#import "ENGPhotoSubmitterAccountManager.h"
#import "RegexKitLite.h"

//-----------------------------------------------------------------------------
//Private Implementations
//-----------------------------------------------------------------------------
@interface ENGPhotoSubmitterSettingTableViewController(PrivateImplementation)
- (void) setupInitialState;
- (ENGPhotoSubmitterServiceSettingTableViewController *)settingTableViewControllerForAccount:(ENGPhotoSubmitterAccount *)account;
- (void) settingDone:(id)sender;
- (UITableViewCell *) createSocialAppButtonWithTag:(NSInteger)tag;
- (void) didSocialAppSwitchChanged:(id)sender;
- (void) didGeneralSwitchChanged:(id)sender;
- (ENGPhotoSubmitterAccount *) indexToAccount:(NSInteger) index;
- (NSInteger) accountToIndex:(NSString *) hash;
- (UISwitch *)createSwitchWithTag:(NSInteger)tag on:(BOOL)on;
- (void) sortSocialAppCell;
@end

#pragma mark - Private Implementations
@implementation ENGPhotoSubmitterSettingTableViewController(PrivateImplementation)
/*!
 * setup initial state
 */
- (void)setupInitialState{
    self.tableView.delegate = self;
    switches_ = [[NSMutableArray alloc] init];
    settingControllers_ = [[NSMutableDictionary alloc] init];
    cells_ = [[NSMutableDictionary alloc] init];
    
    NSArray *submitters = [ENGPhotoSubmitterManager sharedInstance].submitters;
    for(id<ENGPhotoSubmitterProtocol> submitter in submitters){
        ENGPhotoSubmitterServiceSettingTableViewController *settingView = 
          submitter.settingView;
        if(settingView != nil){
            [settingControllers_ setObject:settingView forKey:submitter.account.accountHash];
            settingView.settingDelegate = self;
            settingView.tableViewDelegate = tableViewDelegate_;
        }
    }
    
    [ENGPhotoSubmitterManager sharedInstance].authenticationDelegate = self;
    
    int i = 0;
    for(id<ENGPhotoSubmitterProtocol> submitter in submitters){
        ENGPhotoSubmitterSwitch *s = [[ENGPhotoSubmitterSwitch alloc] init];
        s.account = submitter.account;
        s.index = i;
        [s addTarget:self action:@selector(didSocialAppSwitchChanged:) forControlEvents:UIControlEventValueChanged];
        [switches_ addObject:s];
        i++;
    }
    [self sortSocialAppCell];
}

/*!
 * get setting table view fo type
 */
- (ENGPhotoSubmitterServiceSettingTableViewController *)settingTableViewControllerForAccount:(ENGPhotoSubmitterAccount *)account{
    return [settingControllers_ objectForKey:account.accountHash];
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
    switch (section) {
        case SV_SECTION_GENERAL: return SV_GENERAL_COUNT;
        case SV_SECTION_ACCOUNTS: return [ENGPhotoSubmitterManager sharedInstance].submitters.count;
    }
    return 0;
}

/*!
 * title for section
 */
- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section{
    switch (section) {
        case SV_SECTION_GENERAL : return NSLocalizedStringFromTable(@"Settings_Section_General", @"PhotoSubmitter", nil); break;
        case SV_SECTION_ACCOUNTS: return NSLocalizedStringFromTable(@"Settings_Section_Accounts", @"PhotoSubmitter", nil); break;
    }
    return nil;
}

/*!
 * footer for section
 */
- (NSString *)tableView:(UITableView *)tableView titleForFooterInSection:(NSInteger)section{
    switch (section) {
        case SV_SECTION_GENERAL : break;
        case SV_SECTION_ACCOUNTS: return NSLocalizedStringFromTable(@"Settings_Section_Accounts_Footer", @"PhotoSubmitter", nil); break;
    }
    return nil;    
}

/*!
 * create cell
 */
-(UITableViewCell *) tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{    
    UITableViewCell *cell;
    if(indexPath.section == SV_SECTION_GENERAL){
        cell = [self createGeneralSettingCell:indexPath.row];
    }else if(indexPath.section == SV_SECTION_ACCOUNTS){
        cell = [self createSocialAppButtonWithTag:indexPath.row];
    }
    return cell;
}

/*!
 * create social app button
 */
-(UITableViewCell *) createSocialAppButtonWithTag:(NSInteger)tag{
    ENGPhotoSubmitterAccount *account = [self indexToAccount:tag];
    id<ENGPhotoSubmitterProtocol> submitter = [ENGPhotoSubmitterManager submitterForAccount:account];
    
    NSString *identifier = [NSString stringWithFormat:@"social_%@", submitter.account.accountHash];
    UITableViewCell *cell = [cells_ objectForKey:identifier];
    if(cell == nil){
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleValue1 reuseIdentifier:identifier];
        cell.imageView.image = submitter.icon;
        cell.textLabel.text = submitter.displayName;
        ENGPhotoSubmitterSwitch *s = [switches_ objectAtIndex:tag];
        cell.accessoryView = s;
        if([submitter isLogined]){
            [s setOn:YES animated:NO];
        }else{
            [s setOn:NO animated:NO];
        }
        [cells_ setObject:cell forKey:identifier];
   }
    
    return cell;
}
     
/*!
 * on row selected
 */
- (void) tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath{
    if(indexPath.section == SV_SECTION_ACCOUNTS){
        ENGPhotoSubmitterAccount *account = [self indexToAccount:indexPath.row];
        id<ENGPhotoSubmitterProtocol> submitter = [ENGPhotoSubmitterManager submitterForAccount:account];
        if(submitter.isEnabled){
            ENGPhotoSubmitterServiceSettingTableViewController *vc = [self settingTableViewControllerForAccount:account];
            if(vc != nil){
                [self.navigationController pushViewController:vc animated:YES];
            }
        }
    }
    [tableView deselectRowAtIndexPath:indexPath animated: YES];
}

/*!
 * sort social app cell by switch state
 */
- (void) sortSocialAppCell{
    [switches_ sortUsingComparator:^(ENGPhotoSubmitterSwitch *a, ENGPhotoSubmitterSwitch *b){
        if(a.on != b.on){
            if(a.on){
                return NSOrderedAscending;
            }
            return NSOrderedDescending;
        }
        return (NSInteger)[a.account.type compare:b.account.type];
    }];
    
    for(int index = 0; index < switches_.count; index++){
        ENGPhotoSubmitterSwitch *s = [switches_ objectAtIndex:index];
        s.index = index;
    }
    [self.tableView reloadData];
}

#pragma mark - ui parts delegates
/*!
 * done button tapped
 */
- (void)settingDone:(id)sender{
    [self.parentViewController dismissViewControllerAnimated:YES completion:nil];
    [self.delegate didDismissSettingTableViewController];
}

/*!
 * if social app switch changed
 */
- (void)didSocialAppSwitchChanged:(id)sender{
    ENGPhotoSubmitterSwitch *s = (ENGPhotoSubmitterSwitch *)sender;
    id<ENGPhotoSubmitterProtocol> submitter = [ENGPhotoSubmitterManager submitterForAccount:s.account];
    if(s.on){
        [submitter login];
    }else{
        [submitter disable];
    }
}

/*!
 * if social app switch changed
 */
- (void)didGeneralSwitchChanged:(id)sender{
    ENGPhotoSubmitterSettings *settings = [ENGPhotoSubmitterSettings getInstance];
    UISwitch *s = (UISwitch *)sender;
    switch(s.tag){
        case SV_GENERAL_COMMENT: 
            settings.commentPostEnabled = s.on; 
            break;
        case SV_GENERAL_GPS:
            settings.gpsEnabled = s.on;
            [ENGPhotoSubmitterManager sharedInstance].enableGeoTagging = s.on;
            break;
        case SV_GENERAL_IMAGE:
            settings.autoEnhance = s.on;
            break;
    }
}

/*!
 * create switch with tag
 */
- (UISwitch *)createSwitchWithTag:(NSInteger)tag on:(BOOL)on{
    ENGPhotoSubmitterSwitch *s = [[ENGPhotoSubmitterSwitch alloc] initWithFrame:CGRectZero];
    s.on = on;
    s.tag = tag;
    return s;
}

#pragma mark - conversion methods
/*!
 * convert index to NSString *
 */
- (ENGPhotoSubmitterAccount *)indexToAccount:(NSInteger)index{
    for(ENGPhotoSubmitterSwitch *s in switches_){
        if(s.index == index){
            return s.account;
        }
    }    
    return nil;
}

/*!
 * convert NSString * to index
 */
- (NSInteger)accountToIndex:(NSString *)hash{
    for(ENGPhotoSubmitterSwitch *s in switches_){
        if([s.account.accountHash isEqualToString:hash]){
            return s.index;
        }
    }
    return SWITCH_NOTFOUND;
}
@end

//-----------------------------------------------------------------------------
//Public Implementations
#pragma mark -
#pragma mark Public Implementations
//-----------------------------------------------------------------------------
@implementation ENGPhotoSubmitterSettingTableViewController
@synthesize delegate;
@synthesize tableViewDelegate = tableViewDelegate_;

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
 * update social app switches
 */
- (void)updateSocialAppSwitches{
    for(int i = 0; i < switches_.count; i++){
        ENGPhotoSubmitterSwitch *s = [switches_ objectAtIndex:i];
        id<ENGPhotoSubmitterProtocol> submitter = [ENGPhotoSubmitterManager submitterForAccount:s.account];
        BOOL isLogined = submitter.isLogined;
        if(isLogined == NO){
            [submitter disable];
        }
        [s setOn:isLogined animated:YES];
    }
    [self sortSocialAppCell];
}


/*!
 * create general setting cell
 */
- (UITableViewCell *)createGeneralSettingCell:(NSInteger)tag{
    ENGPhotoSubmitterSettings *settings = [ENGPhotoSubmitterSettings getInstance];
    
    NSString *identifier = [NSString stringWithFormat:@"general_%ld", (long)tag];
    
    UITableViewCell *cell = [cells_ objectForKey:identifier];
    if(cell){
        return cell;
    }
    
    cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleValue1 reuseIdentifier:identifier];
    switch (tag) {
        case SV_GENERAL_COMMENT:
        {
            cell.textLabel.text = NSLocalizedStringFromTable(@"Settings_Row_Comment", @"PhotoSubmitter", nil);
            UISwitch *s = [self createSwitchWithTag:tag on:settings.commentPostEnabled];
            [s addTarget:self action:@selector(didGeneralSwitchChanged:) forControlEvents:UIControlEventValueChanged];
            cell.accessoryView = s;
            cell.imageView.image = [UIImage imageNamed:@"PhotoSubmitterSettingComment.png"];
            break;
        }    
        case SV_GENERAL_GPS:{
            cell.textLabel.text = NSLocalizedStringFromTable(@"Settings_Row_GPSTagging", @"PhotoSubmitter", nil);
            UISwitch *s = [self createSwitchWithTag:tag on:settings.gpsEnabled];
            [s addTarget:self action:@selector(didGeneralSwitchChanged:) forControlEvents:UIControlEventValueChanged];
            cell.accessoryView = s;
            cell.imageView.image = [UIImage imageNamed:@"PhotoSubmitterSettingLocation.png"];
            break;
        }
        case SV_GENERAL_IMAGE:{
            cell.textLabel.text = NSLocalizedStringFromTable(@"Settings_Row_Image", @"PhotoSubmitter", nil);
            UISwitch *s = [self createSwitchWithTag:tag on:settings.autoEnhance];
            [s addTarget:self action:@selector(didGeneralSwitchChanged:) forControlEvents:UIControlEventValueChanged];
            cell.accessoryView = s;
            cell.imageView.image = [UIImage imageNamed:@"PhotoSubmitterSettingAutoEnhance.png"];
            break;
        }
    }
    [cells_ setObject:cell forKey:identifier];
    return cell;
}

#pragma mark - PhotoSubmitterAuthDelegate delegate methods
/*!
 * photo submitter did login
 */
- (void)photoSubmitter:(id<ENGPhotoSubmitterProtocol>)photoSubmitter didLogin:(ENGPhotoSubmitterAccount *)account{
    NSInteger index = [self accountToIndex:account.accountHash];
    ENGPhotoSubmitterSwitch *s = [switches_ objectAtIndex:index];
    [s setOn:YES animated:YES];
    [self sortSocialAppCell];
}

/*!
 * photo submitter did logout
 */
- (void)photoSubmitter:(id<ENGPhotoSubmitterProtocol>)photoSubmitter didLogout:(ENGPhotoSubmitterAccount *)account{
    NSInteger index = [self accountToIndex:account.accountHash];
    UISwitch *s = [switches_ objectAtIndex:index];
    [s setOn:NO animated:YES];    
    [self sortSocialAppCell];
}

/*!
 * photo submitter start authorization
 */
- (void)photoSubmitter:(id<ENGPhotoSubmitterProtocol>)photoSubmitter willBeginAuthorization:(ENGPhotoSubmitterAccount *)account{
}

/*!
 * photo submitter authorization finished
 */
- (void)photoSubmitter:(id<ENGPhotoSubmitterProtocol>)photoSubmitter didAuthorizationFinished:(ENGPhotoSubmitterAccount *)account{
}

/*!
 * tableViewDelegate
 */
- (void)setTableViewDelegate:(id<ENGPhotoSubmitterServiceSettingTableViewDelegate>)inTableViewDelegate{
    tableViewDelegate_ = inTableViewDelegate;
    for(NSString *key in settingControllers_){
        ENGPhotoSubmitterSettingTableViewController *view = [settingControllers_ objectForKey:key];
        view.tableViewDelegate = tableViewDelegate_;
    }
}

#pragma mark - PhotoSubmitterServiceSettingDelegate
/*!
 * when add account cell tapped
 */
- (void)didRequestForAddAccount:(ENGPhotoSubmitterAccount *)account{
    id<ENGPhotoSubmitterProtocol> submitter = [ENGPhotoSubmitterManager submitterForAccount:account];
    ENGPhotoSubmitterServiceSettingTableViewController *settingView = submitter.settingView;
    if(settingView != nil){
        [settingControllers_ setObject:settingView forKey:submitter.account.accountHash];
        settingView.settingDelegate = self;
        settingView.tableViewDelegate = tableViewDelegate_;
    }
    ENGPhotoSubmitterSwitch *s = [[ENGPhotoSubmitterSwitch alloc] init];
    s.account = submitter.account;
    s.index = switches_.count;
    [s addTarget:self action:@selector(didSocialAppSwitchChanged:) forControlEvents:UIControlEventValueChanged];
    [switches_ addObject:s];
    int i = 0;
    for(ENGPhotoSubmitterSwitch *s in switches_){
        s.index = i;
        i++;
    }
    [self updateSocialAppSwitches];
}

/*!
 * delete account
 */
- (void)didRequestForDeleteAccount:(ENGPhotoSubmitterAccount *)account{
    NSInteger index = [self accountToIndex:account.accountHash];
    [switches_ removeObjectAtIndex:index];        
    NSInteger i = 0;
    for(ENGPhotoSubmitterSwitch *s in switches_){
        s.index = i;
        i++;
    }
    [settingControllers_ removeObjectForKey:account.accountHash];
    [[ENGPhotoSubmitterManager sharedInstance] removeSubmitterForAccount:account];
    [self.tableView reloadData];
}

#pragma mark - UIViewController methods
- (void)viewDidAppear:(BOOL)animated{
    UIBarButtonItem *doneButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemDone target:self action:@selector(settingDone:)];
    [self.navigationItem setRightBarButtonItem:doneButton animated:YES];
    [self setTitle:NSLocalizedStringFromTable(@"Settings_Title", @"PhotoSubmitter", nil)];
    
    UITableViewCell *cell = [self tableView:self.tableView cellForRowAtIndexPath:[NSIndexPath indexPathForRow:SV_GENERAL_COMMENT inSection:SV_SECTION_GENERAL]];
    UISwitch *s = (UISwitch *)cell.accessoryView;
    if(s && [s isKindOfClass:[UISwitch class]]){
        [s setOn:[ENGPhotoSubmitterSettings getInstance].commentPostEnabled animated:YES];
    }
    [self updateSocialAppSwitches];
    //[[PhotoSubmitterManager sharedInstance] refreshCredentials];
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
@end
