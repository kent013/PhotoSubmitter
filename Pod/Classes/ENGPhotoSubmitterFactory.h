//
//  ENGPhotoSubmitterFactory.h
//
//  Created by Kentaro ISHITOYA on 12/02/28.
//

#import <Foundation/Foundation.h>
#import "ENGPhotoSubmitterProtocol.h"

@interface ENGPhotoSubmitterFactory : NSObject
+ (id<ENGPhotoSubmitterProtocol>)createWithAccount:(ENGPhotoSubmitterAccount *)account;
@end
