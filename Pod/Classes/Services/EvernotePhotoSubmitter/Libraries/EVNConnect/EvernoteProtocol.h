//
//  EvernoteProtocol.h
//  EVNConnect
//
//  Created by Kentaro ISHITOYA on 12/02/03.
//  Copyright (c) 2012 Kentaro ISHITOYA. All rights reserved.
//

#import <Foundation/Foundation.h>

/*!
 * endpoint urls
 */
static NSString *kEvernoteBaseURL = @"http://www.evernote.com/edam/";
static NSString *kEvernoteOAuthRequestURL = @"https://www.evernote.com/oauth";
static NSString *kEvernoteOAuthAuthenticationURL = @"https://www.evernote.com/OAuth.action";

/*!
 * sandbox endpoint urls
 */
static NSString *kEvernoteSandboxBaseURL = @"http://sandbox.evernote.com/edam/";
static NSString *kEvernoteOAuthSandboxRequestURL = @"https://sandbox.evernote.com/oauth";
static NSString *kEvernoteOAuthSandboxAuthenticationURL = @"https://sandbox.evernote.com/OAuth.action";

/*!
 * credential keys
 */
static NSString *kEvernoteAuthToken = @"evernoteAuthToken";
static NSString *kEvernoteUserId = @"evernoteUserId";
static NSString *kEvernoteShardId = @"evernoteShardId";

@class EvernoteRequest;
@class EvernoteHTTPClient;
@class EDAMNoteStoreClient;
@class EDAMUserStoreClient;
@class EvernoteNoteStoreClient;
@class EvernoteUserStoreClient;

/*!
 * enum for consumer engine
 */
typedef enum {
    EvernoteAuthTypeOAuthConsumer,
    EvernoteAuthTypeMPOAuth
} EvernoteAuthType;

/*!
 * delegate for consumer engine
 */
@protocol EvernoteAuthDelegate <NSObject>
- (void)evernoteDidLogin;
- (void)evernoteDidNotLogin;
- (void)evernoteDidLogout;
@end

@protocol EvernoteHTTPClientDelegate <NSObject>
- (void)clientLoading:(EvernoteHTTPClient*)client;
- (void)client:(EvernoteHTTPClient*)client didReceiveResponse:(NSURLResponse*)response;
- (void)client:(EvernoteHTTPClient*)client didFailWithError:(NSError*)error;
- (void)client:(EvernoteHTTPClient*)client didFailWithException:(NSException*)exception;
- (void)client:(EvernoteHTTPClient*)client didLoad:(id)result;
- (void)client:(EvernoteHTTPClient*)client didLoadRawResponse:(NSData*)data;
- (void)client:(EvernoteHTTPClient*)client didSendBodyData:(NSInteger)bytesWritten totalBytesWritten:(NSInteger)totalBytesWritten totalBytesExpectedToWrite:(NSInteger)totalBytesExpectedToWrite;
@end

/*!
 * delegate for create EDAMNoteStore
 */
@protocol EvernoteStoreClientFactoryDelegate <NSObject>
- (EDAMNoteStoreClient *)createSynchronousNoteStoreClient;
- (EvernoteNoteStoreClient *)createAsynchronousNoteStoreClientWithDelegate:(id<EvernoteHTTPClientDelegate>)delegate;
- (EDAMUserStoreClient *)createSynchronousUserStoreClient;
- (EvernoteUserStoreClient *)createAsynchronousUserStoreClientWithDelegate:(id<EvernoteHTTPClientDelegate>)delegate;
@end

/*!
 * delegate for evernote request
 */
@protocol EvernoteRequestDelegate <NSObject>
@optional
- (void)requestLoading:(EvernoteRequest*)request;
- (void)request:(EvernoteRequest*)request didReceiveResponse:(NSURLResponse*)response;
- (void)request:(EvernoteRequest*)request didFailWithError:(NSError*)error;
- (void)request:(EvernoteRequest*)request didFailWithException:(NSException*)exception;
- (void)request:(EvernoteRequest*)request didLoad:(id)result;
- (void)request:(EvernoteRequest*)request didLoadRawResponse:(NSData*)data;
- (void)request:(EvernoteRequest*)request didSendBodyData:(NSInteger)bytesWritten totalBytesWritten:(NSInteger)totalBytesWritten totalBytesExpectedToWrite:(NSInteger)totalBytesExpectedToWrite;
@end

/*!
 * protocol for consumer engine
 */
@protocol EvernoteAuthProtocol <NSObject>
- (id)initWithConsumerKey:(NSString*)consumerKey
           consumerSecret:(NSString*)consumerSecret
           callbackScheme:(NSString*)callbackScheme
               useSandBox:(BOOL)useSandBox
              andDelegate:(id<EvernoteAuthDelegate>)delegate;
- (BOOL)handleOpenURL:(NSURL *)url;
- (void)login;
- (void)logout;
- (BOOL)isSessionValid;
- (void)setAuthToken:(NSString *)authToken userId:(NSString *)userId andShardId:(NSString *)shardId;
- (void)clearCredential;

@property (nonatomic, readonly) NSString *shardId;
@property (nonatomic, readonly) NSString *userId;
@property (nonatomic, readonly) NSString *authToken;
@end
