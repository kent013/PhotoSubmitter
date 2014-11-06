//
//  ENGPhotoSubmitterAccountManager.h
//
//  Created by Kentaro ISHITOYA on 12/04/17.
//

#import <Foundation/Foundation.h>
#import "ENGPhotoSubmitterAccount.h"

@interface ENGPhotoSubmitterAccountManager : NSObject{
    __strong NSMutableDictionary *accounts_;
}

@property (readonly, nonatomic) NSArray *accounts;

- (ENGPhotoSubmitterAccount *) createAccountForType:(NSString *)type;
- (void) addAccount:(ENGPhotoSubmitterAccount *)account;
- (void) removeAccount:(ENGPhotoSubmitterAccount *)account;
- (BOOL) containsAccount:(ENGPhotoSubmitterAccount *)account;
- (NSInteger) countAccountForType:(NSString *)type;
- (NSArray *) accountsForType:(NSString *)type;
- (ENGPhotoSubmitterAccount *) accountForType:(NSString *)type andIndex:(NSInteger)index;
- (ENGPhotoSubmitterAccount *) accountForHash:(NSString *)hash;
+ (ENGPhotoSubmitterAccountManager *)sharedManager;
@end
