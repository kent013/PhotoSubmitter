//
//  Config.h
//  DemoApp
//
//  Created by Chris Seymour on 7/13/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

@interface SFConfig : NSObject {
	
}

+(NSString*)consumerKey;
+(NSString*)callbackUrl;
+(NSURL*)loginServer;
+(NSString*)tokenUrl;
+(NSString*)tokenUrlPath;
+(NSString*)authorizeUrl;
+(NSString*)authorizeUrlPath;

+(NSString*)addVersionPrefix:(NSString*)url;
+(int)getVersion;

@end
