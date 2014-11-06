//
//  MailPhotoSubmitterSettingTableViewController.h
//  tottepost
//
//  Created by Kentaro ISHITOYA on 12/04/21.
//  Copyright (c) 2012 cocotomo. All rights reserved.
//

#import "SimplePhotoSubmitterSettingTableViewController.h"

@interface MailPhotoSubmitterSettingTableViewController : SimplePhotoSubmitterSettingTableViewController<UITextFieldDelegate>{
    __strong UITextField *toTextField_;
    __strong UITextField *defaultSubjectTextField_;
    __strong UITextField *defaultBodyTextField_;
}

@end
