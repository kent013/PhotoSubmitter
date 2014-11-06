//
//  ENGSimplePhotoSubmitterSettingTableViewController.h
//
//  Created by Kentaro ISHITOYA on 12/02/13.
//

#import "ENGPhotoSubmitterServiceSettingTableViewController.h"

@interface ENGSimplePhotoSubmitterSettingTableViewController : ENGPhotoSubmitterServiceSettingTableViewController<ENGPhotoSubmitterDataDelegate>{
    BOOL attemptToAddAccount_;
    BOOL attemptToDeleteAccount_;
}
@property (nonatomic, readonly) BOOL attemptToAddAccount;
@property (nonatomic, readonly) BOOL attemptToDeleteAccount;
@end
