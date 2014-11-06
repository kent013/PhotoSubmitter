//
//  ENGAlbumPhotoSubmitterSettingViewController.h
//
//  Created by ISHITOYA Kentaro on 11/12/12.
//

#import <UIKit/UIKit.h>
#import "ENGPhotoSubmitterProtocol.h"
#import "ENGSimplePhotoSubmitterSettingTableViewController.h"
#import "ENGCreateAlbumPhotoSubmitterSettingViewController.h"

@interface ENGAlbumPhotoSubmitterSettingTableViewController : ENGSimplePhotoSubmitterSettingTableViewController{
    NSInteger selectedAlbumIndex_;
    ENGCreateAlbumPhotoSubmitterSettingViewController *createAlbumViewController_;
}
@end
