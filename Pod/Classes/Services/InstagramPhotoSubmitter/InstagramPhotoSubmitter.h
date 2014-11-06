//
//  InstagramPhotoSubmitter.h
//  PhotoSubmitter for Instagram
//
//  Created by Kentaro ISHITOYA on 12/05/20.
//  Copyright (c) 2012 cocotomo. All rights reserved.
//

#import "PhotoSubmitterProtocol.h"
#import "PhotoSubmitter.h"

/*!
 * photo submitter for Instagram.
 * get instance with using 
 * [[PhotoSubmitter getInstance] submitterWithType:PhotoSubmitterTypeInstagram]
 */
@interface InstagramPhotoSubmitter : PhotoSubmitter<PhotoSubmitterInstanceProtocol, UIDocumentInteractionControllerDelegate>{
    UIDocumentInteractionController *interactionController_;
}
@end
