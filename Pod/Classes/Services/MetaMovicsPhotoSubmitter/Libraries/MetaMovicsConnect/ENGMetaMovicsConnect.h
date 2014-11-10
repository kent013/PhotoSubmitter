//
//  ENGMetaMovicsConnect.h
//  ENGMetaMovicsConnect
//
//  Created by Kentaro ISHITOYA on 12/02/21.
//

#import <Foundation/Foundation.h>
#import "ENGMetaMovicsProtocol.h"
#import "ENGMetaMovicsAuth.h"
#import "ENGMetaMovicsRequest.h"

@interface ENGMetaMovicsConnect : NSObject<ENGMetaMovicsAuthDelegate>{
    __strong NSMutableSet *requests_;
    __strong ENGMetaMovicsAuth *auth_;
    __weak id<ENGMetaMovicsSessionDelegate> sessionDelegate_;
}

@property(nonatomic, weak) id<ENGMetaMovicsSessionDelegate> sessionDelegate;
@property(readonly) NSString* token;

#pragma mark - authentication
- (id)initWithUsername:(NSString *)username
              password:(NSString *)password
                 token:(NSString *)token
           andDelegate:(id<ENGMetaMovicsSessionDelegate>)delegate;
- (void)loginWithUsername:(NSString *)username 
                 password:(NSString *)password 
            andPermission:(NSArray *)permission;
- (void)logout;
- (BOOL)isSessionValid;
- (void)refreshCredentialWithUsername:(NSString *)username 
                             password:(NSString *)password 
                        andPermission:(NSArray *)permission;

#pragma mark - get upload session token
- (ENGMetaMovicsRequest *) getUploadSessionTokenWithDelegate:(id<ENGMetaMovicsRequestDelegate>)delegate;

#pragma mark - file
- (ENGMetaMovicsRequest *)uploadVideoFileWithSessionId:(NSString *)sessionId
                                           duration:(int) duration
                                              width:(int) width
                                             height:(int) height
                                               data:(NSData *)data
                                        andDelegate:(id<ENGMetaMovicsRequestDelegate>)delegate;

- (ENGMetaMovicsRequest *)createPageWithVideoId:(NSString *)videoId
                                   categoryId:(NSString *)categoryId
                                      caption:(NSString *)caption
                                  andDelegate:(id<ENGMetaMovicsRequestDelegate>)delegate;
@end
