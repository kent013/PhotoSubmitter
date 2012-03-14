//
//  NSString+Dropbox.m
//  DropboxSDK
//
//  Created by Brian Smith on 7/19/10.
//  Copyright 2010 Dropbox, Inc. All rights reserved.
//

#if __has_feature(objc_arc)
#error This file must be compiled with Non-ARC. use -fno-objc_arc flag (or convert project to Non-ARC)
#endif

#import "NSString+Dropbox.h"

#import "DBDefines.h"


@implementation NSString (Dropbox)

- (NSString*)normalizedDropboxPath {
    if ([self isEqual:@"/"]) return @"";
    return [[self lowercaseString] precomposedStringWithCanonicalMapping];
}

- (BOOL)isEqualToDropboxPath:(NSString*)otherPath {
    return [[self normalizedDropboxPath] isEqualToString:[otherPath normalizedDropboxPath]];
}

@end

DB_FIX_CATEGORY_BUG(NSString_Dropbox)
