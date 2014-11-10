//
//  ENGDropboxPhotoSubmitter.h
//  PhotoSubmitter for Dropbox
//
//  Created by ISHITOYA Kentaro on 11/12/22.
//

#import "ENGPhotoSubmitterProtocol.h"
#import "ENGPhotoSubmitter.h"
#import "DropboxSDK.h"

/*!
 * photo submitter for dropbox.
 */
@interface ENGDropboxPhotoSubmitter : ENGPhotoSubmitter<ENGPhotoSubmitterInstanceProtocol, DBSessionDelegate, DBRestClientDelegate>{
}

+ (void)setDropboxAPIKey:(NSString *)APIKey andSecret:(NSString *)APISecret;
@end
