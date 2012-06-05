//
//  MPOAuthURLResponse.m
//  MPOAuthConnection
//
//  Created by Karl Adam on 08.12.05.
//  Copyright 2008 matrixPointer. All rights reserved.
//

#if __has_feature(objc_arc)
#error This file must be compiled with Non-ARC. use -fno-objc_arc flag (or convert project to Non-ARC)
#endif

#import "MPOAuthURLResponse.h"

@interface MPOAuthURLResponse ()
@property (nonatomic, readwrite, retain) NSURLResponse *urlResponse;
@property (nonatomic, readwrite, retain) NSDictionary *oauthParameters;
@end

@implementation MPOAuthURLResponse

- (id)init {
	if ((self = [super init])) {
		
	}
	return self;
}

- (oneway void)dealloc {
	self.urlResponse = nil;
	self.oauthParameters = nil;
	
	[super dealloc];
}

@synthesize urlResponse = _urlResponse;
@synthesize oauthParameters = _oauthParameters;

@end
