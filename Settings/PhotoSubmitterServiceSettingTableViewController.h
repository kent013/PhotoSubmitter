//
//  PhotoSubmitterSettingTableViewController.h
//  tottepost
//
//  Created by ISHITOYA Kentaro on 12/01/02.
//  Copyright (c) 2012 cocotomo. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "PhotoSubmitterManager.h"
#import "PhotoSubmitterSettingTableViewProtocol.h"

@protocol PhotoSubmitterServiceSettingDelegate;
@protocol PhotoSubmitterServiceSettingTableViewDelegate;

@interface PhotoSubmitterServiceSettingTableViewController : UITableViewController<PhotoSubmitterServiceSettingTableViewProtocol>{
    PhotoSubmitterAccount *account_;
}

- (id)initWithAccount:(PhotoSubmitterAccount *)account;
@property (nonatomic, readonly) PhotoSubmitterAccount *account;
@property (nonatomic, assign) id<PhotoSubmitterServiceSettingDelegate> settingDelegate;
@property (nonatomic, assign) id<PhotoSubmitterServiceSettingTableViewDelegate> tableViewDelegate;
@end


@protocol PhotoSubmitterServiceSettingDelegate <NSObject>
- (void) didRequestForAddAccount:(PhotoSubmitterAccount *)account;
- (void) didRequestForDeleteAccount:(PhotoSubmitterAccount *)account;
@end

@protocol PhotoSubmitterServiceSettingTableViewDelegate <NSObject>
- (NSInteger) settingViewController:(PhotoSubmitterServiceSettingTableViewController *)settingViewController numberOfSectionsInTableView:(UITableView *)tableView;
- (NSInteger)settingViewController:(PhotoSubmitterServiceSettingTableViewController *)settingViewController tableView:(UITableView *)table numberOfRowsInSection:(NSInteger)section;
- (NSString *)settingViewController:(PhotoSubmitterServiceSettingTableViewController *)settingViewController tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section;
- (NSString *)settingViewController:(PhotoSubmitterServiceSettingTableViewController *)settingViewController tableView:(UITableView *)tableView titleForFooterInSection:(NSInteger)section;
- (UITableViewCell *) settingViewController:(PhotoSubmitterServiceSettingTableViewController *)settingViewController tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath;
- (BOOL) settingViewController:(PhotoSubmitterServiceSettingTableViewController *)settingViewController tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath;
@end