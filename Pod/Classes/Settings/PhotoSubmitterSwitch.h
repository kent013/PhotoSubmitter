//
//  PhotoSubmitterSwitch.h
//  tottepost
//
//  Created by Kentaro ISHITOYA on 12/03/06.
//  Copyright (c) 2012 cocotomo. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "PhotoSubmitterAccount.h"

@interface PhotoSubmitterSwitch : UISwitch
@property (nonatomic, strong) PhotoSubmitterAccount *account;
@property (nonatomic, strong) NSDate *onEnabled;
@property (nonatomic, assign) int index;
@end
