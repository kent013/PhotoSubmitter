//
//  ENGPhotoSubmitterSettingTableViewController.h
//
//  Created by ISHITOYA Kentaro on 11/12/11.
//

#import <UIKit/UIKit.h>
#import "ENGPhotoSubmitterManager.h"
#import "ENGPhotoSubmitterServiceSettingTableViewController.h"

@protocol ENGPhotoSubmitterSettingTableViewControllerDelegate;

/*!
 * setting view controller
 */
@interface ENGPhotoSubmitterSettingTableViewController : UITableViewController<ENGPhotoSubmitterAuthenticationDelegate, ENGPhotoSubmitterServiceSettingDelegate>{
    __strong id<ENGPhotoSubmitterServiceSettingTableViewDelegate> tableViewDelegate_;
@protected
    __strong NSMutableDictionary *settingControllers_;
    __strong NSMutableArray *switches_;
    __strong NSMutableDictionary *cells_;
}
- (void) updateSocialAppSwitches;
- (UITableViewCell *) createGeneralSettingCell:(NSInteger)tag;
@property (weak, nonatomic) id<ENGPhotoSubmitterSettingTableViewControllerDelegate> delegate;
@property (strong, nonatomic) id<ENGPhotoSubmitterServiceSettingTableViewDelegate> tableViewDelegate;
@end

@protocol ENGPhotoSubmitterSettingTableViewControllerDelegate <NSObject>
- (void) didDismissSettingTableViewController;
@end