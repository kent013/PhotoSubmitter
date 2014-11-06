//
//  PhotoSubmitterAccount.h
//  tottepost
//
//  Created by Kentaro ISHITOYA on 12/04/17.
//  Copyright (c) 2012 cocotomo. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "PhotoSubmitterProtocol.h"

@interface PhotoSubmitterAccount : NSObject<NSCoding>{
    int index_;
    __strong NSString *type_;
    __strong NSString *accountHash_;
}

@property (assign, nonatomic) int index;
@property (readonly, nonatomic) NSString *type;
@property (readonly, nonatomic) NSString *accountHash;

- (id) initWithType:(NSString *)type andIndex:(int)index;
@end
