//
//  SettingViewController.m
//  tottepost
//
//  Created by ISHITOYA Kentaro on 11/12/11.
//  Copyright (c) 2011 cocotomo. All rights reserved.
//

#if ! __has_feature(objc_arc)
#error This file must be compiled with ARC. Use -fobjc-arc flag (or convert project to ARC).
#endif

#import "PhotoSubmitterSettingTableViewController.h"
#import "PhotoSubmitterSettingTableViewProtocol.h"
#import "PhotoSubmitterServiceSettingTableViewController.h"
#import "PhotoSubmitterSettings.h"
#import "PSLang.h"
#import "PhotoSubmitterSwitch.h"
#import "PhotoSubmitterAccountManager.h"
#import "RegexKitLite.h"

//-----------------------------------------------------------------------------
//Private Implementations
//-----------------------------------------------------------------------------
@interface PhotoSubmitterSettingTableViewController(PrivateImplementation)
- (void) setupInitialState;
- (PhotoSubmitterServiceSettingTableViewController *)settingTableViewControllerForAccount:(PhotoSubmitterAccount *)account;
- (void) settingDone:(id)sender;
- (UITableViewCell *) createSocialAppButtonWithTag:(int)tag;
- (void) didSocialAppSwitchChanged:(id)sender;
- (void) didGeneralSwitchChanged:(id)sender;
- (PhotoSubmitterAccount *) indexToAccount:(int) index;
- (int) accountToIndex:(NSString *) hash;
- (UISwitch *)createSwitchWithTag:(int)tag on:(BOOL)on;
- (void) sortSocialAppCell;
@end

#pragma mark - Private Implementations
@implementation PhotoSubmitterSettingTableViewController(PrivateImplementation)
/*!
 * setup initial state
 */
- (void)setupInitialState{
    self.tableView.delegate = self;
    switches_ = [[NSMutableArray alloc] init];
    settingControllers_ = [[NSMutableDictionary alloc] init];
    
    NSArray *submitters = [PhotoSubmitterManager sharedInstance].submitters;
    for(id<PhotoSubmitterProtocol> submitter in submitters){
        PhotoSubmitterServiceSettingTableViewController *settingView = 
          submitter.settingView;
        if(settingView != nil){
            [settingControllers_ setObject:settingView forKey:submitter.account.accountHash];
            settingView.settingDelegate = self;
            settingView.tableViewDelegate = tableViewDelegate_;
        }
    }
    
    [PhotoSubmitterManager sharedInstance].authenticationDelegate = self;
    
    int i = 0;
    for(id<PhotoSubmitterProtocol> submitter in submitters){
        PhotoSubmitterSwitch *s = [[PhotoSubmitterSwitch alloc] init];
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
- (PhotoSubmitterServiceSettingTableViewController *)settingTableViewControllerForAccount:(PhotoSubmitterAccount *)account{
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
        case SV_SECTION_ACCOUNTS: return [PhotoSubmitterManager sharedInstance].submitters.count;
    }
    return 0;
}

/*!
 * title for section
 */
- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section{
    switch (section) {
        case SV_SECTION_GENERAL : return [PSLang localized:@"Settings_Section_General"]; break;
        case SV_SECTION_ACCOUNTS: return [PSLang localized:@"Settings_Section_Accounts"]; break;
    }
    return nil;
}

/*!
 * footer for section
 */
- (NSString *)tableView:(UITableView *)tableView titleForFooterInSection:(NSInteger)section{
    switch (section) {
        case SV_SECTION_GENERAL : break;
        case SV_SECTION_ACCOUNTS: return [PSLang localized:@"Settings_Section_Accounts_Footer"]; break;
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
-(UITableViewCell *) createSocialAppButtonWithTag:(int)tag{
    PhotoSubmitterAccount *account = [self indexToAccount:tag];
    id<PhotoSubmitterProtocol> submitter = [PhotoSubmitterManager submitterForAccount:account];
    
    UITableViewCell *cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleValue1 reuseIdentifier:nil];
    cell.imageView.image = submitter.icon;
    cell.textLabel.text = submitter.displayName;
    PhotoSubmitterSwitch *s = [switches_ objectAtIndex:tag];
    cell.accessoryView = s;
    if([submitter isLogined]){
        [s setOn:YES animated:NO];
    }else{
        [s setOn:NO animated:NO];
    }
    return cell;
}
     
/*!
 * on row selected
 */
- (void) tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath{
    if(indexPath.section == SV_SECTION_ACCOUNTS){
        PhotoSubmitterAccount *account = [self indexToAccount:indexPath.row];
        id<PhotoSubmitterProtocol> submitter = [PhotoSubmitterManager submitterForAccount:account];
        if(submitter.isEnabled){
            PhotoSubmitterServiceSettingTableViewController *vc = [self settingTableViewControllerForAccount:account];
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
    [switches_ sortUsingComparator:^(PhotoSubmitterSwitch *a, PhotoSubmitterSwitch *b){
        if(a.on != b.on){
            if(a.on){
                return NSOrderedAscending;
            }
            return NSOrderedDescending;
        }
        return [a.account.type compare:b.account.type];
    }];
    
    for(int index = 0; index < switches_.count; index++){
        PhotoSubmitterSwitch *s = [switches_ objectAtIndex:index];
        s.index = index;
    }
    [self.tableView reloadData];
}

#pragma mark - ui parts delegates
/*!
 * done button tapped
 */
- (void)settingDone:(id)sender{
    [self.parentViewController dismissModalViewControllerAnimated:YES];
    [self.delegate didDismissSettingTableViewController];
}

/*!
 * if social app switch changed
 */
- (void)didSocialAppSwitchChanged:(id)sender{
    PhotoSubmitterSwitch *s = (PhotoSubmitterSwitch *)sender;
    id<PhotoSubmitterProtocol> submitter = [PhotoSubmitterManager submitterForAccount:s.account];
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
    PhotoSubmitterSettings *settings = [PhotoSubmitterSettings getInstance];
    UISwitch *s = (UISwitch *)sender;
    switch(s.tag){
        case SV_GENERAL_COMMENT: 
            settings.commentPostEnabled = s.on; 
            break;
        case SV_GENERAL_GPS:
            settings.gpsEnabled = s.on;
            [PhotoSubmitterManager sharedInstance].enableGeoTagging = s.on;
            break;
        case SV_GENERAL_IMAGE:
            settings.autoEnhance = s.on;
            break;
    }
}

/*!
 * create switch with tag
 */
- (UISwitch *)createSwitchWithTag:(int)tag on:(BOOL)on{
    PhotoSubmitterSwitch *s = [[PhotoSubmitterSwitch alloc] initWithFrame:CGRectZero];
    s.on = on;
    s.tag = tag;
    return s;
}

#pragma mark - conversion methods
/*!
 * convert index to NSString *
 */
- (PhotoSubmitterAccount *)indexToAccount:(int)index{
    for(PhotoSubmitterSwitch *s in switches_){
        if(s.index == index){
            return s.account;
        }
    }    
    return nil;
}

/*!
 * convert NSString * to index
 */
- (int)accountToIndex:(NSString *)hash{
    for(PhotoSubmitterSwitch *s in switches_){
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
@implementation PhotoSubmitterSettingTableViewController
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
        PhotoSubmitterSwitch *s = [switches_ objectAtIndex:i];
        id<PhotoSubmitterProtocol> submitter = [PhotoSubmitterManager submitterForAccount:s.account];
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
- (UITableViewCell *)createGeneralSettingCell:(int)tag{
    PhotoSubmitterSettings *settings = [PhotoSubmitterSettings getInstance];
    UITableViewCell *cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleValue1 reuseIdentifier:nil];
    switch (tag) {
        case SV_GENERAL_COMMENT:
        {
            cell.textLabel.text = [PSLang localized:@"Settings_Row_Comment"];
            UISwitch *s = [self createSwitchWithTag:tag on:settings.commentPostEnabled];
            [s addTarget:self action:@selector(didGeneralSwitchChanged:) forControlEvents:UIControlEventValueChanged];
            cell.accessoryView = s;
            cell.imageView.image = [UIImage imageNamed:@"PhotoSubmitterSettingComment.png"];
            break;
        }    
        case SV_GENERAL_GPS:{
            cell.textLabel.text = [PSLang localized:@"Settings_Row_GPSTagging"];
            UISwitch *s = [self createSwitchWithTag:tag on:settings.gpsEnabled];
            [s addTarget:self action:@selector(didGeneralSwitchChanged:) forControlEvents:UIControlEventValueChanged];
            cell.accessoryView = s;
            cell.imageView.image = [UIImage imageNamed:@"PhotoSubmitterSettingLocation.png"];
            break;
        }
        case SV_GENERAL_IMAGE:{
            cell.textLabel.text = [PSLang localized:@"Settings_Row_Image"];
            UISwitch *s = [self createSwitchWithTag:tag on:settings.autoEnhance];
            [s addTarget:self action:@selector(didGeneralSwitchChanged:) forControlEvents:UIControlEventValueChanged];
            cell.accessoryView = s;
            cell.imageView.image = [UIImage imageNamed:@"PhotoSubmitterSettingAutoEnhance.png"];
            break;
        }
    }
    return cell;
}

#pragma mark - PhotoSubmitterAuthDelegate delegate methods
/*!
 * photo submitter did login
 */
- (void)photoSubmitter:(id<PhotoSubmitterProtocol>)photoSubmitter didLogin:(PhotoSubmitterAccount *)account{
    int index = [self accountToIndex:account.accountHash];
    PhotoSubmitterSwitch *s = [switches_ objectAtIndex:index];
    [s setOn:YES animated:YES];
    [self sortSocialAppCell];
}

/*!
 * photo submitter did logout
 */
- (void)photoSubmitter:(id<PhotoSubmitterProtocol>)photoSubmitter didLogout:(PhotoSubmitterAccount *)account{
    int index = [self accountToIndex:account.accountHash];
    UISwitch *s = [switches_ objectAtIndex:index];
    [s setOn:NO animated:YES];    
    [self sortSocialAppCell];
}

/*!
 * photo submitter start authorization
 */
- (void)photoSubmitter:(id<PhotoSubmitterProtocol>)photoSubmitter willBeginAuthorization:(PhotoSubmitterAccount *)account{
}

/*!
 * photo submitter authorization finished
 */
- (void)photoSubmitter:(id<PhotoSubmitterProtocol>)photoSubmitter didAuthorizationFinished:(PhotoSubmitterAccount *)account{
}

/*!
 * tableViewDelegate
 */
- (void)setTableViewDelegate:(id<PhotoSubmitterServiceSettingTableViewDelegate>)inTableViewDelegate{
    tableViewDelegate_ = inTableViewDelegate;
    for(NSString *key in settingControllers_){
        PhotoSubmitterSettingTableViewController *view = [settingControllers_ objectForKey:key];
        view.tableViewDelegate = tableViewDelegate_;
    }
}

#pragma mark - PhotoSubmitterServiceSettingDelegate
/*!
 * when add account cell tapped
 */
- (void)didRequestForAddAccount:(PhotoSubmitterAccount *)account{
    id<PhotoSubmitterProtocol> submitter = [PhotoSubmitterManager submitterForAccount:account];
    PhotoSubmitterServiceSettingTableViewController *settingView = submitter.settingView;
    if(settingView != nil){
        [settingControllers_ setObject:settingView forKey:submitter.account.accountHash];
        settingView.settingDelegate = self;
        settingView.tableViewDelegate = tableViewDelegate_;
    }
    PhotoSubmitterSwitch *s = [[PhotoSubmitterSwitch alloc] init];
    s.account = submitter.account;
    s.index = switches_.count;
    [s addTarget:self action:@selector(didSocialAppSwitchChanged:) forControlEvents:UIControlEventValueChanged];
    [switches_ addObject:s];
    int i = 0;
    for(PhotoSubmitterSwitch *s in switches_){
        s.index = i;
        i++;
    }
    [self updateSocialAppSwitches];
}

/*!
 * delete account
 */
- (void)didRequestForDeleteAccount:(PhotoSubmitterAccount *)account{
    int index = [self accountToIndex:account.accountHash];
    [switches_ removeObjectAtIndex:index];        
    int i = 0;
    for(PhotoSubmitterSwitch *s in switches_){
        s.index = i;
        i++;
    }
    [settingControllers_ removeObjectForKey:account.accountHash];
    [[PhotoSubmitterManager sharedInstance] removeSubmitterForAccount:account];
    [self.tableView reloadData];
}

#pragma mark - UIViewController methods
- (void)viewDidAppear:(BOOL)animated{
    UIBarButtonItem *doneButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemDone target:self action:@selector(settingDone:)];
    [self.navigationItem setRightBarButtonItem:doneButton animated:YES];
    [self setTitle:[PSLang localized:@"Settings_Title"]];
    
    [self.tableView reloadRowsAtIndexPaths:[NSArray arrayWithObjects:[NSIndexPath indexPathForRow:SV_GENERAL_COMMENT inSection:SV_SECTION_GENERAL], nil] withRowAnimation:NO];
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
