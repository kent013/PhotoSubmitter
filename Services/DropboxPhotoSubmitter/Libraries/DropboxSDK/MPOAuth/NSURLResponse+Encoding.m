//
//  NSURL+MPEncodingAdditions.m
//  MPOAuthConnection
//
//  Created by Karl Adam on 08.12.05.
//  Copyright 2008 matrixPointer. All rights reserved.
//

#if __has_feature(objc_arc)
#error This file must be compiled with Non-ARC. use -fno-objc_arc flag (or convert project to Non-ARC)
#endif

#import "NSURLResponse+Encoding.h"

#import "DBDefines.h"


@implementation NSURLResponse (EncodingAdditions)

- (NSStringEncoding)encoding {
	NSStringEncoding encoding = NSUTF8StringEncoding;
	
	if ([self textEncodingName]) {
		CFStringEncoding cfStringEncoding = CFStringConvertIANACharSetNameToEncoding((CFStringRef)[self textEncodingName]);
		if (cfStringEncoding != kCFStringEncodingInvalidId) {
			encoding = CFStringConvertEncodingToNSStringEncoding(cfStringEncoding); 
		}
	}
	
	return encoding;
}

@end

DB_FIX_CATEGORY_BUG(NSURLResponse_Encoding)
