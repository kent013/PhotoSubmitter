//
//  PSLang.m
//  tottepost
//
//  Created by Kentaro ISHITOYA on 12/03/06.
//  Copyright (c) 2012 cocotomo. All rights reserved.
//

#if ! __has_feature(objc_arc)
#error This file must be compiled with ARC. Use -fobjc-arc flag (or convert project to ARC).
#endif

#import "PSLang.h"

@implementation PSLang
/*!
 * get localized string
 */
+ (NSString *)localized:(NSString *)key{
    return NSLocalizedStringFromTable(key, @"PhotoSubmitter", nil);
}
@end
