//
//  GoogleDrivePhotoSubmitter.h
//  PhotoSubmitter for Google Drive
//
//  Created by Kentaro ISHITOYA on 12/05/20.
//

#import "GData.h"
#import "GTMOAuth2Authentication.h"
#import "ENGPhotoSubmitterProtocol.h"
#import "ENGPhotoSubmitter.h"
#import "ENGGoogleDrivePhotoSubmitterSettingTableViewController.h"

/*!
 * photo submitter for google drive.
 * get instance with using 
 * [[PhotoSubmitter getInstance] submitterWithType:PhotoSubmitterTypePicasa]
 */
@interface ENGGoogleDrivePhotoSubmitter : ENGPhotoSubmitter<ENGPhotoSubmitterInstanceProtocol, NSURLConnectionDataDelegate, NSURLConnectionDelegate>{
    __strong GTMOAuth2Authentication *auth_;
    __strong NSMutableDictionary *contents_;
    __strong GDataServiceGoogleDocs *service_;
    __strong GDataFeedDocList *docFeed_;
    __strong ENGGoogleDrivePhotoSubmitterSettingTableViewController *settingView_;
}
@end
