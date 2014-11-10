//
//  ENGMetaMovicsAuth.m
//  ENGMetaMovicsAuth
//
//  Created by Kentaro ISHITOYA on 12/02/03.
//

#import <Foundation/Foundation.h>
#import "ENGMetaMovicsProtocol.h"
#import "ENGMetaMovicsRequest.h"

@protocol ENGMetaMovicsAuthDelegate;

/*!
 * metamovics auth object
 */
@interface ENGMetaMovicsAuth : NSObject<ENGMetaMovicsRequestDelegate>{
  @protected
    __strong NSString *username_;
    __strong NSString *password_;
    __strong NSString *token_;
    
    id<ENGMetaMovicsAuthDelegate> delegate_;
}

@property (strong, nonatomic) NSString *token;

- (id)initWithUsername:(NSString *)username
              password:(NSString *)password
                 token:(NSString *)token
           andDelegate:(id<ENGMetaMovicsAuthDelegate>)delegate;
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
@protocol ENGMetaMovicsAuthDelegate <NSObject>
- (void)metamovicsDidLogin;
- (void)metamovicsDidNotLogin;
- (void)metamovicsDidLogout;
@end