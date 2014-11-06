//
//  PhotoSubmitterSwitch.m
//  tottepost
//
//  Created by Kentaro ISHITOYA on 12/03/06.
//  Copyright (c) 2012 cocotomo. All rights reserved.
//

#if ! __has_feature(objc_arc)
#error This file must be compiled with ARC. Use -fobjc-arc flag (or convert project to ARC).
#endif

#import "PhotoSubmitterSwitch.h"

@implementation PhotoSubmitterSwitch
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
