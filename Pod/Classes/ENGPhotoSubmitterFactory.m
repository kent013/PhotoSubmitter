//
//  ENGPhotoSubmitterFactory.m
//
//  Created by Kentaro ISHITOYA on 12/02/28.
//

#import <objc/runtime.h>
#import <objc/message.h>
#import "RegexKitLite.h"
#import "ENGPhotoSubmitterFactory.h"
#import "ENGPhotoSubmitterAccount.h"

//-----------------------------------------------------------------------------
//Private Implementations
//-----------------------------------------------------------------------------
@interface ENGPhotoSubmitterFactory(PrivateImplementation)
+ (id<ENGPhotoSubmitterProtocol>)getSubmitterInstance:(ENGPhotoSubmitterAccount *)account;
@end

#pragma mark - private implementations
@implementation ENGPhotoSubmitterFactory(PrivateImplementation)
/*!
 * load classes
 */
+ (id<ENGPhotoSubmitterProtocol>)getSubmitterInstance:(ENGPhotoSubmitterAccount *)account{
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
@implementation ENGPhotoSubmitterFactory
/*!
 * create submitter
 */
+ (id<ENGPhotoSubmitterProtocol>)createWithAccount:(ENGPhotoSubmitterAccount *)account{
    return [self getSubmitterInstance:account];
}
@end
