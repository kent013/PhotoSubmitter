//
//  MetaMovicsProtocol.h
//  MetaMovicsConnect
//
//  Created by Kentaro ISHITOYA on 12/02/21.
//  Copyright (c) 2012 Kentaro ISHITOYA. All rights reserved.
//

#import <Foundation/Foundation.h>
/*!
 * request tags
 */

static NSString* kMetaMovicsRequestGetSessionToken = @"createUploadSession";
static NSString* kMetaMovicsRequestUpload = @"upload";
static NSString* kMetaMovicsRequestCreatePage = @"createPage";

/*!
 * credential keys
 */
static NSString *kMetaMovicsAccessToken = @"metamovicsAuthToken";

@class ENGMetaMovicsRequest;

/*!
 * delegate for session
 */
@protocol ENGMetaMovicsSessionDelegate <NSObject>
- (void)metamovicsDidLogin;
- (void)metamovicsDidNotLogin;
- (void)metamovicsDidLogout;
@end

/*!
 * delegate for metamovics request
 */
@protocol ENGMetaMovicsRequestDelegate <NSObject>
@optional
- (void)requestLoading:(ENGMetaMovicsRequest*)request;
- (void)request:(ENGMetaMovicsRequest*)request didReceiveResponse:(NSURLResponse*)response;
- (void)request:(ENGMetaMovicsRequest*)request didFailWithError:(NSError*)error;
- (void)request:(ENGMetaMovicsRequest*)request didLoad:(id)result;
- (void)request:(ENGMetaMovicsRequest*)request didLoadRawResponse:(NSData*)data;
- (void)request:(ENGMetaMovicsRequest*)request didSendBodyData:(NSInteger)bytesWritten totalBytesWritten:(NSInteger)totalBytesWritten totalBytesExpectedToWrite:(NSInteger)totalBytesExpectedToWrite;
@end
