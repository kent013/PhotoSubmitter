//
//  GDrivePhotoSubmitter.h
//  PhotoSubmitter for Picasa
//
//  Created by Kentaro ISHITOYA on 12/05/20.
//  Copyright (c) 2012 cocotomo. All rights reserved.
//

#import "GData.h"
#import "GTMOAuth2Authentication.h"
#import "PhotoSubmitterProtocol.h"
#import "PhotoSubmitter.h"
#import "GDrivePhotoSubmitterSettingTableViewController.h"

/*!
 * photo submitter for gdrive.
 * get instance with using 
 * [[PhotoSubmitter getInstance] submitterWithType:PhotoSubmitterTypePicasa]
 */
@interface GDrivePhotoSubmitter : PhotoSubmitter<PhotoSubmitterInstanceProtocol, NSURLConnectionDataDelegate, NSURLConnectionDelegate>{
    __strong GTMOAuth2Authentication *auth_;
    __strong NSMutableDictionary *contents_;
    __strong GDataServiceGoogleDocs *service_;
    __strong GDataFeedDocList *docFeed_;
    __strong GDrivePhotoSubmitterSettingTableViewController *settingView_;
}
@end
