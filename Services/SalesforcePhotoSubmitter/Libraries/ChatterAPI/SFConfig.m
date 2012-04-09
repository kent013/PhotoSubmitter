//
//  Config.m
//  DemoApp
//
//  Created by Chris Seymour on 7/13/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//  Modified to use constants.
//

#import "SFConfig.h"
#import "SalesforceAPIKey.h"

@implementation SFConfig

+(NSString*)getConfigString:(NSString*)name {
	NSString* value = (NSString*)[[NSBundle mainBundle] objectForInfoDictionaryKey:name];
	if ((value == nil) || ([value length] <= 0)) {
		NSLog(@"!!!!!!!YOU MUST SET THE %@ VALUE IN THE INFO PLIST FOR THIS APP TO RUN!!!!!!!!!", name);
		[NSThread exit];
	}
	return value;
}	

+(NSString*)consumerKey {
    return SALESFORCE_SUBMITTER_API_KEY;
    //return [Config getConfigString:@"PPConsumerKey"];
}

+(NSString*)callbackUrl {
    return SALESFORCE_SUBMITTER_API_CALLBACK;
    //return [Config getConfigString:@"PPCallbackUrl"];
}

+(NSURL*)loginServer {
    return [NSURL URLWithString:SALESFORCE_SUBMITTER_API_LOGIN_SERVER];
    //return [Config getConfigString:@"PPLoginServer"];
}

+(NSString*)authorizeUrlPath {
    return SALESFORCE_SUBMITTER_API_AUTHURL;
    //return [NSString stringWithFormat:@"%@%@", [Config loginServer], [Config getConfigString:@"PPAuthorizePath"]];
}

+(NSString*)authorizeUrl {
    return [NSString stringWithFormat:@"%@%@", [SFConfig loginServer], [SFConfig authorizeUrlPath]];
}

+(NSString*)tokenUrl {
    return [NSString stringWithFormat:@"%@%@", [SFConfig loginServer], [SFConfig tokenUrlPath]];
}

+(NSString*)tokenUrlPath {
    return SALESFORCE_SUBMITTER_API_TOKENURL;
	//return [Config getConfigString:@"PPTokenPath"];
}

+(NSString*)addVersionPrefix:(NSString*)url {
	return [NSString stringWithFormat:@"/services/data/v%i.0%@", [SFConfig getVersion], url];
}

+(int)getVersion {
    return SALESFORCE_SUBMITTER_API_VERSION;
    //return [[Config getConfigString:@"PPApiVersion"] intValue];
}

@end