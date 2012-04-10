//
//  SalesforcePhotoSubmitter.h
//  tottepost
//
//  Created by Kentaro ISHITOYA on 12/04/08.
//  Copyright (c) 2012 cocotomo. All rights reserved.
//

#import "RestKit.h"
#import "PhotoSubmitterProtocol.h"
#import "PhotoSubmitter.h"
#import "SFAuthContext.h"
#import "SFUser.h"
#import "SFOAuthViewController.h"

/*!
 * photo submitter for picasa.
 * get instance with using 
 * [[PhotoSubmitter getInstance] submitterWithType:PhotoSubmitterTypeSalesforce]
 */
@interface SalesforcePhotoSubmitter : PhotoSubmitter<PhotoSubmitterInstanceProtocol, RKRequestDelegate, SFAccessTokenRefreshDelegate, SFOAuthViewControllerDelegate, NSURLConnectionDelegate, NSURLConnectionDataDelegate>{
}
@end
