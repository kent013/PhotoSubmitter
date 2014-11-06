//
//  CreateAlbumPhotoSubmitterSettingViewController.h
//
//  Created by Kentaro ISHITOYA on 12/02/13.
//

#import <UIKit/UIKit.h>
#import "ENGPhotoSubmitterServiceSettingTableViewController.h"

@interface ENGCreateAlbumPhotoSubmitterSettingViewController : ENGPhotoSubmitterServiceSettingTableViewController<UITextFieldDelegate, ENGPhotoSubmitterAlbumDelegate>{
    UITextField *titleField_;
}
@end
