//
//  MinusProtocol.h
//  MinusConnect
//
//  Created by Kentaro ISHITOYA on 12/02/21.
//  Copyright (c) 2012 Kentaro ISHITOYA. All rights reserved.
//

#import <Foundation/Foundation.h>
/*!
 * request tags
 */
static NSString* kMinusRequestActiveUser = @"activeuser";
static NSString* kMinusRequestUserWithUserId = @"userWithUserId";
static NSString* kMinusRequestFileWithFileId = @"fileWithFileId";
static NSString* kMinusRequestFilesWithFolderId = @"filesWithFolderId";
static NSString* kMinusRequestCreateFile = @"createFile";
static NSString* kMinusRequestFolderWithFolderId = @"folderWithFolderId";
static NSString* kMinusRequestFoldersWithUsername = @"foldersWithUsername";
static NSString* kMinusRequestCreateFolder = @"createFolder";

/*!
 * credential keys
 */
static NSString *kMinusAccessToken = @"minusAuthToken";

@class MinusRequest;

/*!
 * delegate for session
 */
@protocol MinusSessionDelegate <NSObject>
- (void)minusDidLogin;
- (void)minusDidNotLogin;
- (void)minusDidLogout;
@end

/*!
 * delegate for minus request
 */
@protocol MinusRequestDelegate <NSObject>
@optional
- (void)requestLoading:(MinusRequest*)request;
- (void)request:(MinusRequest*)request didReceiveResponse:(NSURLResponse*)response;
- (void)request:(MinusRequest*)request didFailWithError:(NSError*)error;
- (void)request:(MinusRequest*)request didLoad:(id)result;
- (void)request:(MinusRequest*)request didLoadRawResponse:(NSData*)data;
- (void)request:(MinusRequest*)request didSendBodyData:(NSInteger)bytesWritten totalBytesWritten:(NSInteger)totalBytesWritten totalBytesExpectedToWrite:(NSInteger)totalBytesExpectedToWrite;
@end
