//
//  ENGPhotoSubmitterSettingTableViewController.m
//
//  Created by ISHITOYA Kentaro on 12/01/02.
//

#import "ENGPhotoSubmitterServiceSettingTableViewController.h"

//-----------------------------------------------------------------------------
//Private Implementations
//-----------------------------------------------------------------------------
@interface ENGPhotoSubmitterServiceSettingTableViewController(PrivateImplementation)
- (void) setupInitialState;
@end

@implementation ENGPhotoSubmitterServiceSettingTableViewController(PrivateImplementation)
/*!
 * initialize
 */
-(void)setupInitialState{
}
@end

//-----------------------------------------------------------------------------
//Public Implementations
//-----------------------------------------------------------------------------
@implementation ENGPhotoSubmitterServiceSettingTableViewController
@synthesize account = account_;
@synthesize settingDelegate;
@synthesize tableViewDelegate;

/*!
 * initialize
 */
- (id)initWithAccount:(ENGPhotoSubmitterAccount *)account{
    self = [super initWithStyle:UITableViewStyleGrouped];
    if(self){
        account_ = account;
        [self setupInitialState];
    }
    return self;
}


#pragma mark -
#pragma mark ENGPhotoSubmitterSettingTableViewProtocol methods
/*!
 * submitter
 */
- (id<ENGPhotoSubmitterProtocol>)submitter{
    return [ENGPhotoSubmitterManager submitterForAccount:account_];
}

#pragma mark -
#pragma mark UIView delegate
/*!
 * auto rotation
 */
- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
    if(interfaceOrientation == UIInterfaceOrientationPortrait ||
       interfaceOrientation == UIInterfaceOrientationPortraitUpsideDown){
        return YES;
    }
    return NO;
}
@end
