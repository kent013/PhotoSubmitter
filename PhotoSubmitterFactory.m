//
//  PhotoSubmitterFactory.m
//  tottepost
//
//  Created by Kentaro ISHITOYA on 12/02/28.
//  Copyright (c) 2012 cocotomo. All rights reserved.
//

#if ! __has_feature(objc_arc)
#error This file must be compiled with ARC. Use -fobjc-arc flag (or convert project to ARC).
#endif

#import <objc/runtime.h>
#import <objc/message.h>
#import "PhotoSubmitterFactory.h"
#import "RegexKitLite.h"
#import "PhotoSubmitterAccount.h"

//-----------------------------------------------------------------------------
//Private Implementations
//-----------------------------------------------------------------------------
@interface PhotoSubmitterFactory(PrivateImplementation)
+ (id<PhotoSubmitterProtocol>)getSubmitterInstance:(PhotoSubmitterAccount *)account;
@end

#pragma mark - private implementations
@implementation PhotoSubmitterFactory(PrivateImplementation)
/*!
 * load classes
 */
+ (id<PhotoSubmitterProtocol>)getSubmitterInstance:(PhotoSubmitterAccount *)account{
    static NSMutableDictionary *loadedClasses;
    if(loadedClasses == nil){
        loadedClasses = [[NSMutableDictionary alloc] init];
        int numClasses;
        Class *classes = NULL;
        
        classes = NULL;
        numClasses = objc_getClassList(NULL, 0);
        
        if (numClasses > 0 )
        {
            classes = (__unsafe_unretained Class *)malloc(sizeof(Class) * numClasses);
            numClasses = objc_getClassList(classes, numClasses);
            for (int i = 0; i < numClasses; i++) {
                Class cls = classes[i];
                NSString *className = [NSString stringWithUTF8String:class_getName(cls)];
                if([className isMatchedByRegex:@"PhotoSubmitter$"]){
                    [loadedClasses setObject:className forKey:className];
                }
            }
            free(classes);
        }
    }
    
    NSString *className = [loadedClasses objectForKey:account.type];
    if(className == nil){
        return nil;
    }
    return [[NSClassFromString(className) alloc] initWithAccount:account];
}
@end

//-----------------------------------------------------------------------------
//Public Implementations
//-----------------------------------------------------------------------------
#pragma mark - public implementations
@implementation PhotoSubmitterFactory
/*!
 * create submitter
 */
+ (id<PhotoSubmitterProtocol>)createWithAccount:(PhotoSubmitterAccount *)account{
    return [self getSubmitterInstance:account];
}
@end
