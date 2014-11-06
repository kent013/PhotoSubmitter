//
//  FacebookPhotoSubmitter.h
//  PhotoSubmitter for Facebook
//
//  Created by ISHITOYA Kentaro on 11/12/13.
//  Copyright (c) 2011 cocotomo. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "Facebook.h"
#import "FBRequest+ENGUploadProgress.h"
#import "ENGPhotoSubmitterProtocol.h"
#import "ENGPhotoSubmitter.h"

/*!
 * photo submitter for facebook.
 * get instance with using 
 * [[PhotoSubmitter getInstance] submitterWithType:PhotoSubmitterTypeFacebook]
 * or
 * [PhotoSubmitter facebookPhotoSubmitter]
 */
@interface FacebookPhotoSubmitter : ENGPhotoSubmitter<ENGPhotoSubmitterInstanceProtocol, FBSessionDelegate, ENGFBRequestWithUploadProgressDelegate>{
    __strong Facebook *facebook_;
}
@end
