//
//  ENGPhotoSubmitterSwitch.m
//
//  Created by Kentaro ISHITOYA on 12/03/06.
//

#import "ENGPhotoSubmitterSwitch.h"

@implementation ENGPhotoSubmitterSwitch
@synthesize account;
@synthesize onEnabled;
@synthesize index;

- (void)setOn:(BOOL)on{
    [self setOn:on animated:NO];
}

- (void) setOn:(BOOL)on animated:(BOOL)animated{
    [super setOn:on animated:animated];
    if(on){
        if([onEnabled isEqualToDate:[NSDate distantPast]]){
            onEnabled = [NSDate date];
        }else{
            return;
        }
    }else{
        onEnabled = [NSDate distantPast];
    }
}
@end
