//
//  SimplePhotoSubmitterSettingTableViewController.h
//  tottepost
//
//  Created by Kentaro ISHITOYA on 12/02/13.
//  Copyright (c) 2012 cocotomo. All rights reserved.
//

#import "PhotoSubmitterServiceSettingTableViewController.h"

@interface SimplePhotoSubmitterSettingTableViewController : PhotoSubmitterServiceSettingTableViewController<PhotoSubmitterDataDelegate>{
    BOOL attemptToAddAccount_;
    BOOL attemptToDeleteAccount_;
}
@property (nonatomic, readonly) BOOL attemptToAddAccount;
@property (nonatomic, readonly) BOOL attemptToDeleteAccount;
@end
