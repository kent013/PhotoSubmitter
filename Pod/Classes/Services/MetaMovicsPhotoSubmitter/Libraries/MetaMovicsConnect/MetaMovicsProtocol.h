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

@class MetaMovicsRequest;

/*!
 * delegate for session
 */
@protocol MetaMovicsSessionDelegate <NSObject>
- (void)metamovicsDidLogin;
- (void)metamovicsDidNotLogin;
- (void)metamovicsDidLogout;
@end

/*!
 * delegate for metamovics request
 */
@protocol MetaMovicsRequestDelegate <NSObject>
@optional
- (void)requestLoading:(MetaMovicsRequest*)request;
- (void)request:(MetaMovicsRequest*)request didReceiveResponse:(NSURLResponse*)response;
- (void)request:(MetaMovicsRequest*)request didFailWithError:(NSError*)error;
- (void)request:(MetaMovicsRequest*)request didLoad:(id)result;
- (void)request:(MetaMovicsRequest*)request didLoadRawResponse:(NSData*)data;
- (void)request:(MetaMovicsRequest*)request didSendBodyData:(NSInteger)bytesWritten totalBytesWritten:(NSInteger)totalBytesWritten totalBytesExpectedToWrite:(NSInteger)totalBytesExpectedToWrite;
@end
