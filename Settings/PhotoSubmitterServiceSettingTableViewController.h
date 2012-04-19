//
//  PhotoSubmitterSettingTableViewController.h
//  tottepost
//
//  Created by ISHITOYA Kentaro on 12/01/02.
//  Copyright (c) 2012 cocotomo. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "PhotoSubmitterManager.h"
#import "PhotoSubmitterSettingTableViewProtocol.h"


@interface PhotoSubmitterServiceSettingTableViewController : UITableViewController<PhotoSubmitterServiceSettingTableViewProtocol>{
    PhotoSubmitterAccount *account_;
}

- (id)initWithAccount:(PhotoSubmitterAccount *)account;
@property (nonatomic, readonly) PhotoSubmitterAccount *account;
@end
