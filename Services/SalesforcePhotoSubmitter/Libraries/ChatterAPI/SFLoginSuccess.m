//
//  LoginSuccess.m
//  DemoApp
//
//  Created by Chris Seymour on 7/11/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "SFLoginSuccess.h"


@implementation SFLoginSuccess

@synthesize instanceUrl;
@synthesize identityUrl;
@synthesize signature;
@synthesize accessToken;
@synthesize issuedAt;

+(RKObjectMapping*)getMapping {
	// Don't register a route because this will use a different base URL than other data classes! It will
	// use the "login URL" not the "instance URL".
	
	RKObjectMapping* mapping = [RKObjectMapping mappingForClass:[SFLoginSuccess class]];
	[mapping mapAttributes:@"signature", nil];
	[mapping addAttributeMapping:[RKObjectAttributeMapping mappingFromKeyPath:@"instance_url" toKeyPath:@"instanceUrl"]];
	[mapping addAttributeMapping:[RKObjectAttributeMapping mappingFromKeyPath:@"id" toKeyPath:@"identityUrl"]];
	[mapping addAttributeMapping:[RKObjectAttributeMapping mappingFromKeyPath:@"access_token" toKeyPath:@"accessToken"]];
	[mapping addAttributeMapping:[RKObjectAttributeMapping mappingFromKeyPath:@"issued_at" toKeyPath:@"issuedAt"]];
	return mapping;
}

-(void)dealloc {
	[instanceUrl release];
	[identityUrl release];
	[signature release];
	[accessToken release];
	[issuedAt release];
	
	[super dealloc];
}

@end