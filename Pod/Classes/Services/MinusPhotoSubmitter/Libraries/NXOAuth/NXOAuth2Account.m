//
//  NXOAuth2Account.m
//  OAuth2Client
//
//  Created by Tobias Kräntzer on 12.07.11.
//
//  Copyright 2011 nxtbgthng. All rights reserved.
//
//  Licenced under the new BSD-licence.
//  See README.md in this repository for 
//  the full licence.
//

#if __has_feature(objc_arc)
#error This file must be compiled with Non-ARC. use -fno-objc_arc flag (or convert project to Non-ARC)
#endif

#import "NSString+NXOAuth2.h"

#import "NXOAuth2ClientDelegate.h"
#import "NXOAuth2TrustDelegate.h"

#import "NXOAuth2Client.h"
#import "NXOAuth2AccountStore.h"

#import "NXOAuth2Account.h"


#pragma mark Notifications

NSString * const NXOAuth2AccountDidChangeUserDataNotification = @"NXOAuth2AccountDidChangeUserDataNotification";
NSString * const NXOAuth2AccountDidChangeAccessTokenNotification = @"NXOAuth2AccountDidChangeAccessTokenNotification";
NSString * const NXOAuth2AccountDidLoseAccessTokenNotification = @"NXOAuth2AccountDidLoseAccessTokenNotification";
NSString * const NXOAuth2AccountDidFailToGetAccessTokenNotification = @"NXOAuth2AccountDidFailToGetAccessTokenNotification";

#pragma mark -

@interface NXOAuth2Account () <NXOAuth2ClientDelegate, NXOAuth2TrustDelegate>
@end

#pragma mark -

@implementation NXOAuth2Account (Private)

- (id)initAccountWithOAuthClient:(NXOAuth2Client *)anOAuthClient accountType:(NSString *)anAccountType;
{
    self = [super init];
    if (self) {
        accountType = [anAccountType retain];
        oauthClient = [anOAuthClient retain];
        accessToken = [oauthClient.accessToken retain];
        oauthClient.delegate = self;
        identifier = [[NSString nxoauth2_stringWithUUID] retain];
    }
    return self;
}

@end

#pragma mark -

@implementation NXOAuth2Account

@synthesize accountType;
@synthesize identifier;
@synthesize userData;
@synthesize oauthClient;
@synthesize accessToken;


#pragma mark Lifecycle

- (void)dealloc;
{
    [accountType release];
    [oauthClient release];
    [accessToken release];
    [userData release];
    [identifier release];
    [super dealloc];
}


#pragma mark Accessors

- (NXOAuth2Client *)oauthClient;
{
    @synchronized (oauthClient) {
        if (oauthClient == nil) {
            NSDictionary *configuration = [[NXOAuth2AccountStore sharedStore] configurationForAccountType:self.accountType];
            
            NSString *clientID = [configuration objectForKey:kNXOAuth2AccountStoreConfigurationClientID];
            NSString *clientSecret = [configuration objectForKey:kNXOAuth2AccountStoreConfigurationSecret];
            NSURL *authorizeURL = [configuration objectForKey:kNXOAuth2AccountStoreConfigurationAuthorizeURL];
            NSURL *tokenURL = [configuration objectForKey:kNXOAuth2AccountStoreConfigurationTokenURL];
            
            oauthClient = [[NXOAuth2Client alloc] initWithClientID:clientID
                                                      clientSecret:clientSecret
                                                      authorizeURL:authorizeURL
                                                          tokenURL:tokenURL
                                                       accessToken:self.accessToken
                                                        persistent:NO
                                                          delegate:self];
        }
    }
    return oauthClient;
}

- (void)setUserData:(id<NSObject,NSCoding,NSCopying>)someUserData;
{
    if (userData != someUserData) {
        @synchronized (userData) {
            [userData release]; userData = [someUserData retain];
            [[NSNotificationCenter defaultCenter] postNotificationName:NXOAuth2AccountDidChangeUserDataNotification
                                                                object:self];
        }
    }
}

- (NSString *)description;
{
    return [NSString stringWithFormat:@"<NXOAuth2Account identifier:'%@' accountType:'%@' accessToken:%@ userData:%@>", self.identifier, self.accountType, self.accessToken, self.userData];
}


#pragma mark NXOAuth2TrustDelegate

-(NXOAuth2TrustMode)connection:(NXOAuth2Connection *)connection trustModeForHostname:(NSString *)hostname;
{
    NXOAuth2TrustModeHandler handler = [[NXOAuth2AccountStore sharedStore] trustModeHandlerForAccountType:self.accountType];
    if (handler) {
        return handler(connection, hostname);
    } else {
        return NXOAuth2TrustModeSystem;
    }
}

-(NSArray *)connection:(NXOAuth2Connection *)connection trustedCertificatesForHostname:(NSString *)hostname;
{
    NXOAuth2TrustedCertificatesHandler handler = [[NXOAuth2AccountStore sharedStore] trustedCertificatesHandlerForAccountType:self.accountType];
    return handler(hostname);
}


#pragma mark NXOAuth2ClientDelegate

- (void)oauthClientNeedsAuthentication:(NXOAuth2Client *)client;
{
    // This delegate method will never be called, because an account
    // contains only an authenticated oauch client.
}

- (void)oauthClientDidGetAccessToken:(NXOAuth2Client *)client;
{
    [accessToken release];
    accessToken = [oauthClient.accessToken retain];
    [[NSNotificationCenter defaultCenter] postNotificationName:NXOAuth2AccountDidChangeAccessTokenNotification
                                                        object:self];
}

- (void)oauthClientDidLoseAccessToken:(NXOAuth2Client *)client;
{
    [accessToken release];
    accessToken = nil;
    [[NSNotificationCenter defaultCenter] postNotificationName:NXOAuth2AccountDidLoseAccessTokenNotification
                                                        object:self];
}

- (void)oauthClientDidRefreshAccessToken:(NXOAuth2Client *)client;
{
    [accessToken release];
    accessToken = [oauthClient.accessToken retain];
    [[NSNotificationCenter defaultCenter] postNotificationName:NXOAuth2AccountDidChangeAccessTokenNotification
                                                        object:self];
}

- (void)oauthClient:(NXOAuth2Client *)client didFailToGetAccessTokenWithError:(NSError *)error;
{
    [accessToken release];
    accessToken = nil;
    NSDictionary *userInfo = [NSDictionary dictionaryWithObject:error
                                                         forKey:NXOAuth2AccountStoreErrorKey];
    [[NSNotificationCenter defaultCenter] postNotificationName:NXOAuth2AccountDidFailToGetAccessTokenNotification
                                                        object:self
                                                      userInfo:userInfo];
}


#pragma mark NSCoding

- (void)encodeWithCoder:(NSCoder *)aCoder
{
	[aCoder encodeObject:identifier forKey:@"identifier"];
    [aCoder encodeObject:accountType forKey:@"accountType"];
	[aCoder encodeObject:accessToken forKey:@"accessToken"];
    [aCoder encodeObject:userData forKey:@"userData"];
}

- (id)initWithCoder:(NSCoder *)aDecoder
{
	if (self = [super init]) {
        userData = [[aDecoder decodeObjectForKey:@"userData"] retain];
        accessToken = [[aDecoder decodeObjectForKey:@"accessToken"] retain];
		accountType = [[aDecoder decodeObjectForKey:@"accountType"] copy];
        identifier = [[aDecoder decodeObjectForKey:@"identifier"] copy];
	}
	return self;
}

@end
