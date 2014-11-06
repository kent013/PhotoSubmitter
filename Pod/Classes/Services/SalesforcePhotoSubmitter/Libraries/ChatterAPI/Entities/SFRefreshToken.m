//
//  SFRefreshToken.m
//  tottepost
//
//  Created by Kentaro ISHITOYA on 12/04/10.
//  Copyright (c) 2012 cocotomo. All rights reserved.
//

#import "SFRefreshToken.h"

@implementation SFRefreshToken
@synthesize client_id;
@synthesize refresh_token;
@synthesize grant_type;

+(RKObjectMapping*)getMapping {
	RKObjectMapping* mapping = [RKObjectMapping mappingForClass:[SFRefreshToken class]];
    
	[mapping mapAttributes:@"client_id", @"refresh_token", @"grant_type" , nil];
    //[mapping mapKeyPath:@"client_id" toAttribute:@"clientId"];
    //[mapping mapKeyPath:@"refresh_token" toAttribute:@"refreshToken"];
    //[mapping mapKeyPath:@"grant_type" toAttribute:@"grantType"];

	return mapping;
}

-(void)dealloc {
    [client_id release];
    [refresh_token release];
    [grant_type release];
	[super dealloc];
}
@end
