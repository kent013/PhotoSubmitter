//
//  MappingManager.m
//  DemoApp
//
//  Created by Chris Seymour on 7/10/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "SFMappingManager.h"

#import "SFAuthContext.h"

#import "SFPhoto.h"
#import "SFAddress.h"
#import "SFUser.h"
#import "SFFeedItem.h"
#import "SFNewsFeedPage.h"
#import "SFUserFeedPage.h"
#import "SFMessageSegment.h"

#define RESTKIT_DEBUG 1

@implementation SFMappingManager

+ (void)initMappings {	
	// Set-up the RestKit manager.
	RKObjectManager* manager = [RKObjectManager objectManagerWithBaseURL:[[SFAuthContext context] instanceUrl]];
	[RKObjectManager setSharedManager:manager];

	// Initialize mappings. Dependencies first.
	[SFPhoto setupMapping:manager];
	[SFAddress setupMapping:manager];
	[SFUserSummary setupMapping:manager];
	[SFUser setupMapping:manager];
	[SFMessageSegment setupMapping:manager];
	[SFFeedBody setupMapping:manager];
	[SFFeedItem setupMapping:manager];
	[SFNewsFeedPage setupMapping:manager];
	[SFUserFeedPage setupMapping:manager];

	// RestKit logging.
    if(RESTKIT_DEBUG){
        RKLogConfigureByName("RestKit", RKLogLevelDebug);
        RKLogConfigureByName("RestKit/Network", RKLogLevelDebug);
        RKLogConfigureByName("RestKit/ObjectMapping", RKLogLevelDebug);
        RKLogConfigureByName("RestKit/Network/Queue", RKLogLevelDebug);
    }
}

+ (void)initialize
{
    static BOOL initialized = NO;
	if (initialized) {
		// Reset the base URL.
		[RKObjectManager sharedManager].client.baseURL = [RKURL URLWithBaseURL:[[SFAuthContext context] instanceUrl]];
	} else {
		// Initialize the mappings.
		[SFMappingManager initMappings];
		
        initialized = YES;
    }
}

@end
