//
//  UIImage+ENGDigest.m
//
//  Created by ISHITOYA Kentaro on 10/08/26.
//

#import "UIImage+ENGDigest.h"
#import "NSData+ENGDigest.h"
#import "CommonCrypto/CommonDigest.h"

@implementation UIImage (ENGDigest)

//calcurate MD5 digest
- (NSString *)MD5DigestString
{
    NSData* pngData = [[NSData alloc] initWithData:UIImagePNGRepresentation(self)];
    return [pngData MD5DigestString];
}

@end