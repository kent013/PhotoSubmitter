//
//  MetaMovicsPhotoSubmitter.h
//  tottepost
//
//  Created by Kentaro ISHITOYA on 12/02/22.
//  Copyright (c) 2012 cocotomo. All rights reserved.
//

#import "ENGPhotoSubmitter.h"
#import "ENGMetaMovicsConnect.h"
#import "ENGPhotoSubmitterAccountTableViewController.h"

/*!
 * photo submitter for metamovics.
 */
@interface ENGMetaMovicsPhotoSubmitter : ENGPhotoSubmitter<ENGPhotoSubmitterInstanceProtocol, ENGPhotoSubmitterPasswordAuthViewDelegate, ENGMetaMovicsRequestDelegate, ENGMetaMovicsSessionDelegate, ENGPhotoSubmitterDataDelegate>{
    __strong ENGPhotoSubmitterAccountTableViewController *authController_;
    __strong ENGMetaMovicsConnect *metamovics_;
    __strong NSString *userId_;
    __strong NSString *password_;
    __strong NSMutableDictionary *contents_;
}
@end
