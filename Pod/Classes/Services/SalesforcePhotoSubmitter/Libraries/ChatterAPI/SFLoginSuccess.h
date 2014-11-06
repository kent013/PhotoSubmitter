//
//  LoginSuccess.h
//  DemoApp
//
//  Created by Chris Seymour on 7/11/11.
//  Copyright 2011 cocotomo. All rights reserved.
//

#import "RestKit/RestKit.h"

@interface SFLoginSuccess : NSObject {
	NSURL* instanceUrl;
	NSURL* identityUrl;
	NSString* signature;
	NSString* accessToken;
	NSString* issuedAt;
}

+(RKObjectMapping*)getMapping;

@property(nonatomic, retain) NSURL* instanceUrl;
@property(nonatomic, retain) NSURL* identityUrl;
@property(nonatomic, retain) NSString* signature;
@property(nonatomic, retain) NSString* accessToken;
@property(nonatomic, retain) NSString* issuedAt;

@end

