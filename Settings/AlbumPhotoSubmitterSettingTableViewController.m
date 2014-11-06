//
//  AlbumPhotoSubmitterSettingViewController.m
//  tottepost
//
//  Created by ISHITOYA Kentaro on 11/12/12.
//  Copyright (c) 2011 cocotomo. All rights reserved.
//

#if ! __has_feature(objc_arc)
#error This file must be compiled with ARC. Use -fobjc-arc flag (or convert project to ARC).
#endif

#import "AlbumPhotoSubmitterSettingTableViewController.h"
#import "PhotoSubmitterManager.h"
#import "PhotoSubmitterAlbumEntity.h"
#import "RegexKitLite.h"
#import "PSLang.h"

#define FSV_SECTION_ACCOUNT 0
#define FSV_SECTION_ALBUMS 1
#define FSV_ROW_ACCOUNT_NAME 0
#define FSV_ROW_ACCOUNT_LOGOUT 1

#define FSV_BUTTON_TYPE 102
//-----------------------------------------------------------------------------
//Private Implementations
//-----------------------------------------------------------------------------
@interface AlbumPhotoSubmitterSettingTableViewController(PrivateImplementation)
- (void) setupInitialState;
@end

@implementation AlbumPhotoSubmitterSettingTableViewController(PrivateImplementation)
/*!
 * initialize
 */
-(void)setupInitialState{
    createAlbumViewController_ = [[CreateAlbumPhotoSubmitterSettingViewController alloc] initWithAccount:self.account];
}
@end

//-----------------------------------------------------------------------------
//Public Implementations
//-----------------------------------------------------------------------------
@implementation AlbumPhotoSubmitterSettingTableViewController
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
            case FSV_SECTION_ALBUMS : return [PSLang localized:@"Detail_Section_Album"]; break;
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
            case FSV_SECTION_ALBUMS: return [NSString stringWithFormat:[PSLang localized:@"Album_Detail_Section_Album_Footer"], self.submitter.displayName];
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
            cell.textLabel.text = [PSLang localized:@"Album_Detail_Section_Create_Album_Title"];
            cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
        }else{
            PhotoSubmitterAlbumEntity *album = [self.submitter.albumList objectAtIndex:indexPath.row];
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
#pragma mark PhotoSubmitterAlbumDelegate methods
- (void)photoSubmitter:(id<PhotoSubmitterProtocol>)photoSubmitter didAlbumUpdated:(NSMutableArray *)albums{
    if(photoSubmitter.targetAlbum == nil){
        for(PhotoSubmitterAlbumEntity *album in albums){
            if([album.name isMatchedByRegex:TOTTEPOST_DEFAULT_ALBUM_NAME options:RKLCaseless inRange:NSMakeRange(0, album.name.length) error:nil]){
                photoSubmitter.targetAlbum = album;
                break;
            }
        }
    }
    [self.tableView reloadData];
}
@end