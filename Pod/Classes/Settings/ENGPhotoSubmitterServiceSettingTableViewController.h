//
//  ENGPhotoSubmitterSettingTableViewController.h
//
//  Created by ISHITOYA Kentaro on 12/01/02.
//

#import <UIKit/UIKit.h>
#import "ENGPhotoSubmitterManager.h"
#import "ENGPhotoSubmitterSettingTableViewProtocol.h"

@protocol ENGPhotoSubmitterServiceSettingDelegate;
@protocol ENGPhotoSubmitterServiceSettingTableViewDelegate;

@interface ENGPhotoSubmitterServiceSettingTableViewController : UITableViewController<ENGPhotoSubmitterServiceSettingTableViewProtocol>{
    ENGPhotoSubmitterAccount *account_;
}

- (id)initWithAccount:(ENGPhotoSubmitterAccount *)account;
@property (nonatomic, readonly) ENGPhotoSubmitterAccount *account;
@property (nonatomic, assign) id<ENGPhotoSubmitterServiceSettingDelegate> settingDelegate;
@property (nonatomic, assign) id<ENGPhotoSubmitterServiceSettingTableViewDelegate> tableViewDelegate;
@end


@protocol ENGPhotoSubmitterServiceSettingDelegate <NSObject>
- (void) didRequestForAddAccount:(ENGPhotoSubmitterAccount *)account;
- (void) didRequestForDeleteAccount:(ENGPhotoSubmitterAccount *)account;
@end

@protocol ENGPhotoSubmitterServiceSettingTableViewDelegate <NSObject>
- (NSInteger) settingViewController:(ENGPhotoSubmitterServiceSettingTableViewController *)settingViewController numberOfSectionsInTableView:(UITableView *)tableView;
- (NSInteger)settingViewController:(ENGPhotoSubmitterServiceSettingTableViewController *)settingViewController tableView:(UITableView *)table numberOfRowsInSection:(NSInteger)section;
- (NSString *)settingViewController:(ENGPhotoSubmitterServiceSettingTableViewController *)settingViewController tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section;
- (NSString *)settingViewController:(ENGPhotoSubmitterServiceSettingTableViewController *)settingViewController tableView:(UITableView *)tableView titleForFooterInSection:(NSInteger)section;
- (UITableViewCell *) settingViewController:(ENGPhotoSubmitterServiceSettingTableViewController *)settingViewController tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath;
- (BOOL) settingViewController:(ENGPhotoSubmitterServiceSettingTableViewController *)settingViewController tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath;
@end