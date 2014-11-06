//
//  MetaMovicsConnect.h
//  MetaMovicsConnect
//
//  Created by Kentaro ISHITOYA on 12/02/21.
//  Copyright (c) 2012 Kentaro ISHITOYA. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "MetaMovicsProtocol.h"
#import "MetaMovicsAuth.h"
#import "MetaMovicsRequest.h"

@interface MetaMovicsConnect : NSObject<MetaMovicsAuthDelegate>{
    __strong NSMutableSet *requests_;
    __strong MetaMovicsAuth *auth_;
    __weak id<MetaMovicsSessionDelegate> sessionDelegate_;
}

@property(nonatomic, weak) id<MetaMovicsSessionDelegate> sessionDelegate;
@property(readonly) NSString* token;

#pragma mark - authentication
- (id)initWithUsername:(NSString *)username
              password:(NSString *)password
                 token:(NSString *)token
           andDelegate:(id<MetaMovicsSessionDelegate>)delegate;
- (void)loginWithUsername:(NSString *)username 
                 password:(NSString *)password 
            andPermission:(NSArray *)permission;
- (void)logout;
- (BOOL)isSessionValid;
- (void)refreshCredentialWithUsername:(NSString *)username 
                             password:(NSString *)password 
                        andPermission:(NSArray *)permission;

#pragma mark - get upload session token
- (MetaMovicsRequest *) getUploadSessionTokenWithDelegate:(id<MetaMovicsRequestDelegate>)delegate;

#pragma mark - file
- (MetaMovicsRequest *)uploadVideoFileWithSessionId:(NSString *)sessionId
                                           duration:(int) duration
                                              width:(int) width
                                             height:(int) height
                                               data:(NSData *)data
                                        andDelegate:(id<MetaMovicsRequestDelegate>)delegate;

- (MetaMovicsRequest *)createPageWithVideoId:(NSString *)videoId
                                   categoryId:(NSString *)categoryId
                                      caption:(NSString *)caption
                                  andDelegate:(id<MetaMovicsRequestDelegate>)delegate;
@end
