//
//  ENGViewController.h
//  PhotoSubmitter
//
//  Created by kent013 on 11/06/2014.
//  Copyright (c) 2014 kent013. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "ENGPhotoSubmitterSettingTableViewController.h"
#import "ENGPhotoSubmitterProtocol.h"

@interface ENGViewController : UIViewController<UIImagePickerControllerDelegate, UINavigationControllerDelegate, ENGPhotoSubmitterSettingTableViewControllerDelegate, ENGPhotoSubmitterPhotoDelegate, ENGPhotoSubmitterNavigationControllerDelegate>{
    ENGPhotoSubmitterSettingTableViewController *settingViewController_;
    UINavigationController *settingNavigationController_;
    UIImagePickerController *imagePicker_;
}
@end