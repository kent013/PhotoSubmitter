//
//  MetaMovicsPhotoSubmitter.h
//  tottepost
//
//  Created by Kentaro ISHITOYA on 12/02/22.
//  Copyright (c) 2012 cocotomo. All rights reserved.
//

#import "PhotoSubmitter.h"
#import "MetaMovicsConnect.h"
#import "PhotoSubmitterAccountTableViewController.h"

/*!
 * photo submitter for metamovics.
 */
@interface MetaMovicsPhotoSubmitter : PhotoSubmitter<PhotoSubmitterInstanceProtocol, PhotoSubmitterPasswordAuthViewDelegate, MetaMovicsRequestDelegate, MetaMovicsSessionDelegate, PhotoSubmitterDataDelegate>{
    __strong PhotoSubmitterAccountTableViewController *authController_;
    __strong MetaMovicsConnect *metamovics_;
    __strong NSString *userId_;
    __strong NSString *password_;
    __strong NSMutableDictionary *contents_;
}
@end
