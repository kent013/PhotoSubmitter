//
//  ENGGoogleDrivePhotoSubmitterSettingTableViewControllerViewController.m
//
//  Created by Kentaro ISHITOYA on 12/05/21.
//

#import "ENGGoogleDrivePhotoSubmitterSettingTableViewController.h"
#import "ENGPhotoSubmitterLocalization.h"
#define FSV_SECTION_ACCOUNTS 0
#define FSV_SECTION_ALBUMS 1

//-----------------------------------------------------------------------------
//Private Implementations
//-----------------------------------------------------------------------------
@interface ENGGoogleDrivePhotoSubmitterSettingTableViewController(PrivateImplementation)
@end

@implementation ENGGoogleDrivePhotoSubmitterSettingTableViewController(PrivateImplementation)
@end

//-----------------------------------------------------------------------------
//Public Implementations
//-----------------------------------------------------------------------------
@implementation ENGGoogleDrivePhotoSubmitterSettingTableViewController
/*!
 * footer for section
 */
- (NSString *)tableView:(UITableView *)tableView titleForFooterInSection:(NSInteger)section{
    if(self.submitter.isAlbumSupported){
        switch (section){
            case FSV_SECTION_ACCOUNTS: {
                NSString *spTitle = [super tableView:tableView titleForFooterInSection:section];
                if(spTitle == nil){
                    spTitle = @"";
                }else{
                    [spTitle stringByAppendingFormat:@"\n"];
                }
                return [spTitle stringByAppendingString:ENGPhotoSubmitterLocalization(@"GDrive_Detail_Section_Account_Footer")]; 
            }
            case FSV_SECTION_ALBUMS: return [NSString stringWithFormat:ENGPhotoSubmitterLocalization(@"Album_Detail_Section_Album_Footer"), self.submitter.displayName];
        }
    }
    NSString *title = [self.tableViewDelegate settingViewController:self tableView:tableView titleForFooterInSection:section];
    if(title != nil){
        return title;
    }
    return [super tableView:tableView titleForFooterInSection:section];
}
@end
