//
//  ENGPhotoSubmitterSwitch.h
//
//  Created by Kentaro ISHITOYA on 12/03/06.
//

#import <UIKit/UIKit.h>
#import "ENGPhotoSubmitterAccount.h"

@interface ENGPhotoSubmitterSwitch : UISwitch
@property (nonatomic, strong) ENGPhotoSubmitterAccount *account;
@property (nonatomic, strong) NSDate *onEnabled;
@property (nonatomic, assign) NSInteger index;
@end
