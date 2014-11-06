//
//  ENGAlbumPhotoSubmitterSettingViewController.m
//
//  Created by ISHITOYA Kentaro on 11/12/12.
//

#import "RegexKitLite.h"
#import "ENGAlbumPhotoSubmitterSettingTableViewController.h"
#import "ENGPhotoSubmitterManager.h"
#import "ENGPhotoSubmitterAlbumEntity.h"

#define FSV_SECTION_ACCOUNT 0
#define FSV_SECTION_ALBUMS 1
#define FSV_ROW_ACCOUNT_NAME 0
#define FSV_ROW_ACCOUNT_LOGOUT 1

#define FSV_BUTTON_TYPE 102
//-----------------------------------------------------------------------------
//Private Implementations
//-----------------------------------------------------------------------------
@interface ENGAlbumPhotoSubmitterSettingTableViewController(PrivateImplementation)
- (void) setupInitialState;
@end

@implementation ENGAlbumPhotoSubmitterSettingTableViewController(PrivateImplementation)
/*!
 * initialize
 */
-(void)setupInitialState{
    createAlbumViewController_ = [[ENGCreateAlbumPhotoSubmitterSettingViewController alloc] initWithAccount:self.account];
}
@end

//-----------------------------------------------------------------------------
//Public Implementations
//-----------------------------------------------------------------------------
@implementation ENGAlbumPhotoSubmitterSettingTableViewController
/*!
 * albums
 */
- (void)viewDidAppear:(BOOL)animated{
    [super viewDidAppear:animated];
    if(self.submitter.isAlbumSupported){
        [self.submitter updateAlbumListWithDelegate:self];
    }
}

#pragma mark -
#pragma mark tableview methods
/*! 
 * get section number
 */
-(NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    if(self.tableViewDelegate){
        NSInteger count = [self.tableViewDelegate settingViewController:self numberOfSectionsInTableView:tableView];
        if(count >= 0){
            return count;
        }
    }
    if(self.submitter.isAlbumSupported){
        return 2;
    }
    return 1;
}

/*!
 * get row number
 */
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    if(self.tableViewDelegate){
        NSInteger count = [self.tableViewDelegate settingViewController:self tableView:tableView numberOfRowsInSection:section];
        if(count >= 0){
            return count;
        }
    }
    if(self.submitter.isAlbumSupported){
        switch (section) {
            case FSV_SECTION_ALBUMS: return self.submitter.albumList.count + 1;
        }
    }
    return [super tableView:tableView numberOfRowsInSection:section];
}

/*!
 * title for section
 */
- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section{
    NSString *title = [self.tableViewDelegate settingViewController:self tableView:tableView titleForHeaderInSection:section];
    if(title != nil){
        return title;
    }
    if(self.submitter.isAlbumSupported){
        switch (section) {
            case FSV_SECTION_ALBUMS : return NSLocalizedStringFromTable(@"Detail_Section_Album", @"ENGPhotoSubmitter", nil); break;
        }
    }
    return [super tableView:tableView titleForHeaderInSection:section];
}

/*!
 * footer for section
 */
- (NSString *)tableView:(UITableView *)tableView titleForFooterInSection:(NSInteger)section{
    NSString *title = [self.tableViewDelegate settingViewController:self tableView:tableView titleForFooterInSection:section];
    if(title != nil){
        return title;
    }
    if(self.submitter.isAlbumSupported){
        switch (section){
            case FSV_SECTION_ALBUMS: return [NSString stringWithFormat:NSLocalizedStringFromTable(@"Album_Detail_Section_Album_Footer", @"ENGPhotoSubmitter", nil), self.submitter.displayName];
        }
    }
    return [super tableView:tableView titleForFooterInSection:section];;
}

/*!
 * create cell
 */
-(UITableViewCell *) tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{    
    UITableViewCell *cell = [self.tableViewDelegate settingViewController:self tableView:tableView cellForRowAtIndexPath:indexPath];
    
    if(cell != nil){
        return cell;
    }
    
    cell = [super tableView:tableView cellForRowAtIndexPath:indexPath];
    if(indexPath.section == FSV_SECTION_ALBUMS && self.submitter.isAlbumSupported){
        if(self.submitter.albumList.count == indexPath.row){
            cell.textLabel.text = NSLocalizedStringFromTable(@"Album_Detail_Section_Create_Album_Title", @"ENGPhotoSubmitter", nil);
            cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
        }else{
            ENGPhotoSubmitterAlbumEntity *album = [self.submitter.albumList objectAtIndex:indexPath.row];
            if(album.privacy != nil && [album.privacy isEqualToString:@""] == NO){
                cell.textLabel.text = [NSString stringWithFormat:@"%@ (privacy:%@)", album.name, album.privacy];
            }else{
                cell.textLabel.text = album.name;
            }
            if([album.albumId isEqualToString: self.submitter.targetAlbum.albumId]){
                cell.accessoryType = UITableViewCellAccessoryCheckmark;
                selectedAlbumIndex_ = indexPath.row;
            }
        }
    }
    return cell;
}


/*!
 * on row selected
 */
- (void) tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath{
    BOOL processed = [self.tableViewDelegate settingViewController:self tableView:tableView didSelectRowAtIndexPath:indexPath];
    if(processed){
        return;
    }
    if(indexPath.section == FSV_SECTION_ALBUMS && self.submitter.isAlbumSupported){
        UITableViewCell *cell = [tableView cellForRowAtIndexPath:indexPath];
        if(indexPath.row == self.submitter.albumList.count){
            [self.navigationController pushViewController:createAlbumViewController_ animated:YES];
        }else{
            cell.accessoryType = UITableViewCellAccessoryCheckmark;
            if(selectedAlbumIndex_ != indexPath.row){
                cell = [tableView cellForRowAtIndexPath:[NSIndexPath indexPathForRow:selectedAlbumIndex_ inSection:FSV_SECTION_ALBUMS]];
                cell.accessoryType = UITableViewCellAccessoryNone;
            }
            self.submitter.targetAlbum = [self.submitter.albumList objectAtIndex:indexPath.row];
            selectedAlbumIndex_ = indexPath.row;
        }
    }
    [super tableView:tableView didSelectRowAtIndexPath:indexPath];
}

#pragma mark -
#pragma mark ENGPhotoSubmitterAlbumDelegate methods
- (void)photoSubmitter:(id<ENGPhotoSubmitterProtocol>)photoSubmitter didAlbumUpdated:(NSMutableArray *)albums{
    if(photoSubmitter.targetAlbum == nil){
        for(ENGPhotoSubmitterAlbumEntity *album in albums){
            if([album.name isMatchedByRegex:PHOTOSUBMITTER_DEFAULT_ALBUM_NAME options:RKLCaseless inRange:NSMakeRange(0, album.name.length) error:nil]){
                photoSubmitter.targetAlbum = album;
                break;
            }
        }
    }
    [self.tableView reloadData];
}
@end