//
//  MetaMovicsAuth.m
//  EVNConnect
//
//  Created by Kentaro ISHITOYA on 12/02/03.
//  Copyright (c) 2012 Kentaro ISHITOYA. All rights reserved.
//

#if ! __has_feature(objc_arc)
#error This file must be compiled with ARC. Use -fobjc-arc flag (or convert project to ARC).
#endif

#import "MetaMovicsAuth.h"
#import "MetaMovicsRequest.h"
#import "MetaMovicsProtocol.h"
#import "NSString+Join.h"

#import "MetaMovicsConstants.h"

//-----------------------------------------------------------------------------
//Private Implementations
//-----------------------------------------------------------------------------
@interface MetaMovicsAuth(PrivateImplementation)
-(void)requestAccessWithUsername:(NSString *)username andPassword:(NSString *)password;
@end

@implementation MetaMovicsAuth(PrivateImplementation)
/*!
 * request for access
 */
-(void)requestAccessWithUsername:(NSString *)username andPassword:(NSString *)password{
    NSString *baseUrl = [NSString stringWithFormat:@"%@/authenticate?name=%@&password=%@", kMetaMovicsBaseURL, username, password];
    NSMutableURLRequest* request =
    [NSMutableURLRequest requestWithURL:[NSURL URLWithString:baseUrl]
                            cachePolicy:NSURLRequestReloadIgnoringLocalCacheData
                        timeoutInterval:kTimeoutInterval];
    [request setValue:kUserAgent forHTTPHeaderField:@"User-Agent"];
    [request setHTTPMethod:kHTTPPOST];

    MetaMovicsRequest *r =
        [[MetaMovicsRequest alloc] initWithURLRequest:request andDelegate:self];
    [r start];
}
@end

//-----------------------------------------------------------------------------
//Public Implementations
//-----------------------------------------------------------------------------
#pragma mark - authentication
@implementation MetaMovicsAuth
@synthesize token = token_;

/*!
 * initialize
 */
- (id)initWithUsername:(NSString *)username password:(NSString *)password token:(NSString *)atoken andDelegate:(id<MetaMovicsAuthDelegate>)delegate{
    self = [super init];
    if (self) {
        delegate_ = delegate;
        username_ = username;
        password_ = password;
        if(atoken == nil){
            [self requestAccessWithUsername:username andPassword:password];
        }else{
            token_ = atoken;
        }
    }
    return self;
}

/*!
 * login to metamovics, obtain request token
 */
-(void)loginWithUsername:(NSString *)username andPassword:(NSString *)password{
    if([self isSessionValid]){
        [self metamovicsDidLogin];
        return;
    }
    [self requestAccessWithUsername:username andPassword:password];
}

/*!
 * logout
 */
- (void)logout {
    [self clearCredential];
    if ([delegate_ respondsToSelector:@selector(metamovicsDidLogout)]) {
        token_ = nil;
        [delegate_ metamovicsDidLogout];
    }
}

/*!
 * send did login message
 */
- (void)metamovicsDidLogin{
    if ([delegate_ respondsToSelector:@selector(metamovicsDidLogin)]) {
        [delegate_ metamovicsDidLogin];
    }
    
}

/*!
 * send did login message
 */
- (void)metamovicsDidLogout{
    if ([delegate_ respondsToSelector:@selector(metamovicsDidLogout)]) {
        [delegate_ metamovicsDidLogout];
    }
    
}

/*!
 * send did not login message
 */
- (void)metamovicsDidNotLogin{
    if ([delegate_ respondsToSelector:@selector(metamovicsDidNotLogin)]) {
        [delegate_ metamovicsDidNotLogin];
    }
}

#pragma mark - credentials
/*!
 * clear access token
 */
- (void)clearCredential{
    token_ = nil;
}

/*!
 * refresh credential
 */
- (void)refreshCredentialWithUsername:(NSString *)username andPassword:(NSString *)password{
    [self requestAccessWithUsername:username andPassword:password];
}
/*!
 * check is session valid
 */
- (BOOL)isSessionValid{
    return token_ != nil;
}


#pragma mark - PhotoSubmitterMetaMovicsRequestDelegate
/*!
 * did load
 */
- (void)request:(MetaMovicsRequest *)request didLoad:(id)result{
    if([[result objectForKey:@"result"] intValue] == 1){
        self.token = [result objectForKey:@"token"];
        [self metamovicsDidLogin];
    }else{
        [self metamovicsDidNotLogin];
        self.token = nil;
    }
}

/*!
 * request failed
 */
- (void)request:(MetaMovicsRequest *)request didFailWithError:(NSError *)error{
    [self metamovicsDidNotLogin];
}

/*!
 * progress
 */
- (void)request:(MetaMovicsRequest *)request didSendBodyData:(NSInteger)bytesWritten totalBytesWritten:(NSInteger)totalBytesWritten totalBytesExpectedToWrite:(NSInteger)totalBytesExpectedToWrite{
}
@end
