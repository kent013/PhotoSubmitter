//
//  MetaMovicsAuth.h
//  EVNConnect
//
//  Created by Kentaro ISHITOYA on 12/02/03.
//  Copyright (c) 2012 Kentaro ISHITOYA. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "MetaMovicsProtocol.h"
#import "MetaMovicsRequest.h"

@protocol MetaMovicsAuthDelegate;

/*!
 * metamovics auth object
 */
@interface MetaMovicsAuth : NSObject<MetaMovicsRequestDelegate>{
  @protected
    __strong NSString *username_;
    __strong NSString *password_;
    __strong NSString *token_;
    
    id<MetaMovicsAuthDelegate> delegate_;
}

@property (strong, nonatomic) NSString *token;

- (id)initWithUsername:(NSString *)username
              password:(NSString *)password
                 token:(NSString *)token
           andDelegate:(id<MetaMovicsAuthDelegate>)delegate;
- (void)loginWithUsername:(NSString *)username
              andPassword:(NSString *)password;
- (void)logout;
- (void)metamovicsDidLogin;
- (void)metamovicsDidLogout;
- (void)metamovicsDidNotLogin;
- (void)clearCredential;
- (void)refreshCredentialWithUsername:(NSString *)username
                             andPassword:(NSString *)password;
- (BOOL)isSessionValid;
@end

/*!
 * delegate for consumer engine
 */
@protocol MetaMovicsAuthDelegate <NSObject>
- (void)metamovicsDidLogin;
- (void)metamovicsDidNotLogin;
- (void)metamovicsDidLogout;
@end