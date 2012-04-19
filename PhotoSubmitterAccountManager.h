//
//  PhotoSubmitterAccountManager.h
//  tottepost
//
//  Created by Kentaro ISHITOYA on 12/04/17.
//  Copyright (c) 2012 cocotomo. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "PhotoSubmitterAccount.h"

@interface PhotoSubmitterAccountManager : NSObject{
    __strong NSMutableDictionary *accounts_;
}

@property (readonly, nonatomic) NSArray *accounts;

- (PhotoSubmitterAccount *) createAccountForType:(NSString *)type;
- (void) addAccount:(PhotoSubmitterAccount *)account;
- (void) removeAccount:(PhotoSubmitterAccount *)account;
- (BOOL) containsAccount:(PhotoSubmitterAccount *)account;
- (int) countAccountForType:(NSString *)type;
- (NSArray *) accountsForType:(NSString *)type;
- (PhotoSubmitterAccount *) accountForType:(NSString *)type andIndex:(int)index;
- (PhotoSubmitterAccount *) accountForHash:(NSString *)hash;
+ (PhotoSubmitterAccountManager *)sharedManager;
@end
