//
//  Identity.h
//  DemoApp
//
//  Created by Chris Seymour on 9/23/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "RestKit.h"

@interface SFIdentity : NSObject {
	NSString* user_id;
	NSString* organization_id;
	NSString* username;
	NSString* nick_name;
	NSString* display_name;
	NSString* email;
	NSString* user_type;
	NSString* language;
	NSString* locale;
	BOOL active;
}

+(RKObjectMapping*)getMapping;

@property(nonatomic, retain) NSString* user_id;
@property(nonatomic, retain) NSString* organization_id;
@property(nonatomic, retain) NSString* username;
@property(nonatomic, retain) NSString* nick_name;
@property(nonatomic, retain) NSString* display_name;
@property(nonatomic, retain) NSString* email;
@property(nonatomic, retain) NSString* user_type;
@property(nonatomic, retain) NSString* language;
@property(nonatomic, retain) NSString* locale;
@property(readonly) BOOL active;

@end
