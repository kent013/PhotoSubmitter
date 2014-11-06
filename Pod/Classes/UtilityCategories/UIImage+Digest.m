//
//  UIImage+Digest.m
//  iSticky
//
//  Created by ISHITOYA Kentaro on 10/08/26.
//  Copyright 2010 cocotomo. All rights reserved.
//

#if ! __has_feature(objc_arc)
#error This file must be compiled with ARC. Use -fobjc-arc flag (or convert project to ARC).
#endif

#import "UIImage+Digest.h"
#import "NSData+Digest.h"
#import "CommonCrypto/CommonDigest.h"

@implementation UIImage (Digest)

//calcurate MD5 digest
- (NSString *)MD5DigestString
{
    NSData* pngData = [[NSData alloc] initWithData:UIImagePNGRepresentation(self)];
    return [pngData MD5DigestString];
}

@end