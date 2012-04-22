//
//  PhotoSubmitterSettingTableViewController.m
//  tottepost
//
//  Created by ISHITOYA Kentaro on 12/01/02.
//  Copyright (c) 2012 cocotomo All rights reserved.
//

#if ! __has_feature(objc_arc)
#error This file must be compiled with ARC. Use -fobjc-arc flag (or convert project to ARC).
#endif

#import "PhotoSubmitterServiceSettingTableViewController.h"

//-----------------------------------------------------------------------------
//Private Implementations
//-----------------------------------------------------------------------------
@interface PhotoSubmitterServiceSettingTableViewController(PrivateImplementation)
- (void) setupInitialState;
@end

@implementation PhotoSubmitterServiceSettingTableViewController(PrivateImplementation)
/*!
 * initialize
 */
-(void)setupInitialState{
}
@end

//-----------------------------------------------------------------------------
//Public Implementations
//-----------------------------------------------------------------------------
@implementation PhotoSubmitterServiceSettingTableViewController
@synthesize account = account_;
@synthesize settingDelegate;
@synthesize tableViewDelegate;

/*!
 * initialize
 */
- (id)initWithAccount:(PhotoSubmitterAccount *)account{
    self = [super initWithStyle:UITableViewStyleGrouped];
    if(self){
        account_ = account;
        [self setupInitialState];
    }
    return self;
}


#pragma mark -
#pragma mark PhotoSubmitterSettingTableViewProtocol methods
/*!
 * submitter
 */
- (id<PhotoSubmitterProtocol>)submitter{
    return [PhotoSubmitterManager submitterForAccount:account_];
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
