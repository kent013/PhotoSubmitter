//
//  AuthContext.m
//  DemoApp
//
//  Created by Chris Seymour on 7/10/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "SFAuthContext.h"
#import "SFConfig.h"
#import "SFRefreshToken.h"

@implementation SFAuthContext

static SFAuthContext* contextSingleton;

static const NSString* keychainIdentifier = @"com.salesforce.PhotoPoster.AuthKeychain";

@synthesize accessToken;
@synthesize refreshToken;
@synthesize instanceUrl;
@synthesize identity;
@synthesize delegate;

+ (void)initialize
{
    static BOOL initialized = NO;
    if (!initialized)
    {
        initialized = YES;
        contextSingleton = [[SFAuthContext alloc] init];
    }
}

+ (SFAuthContext*)context {
	return contextSingleton;
}

// Keychain code based on:
// http://developer.apple.com/library/mac/#documentation/Security/Conceptual/keychainServConcepts/iPhoneTasks/iPhoneTasks.html
// See also:
// http://developer.apple.com/library/mac/#documentation/Security/Conceptual/keychainServConcepts/02concepts/concepts.html

- (id)init {
	self = [super init];
	if (self != nil) {
		restManager = [[RKObjectManager objectManagerWithBaseURL:[SFConfig loginServer]] retain];
		
		// Load the refresh token from the keychain, or initialize the keychain.
		[self load];
		
		loggedIn = FALSE;
	}
	return self;
}

+ (NSMutableDictionary*)createKeychainDict {
	NSMutableDictionary* keychainFetcher = [[NSMutableDictionary alloc] init];
	[keychainFetcher setObject:(id)kSecClassGenericPassword
						forKey:(id)kSecClass];
	[keychainFetcher setObject:keychainIdentifier forKey:(id)kSecAttrGeneric];
	[keychainFetcher setObject:keychainIdentifier forKey:(id)kSecAttrAccount];
	
	return [keychainFetcher autorelease];
}

- (BOOL)startGettingAccessTokenWithDelegate:(id<SFAccessTokenRefreshDelegate>)delegateIn {
	if (self.refreshToken == nil) {
		// We need the user to log-in.
		return FALSE;
	}
	
	self.delegate = delegateIn;
    
    SFRefreshToken *token = [[SFRefreshToken alloc] init];
    token.client_id = [SFConfig consumerKey];
    token.refresh_token = self.refreshToken;
    token.grant_type = @"refresh_token";
	
	// Reset the login success.
	[loginSuccess release];
	loginSuccess = [[SFLoginSuccess alloc] init];
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated"
	RKObjectLoader* loader = [RKObjectLoader loaderWithResourcePath:[SFConfig tokenUrlPath] objectManager:restManager delegate:self];
#pragma clang diagnostic pop
	loader.method = RKRequestMethodPOST;
	loader.sourceObject = token;
	loader.targetObject = loginSuccess;
    loader.serializationMapping = [SFRefreshToken getMapping];
    loader.serializationMIMEType = RKMIMETypeFormURLEncoded;
	loader.objectMapping = [SFLoginSuccess getMapping];
	[loader send];
    [token release];
	
	return TRUE;
}

- (void)load {
	// Set up the keychain search dictionary:
	NSMutableDictionary* keychainFetcher = [SFAuthContext createKeychainDict];
	[keychainFetcher setObject:(id)kSecMatchLimitOne forKey:(id)kSecMatchLimit];
	[keychainFetcher setObject:(id)kCFBooleanTrue forKey:(id)kSecReturnData];
	
	NSData* refreshTokenData = nil;
	OSStatus keychainErr = SecItemCopyMatching((CFDictionaryRef)keychainFetcher, (CFTypeRef*)&refreshTokenData);
	if (keychainErr == noErr) {
		// Convert refresh token to a String.
		if ([refreshTokenData length] > 0) {
			self.refreshToken = [[[NSString alloc] initWithData:refreshTokenData encoding:NSUTF8StringEncoding] autorelease];
		} else {
			self.refreshToken = nil;
		}
	} else if (keychainErr == errSecItemNotFound) {
		// Could not find keychain, initialize it.		
		NSMutableDictionary* keychainCreator = [SFAuthContext createKeychainDict];
		[keychainCreator setObject:[NSData data] forKey:(id)kSecValueData]; // Refresh token
		
		keychainErr = SecItemAdd((CFDictionaryRef)keychainCreator, NULL);
		if (noErr != keychainErr) {
			NSLog(@"Error trying to create keychain: %@", keychainErr);
		}
	} else {
		NSLog(@"Error retrieving refresh token from keychain: %@", keychainErr);
	}
	
	[refreshTokenData release];
}

- (void)save {
	// Update the refresh token value in the existing keychain item.
	NSMutableDictionary* updateDict = [SFAuthContext createKeychainDict];
	[updateDict removeObjectForKey:(id)kSecClass];
	
	if (self.refreshToken == nil) {
		//[updateDict setObject:[NSData data] forKey:(id)kSecValueData];
        return;
	} else {
		NSData* refreshTokenData = [self.refreshToken dataUsingEncoding:NSUTF8StringEncoding];
		[updateDict setObject:refreshTokenData forKey:(id)kSecValueData];
	}
	
	NSMutableDictionary* keychainDict = [SFAuthContext createKeychainDict];
	OSStatus err = SecItemUpdate((CFDictionaryRef)keychainDict, (CFDictionaryRef)updateDict);
	if (err != errSecSuccess) {
		NSLog(@"Error updating keychain: %@", err);
	}
}

- (void)clear {
	self.refreshToken = nil;
	self.instanceUrl = nil;
	self.accessToken = nil;
	
	loggedIn = FALSE;
	
	[self save];
}

+ (NSURL*)fullLoginUrl {
	// URL-encode the callback URL.
	NSString* encodedCallbackUrl = [[SFConfig callbackUrl] stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
	// Construct the URL for the first login page.
	return [NSURL URLWithString:[NSString stringWithFormat:
								 @"%@?response_type=token&client_id=%@&redirect_uri=%@",
								 [SFConfig authorizeUrl], [SFConfig consumerKey], encodedCallbackUrl]];
}

+ (NSString*)extractParameterValue:(NSString*)parameter
							  from:(NSString*)source {
	NSError* error = nil;
	NSString* pattern = [NSString stringWithFormat:@"%@=([%%.\\w\\d-]*)", parameter];
	
	NSRegularExpression* regex = [NSRegularExpression regularExpressionWithPattern:pattern options:0 error:&error];
	NSTextCheckingResult* result = [regex firstMatchInString:source options:0 range:NSMakeRange(0, [source length])];		
	if ([result numberOfRanges] > 1) {
		NSRange tokenRange = [result rangeAtIndex:1];
		NSString* encodedValue = [source substringWithRange:tokenRange];
		return [encodedValue stringByReplacingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
	} else {
		// TODO: Better error handling.
		NSLog(@"Could not find parameter %@", parameter);
		return nil;
	}
}

- (void)retrieveIdentity:(NSString*)identityUrl {
	self.identity = [[SFIdentity alloc] init];
	
	[identityManager release];
	identityManager = [[RKObjectManager objectManagerWithBaseURL:self.instanceUrl] retain];
    
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated"
	RKObjectLoader* identityLoader = [RKObjectLoader loaderWithResourcePath:identityUrl objectManager:identityManager delegate:self];
#pragma clang diagnostic pop
	identityLoader.method = RKRequestMethodGET;
	identityLoader.targetObject = self.identity;
	identityLoader.objectMapping = [SFIdentity getMapping];
	[self addOAuthHeader:identityLoader];	

	// TODO: Why does this try to use localhost? I explicitly told it NOT TO!
	[identityLoader send];
}

- (void)processCallbackUrl:(NSURL*)callbackUrl {
	// Extract tokens from callback url.
	
	// "fragment" gives the substring after the "#".
	NSString* fragment = [callbackUrl fragment];
	
	self.accessToken = [SFAuthContext extractParameterValue:@"access_token" from:fragment];
	self.refreshToken = [SFAuthContext extractParameterValue:@"refresh_token" from:fragment];
	self.instanceUrl = [NSURL URLWithString:[SFAuthContext extractParameterValue:@"instance_url" from:fragment]];
	
	[self save];
	
	if (self.refreshToken != nil) {
		loggedIn = TRUE;
	
		// Fetch the identity.
		NSString* identityUrl = [SFAuthContext extractParameterValue:@"id" from:fragment];
		[self retrieveIdentity:identityUrl];
	}
}

- (NSString*)getOAuthHeaderValue {
	return [NSString stringWithFormat:@"OAuth %@", [self accessToken]];
}

- (void)addOAuthHeader:(RKRequest*)request {
	NSMutableDictionary* headerDict = [[[NSMutableDictionary alloc] initWithCapacity:1] autorelease];
	[headerDict setObject:[self getOAuthHeaderValue] forKey:@"Authorization"];
	
	// Don't return entity encoded, HTML-safe strings.
	// Never do this for strings that will be embedded in web pages!!!
	[headerDict setObject:@"false" forKey:@"X-Chatter-Entity-Encoding"];
	
	[request setAdditionalHTTPHeaders:headerDict];
}

- (void)addOAuthHeaderToNSRequest:(NSMutableURLRequest*)request {
	[request addValue:[self getOAuthHeaderValue] forHTTPHeaderField:@"Authorization"];
	
	// Don't return entity encoded, HTML-safe strings.
	// Never do this for strings that will be embedded in web pages!!!
	[request addValue:@"false" forHTTPHeaderField:@"X-Chatter-Entity-Encoding"];
}

- (NSString*)userId {
	return userId;
}

- (void)setUserId:(NSString*)value {
	userId = value;
}

- (void)dealloc {
	[userId release];
	
	[accessToken release];
	[refreshToken release];
	[instanceUrl release];
	
	[restManager release];
	[identityManager release];
	[loginSuccess release];
	[identity release];
	[identityFetcher release];
	
	[super dealloc];
}

// RKObjectLoaderDelegate implementation
- (void)objectLoader:(RKObjectLoader *)objectLoader didLoadObjects:(NSArray *)objects {
	if (!loggedIn) {
		self.accessToken = loginSuccess.accessToken;
		if ([[SFConfig loginServer].absoluteString rangeOfString:@"login.salesforce.com"].location != NSNotFound) {
			// Production
			self.instanceUrl = loginSuccess.instanceUrl;
		} else {
			// Development
			self.instanceUrl = [SFConfig loginServer];
		}
		
		[self.delegate refreshCompleted];
		
		loggedIn = TRUE;
		
		// Retrieve identity.
		// Assuming this starts with [Config loginServer]...
		NSRange relativeStart = [loginSuccess.identityUrl.absoluteString rangeOfString:@"/id"];
		NSString* identityUrl = [loginSuccess.identityUrl.absoluteString substringFromIndex:relativeStart.location];
		[self retrieveIdentity:identityUrl];
	} else {
        [self.delegate loginCompleted];
		NSLog(@"Retrieved identity successfully. user id: %@", self.identity.user_id);
	}
}

- (void)objectLoaderDidLoadUnexpectedResponse:(RKObjectLoader *)objectLoader {
	[self.delegate loginCompletedWithError:nil];
}

- (void)objectLoader:(RKObjectLoader *)objectLoader didFailWithError:(NSError *)error {
	[self.delegate loginCompletedWithError:error];
}

@end

