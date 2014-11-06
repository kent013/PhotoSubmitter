//
//  ENGPhotoSubmitterServiceSettingTableViewProtocol.h
//
//  Created by ISHITOYA Kentaro on 12/01/02.
//

#import <Foundation/Foundation.h>
#import "ENGPhotoSubmitterProtocol.h"

#define PHOTOSUBMITTER_DEFAULT_ALBUM_NAME @"photoSubmitter"
#define SV_SECTION_ACCOUNT 0
#define SV_ROW_ACCOUNT_NAME 0
#define SV_ROW_ACCOUNT_LOGOUT 1
#define SV_ROW_ACCOUNT_ADD 2
#define SV_ROW_ACCOUNT_DELETE 3
#define SV_BUTTON_TYPE 102

#define SV_SECTION_GENERAL  0
#define SV_SECTION_ACCOUNTS 1

#define SV_GENERAL_COUNT 3
#define SV_GENERAL_COMMENT 0
#define SV_GENERAL_GPS 1
#define SV_GENERAL_IMAGE 2

#define SWITCH_NOTFOUND -1

@protocol ENGPhotoSubmitterServiceSettingTableViewProtocol <NSObject>
- (id<ENGPhotoSubmitterProtocol>) submitter;
- (ENGPhotoSubmitterAccount *) account;
@end
