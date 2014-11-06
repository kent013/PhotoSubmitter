//
//  SFRefreshToken.h
//  tottepost
//
//  Created by Kentaro ISHITOYA on 12/04/10.
//  Copyright (c) 2012 cocotomo. All rights reserved.
//

#import "RestKit/RestKit.h"

@interface SFRefreshToken : NSObject
+(RKObjectMapping*)getMapping;

@property(nonatomic, retain) NSString* client_id;
@property(nonatomic, retain) NSString* refresh_token;
@property(nonatomic, retain) NSString* grant_type;
@end