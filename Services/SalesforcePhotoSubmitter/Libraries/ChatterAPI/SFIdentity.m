//
//  Identity.m
//  DemoApp
//
//  Created by Chris Seymour on 9/23/11.
//  Copyright 2011 cocotomo. All rights reserved.
//

#import "SFIdentity.h"


@implementation SFIdentity

@synthesize user_id;
@synthesize organization_id;
@synthesize username;
@synthesize nick_name;
@synthesize display_name;
@synthesize email;
@synthesize user_type;
@synthesize language;
@synthesize locale;
@synthesize active;

+(RKObjectMapping*)getMapping {
	// Don't register a route because this will use a different base URL than other data classes!
	
	RKObjectMapping* mapping = [RKObjectMapping mappingForClass:[SFIdentity class]];
	[mapping mapAttributes:@"user_id", @"organization_id", @"username", @"nick_name", @"display_name", @"email",
		@"user_type", @"language", @"locale", @"active", nil];
	return mapping;
}

-(void)dealloc {
	[user_id release];
	[organization_id release];
	[username release];
	[nick_name release];
	[display_name release];
	[email release];
	[user_type release];
	[language release];
	[locale release];
	
	[super dealloc];
}

@end