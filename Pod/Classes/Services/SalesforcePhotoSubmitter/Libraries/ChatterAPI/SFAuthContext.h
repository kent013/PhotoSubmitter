//
//  AuthContext.h
//  DemoApp
//
//  Created by Chris Seymour on 7/10/11.
//  Copyright 2011 cocotomo. All rights reserved.
//

#import "RestKit/RestKit.h"
#import "SFIdentity.h"
#import "SFLoginSuccess.h"
#import "SFObjectFetcher.h"

@protocol SFAccessTokenRefreshDelegate<NSObject>
- (void)refreshCompleted;
@optional
- (void)loginCompleted;
- (void)loginCompletedWithError:(NSError *)error;
@end


@interface SFAuthContext : NSObject<RKObjectLoaderDelegate> {
	NSString* accessToken;
	NSString* refreshToken;
	NSURL* instanceUrl;
	
	NSString* userId;
	
	RKObjectManager* restManager;
	RKObjectManager* identityManager;
	SFObjectFetcher* identityFetcher;
	SFLoginSuccess* loginSuccess;
	SFIdentity* identity;
	NSObject<SFAccessTokenRefreshDelegate>* delegate;
	
	BOOL loggedIn;
}

+ (SFAuthContext*)context;
+ (NSURL*)fullLoginUrl;

- (BOOL)startGettingAccessTokenWithDelegate:(id<SFAccessTokenRefreshDelegate>)delegateIn;
- (void)clear;
- (void)save;
- (void)load;
- (NSString*)getOAuthHeaderValue;
- (void)addOAuthHeader:(RKRequest*)request;
- (void)addOAuthHeaderToNSRequest:(NSMutableURLRequest*)request;
- (void)processCallbackUrl:(NSURL*)callbackUrl;

- (NSString*)userId;
- (void)setUserId:(NSString*)value;

@property(nonatomic, retain) NSString* accessToken;
@property(nonatomic, retain) NSString* refreshToken;
@property(nonatomic, retain) NSURL* instanceUrl;
@property(nonatomic, retain) SFIdentity* identity;
@property(nonatomic, assign) NSObject<SFAccessTokenRefreshDelegate>* delegate;

@end
