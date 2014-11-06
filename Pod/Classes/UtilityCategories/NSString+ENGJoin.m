//
//  NSString+ENGJoin.m
//
//  Created by ISHITOYA Kentaro on 10/09/29.
//

#import "NSString+ENGJoin.h"


@implementation NSString(ENGJoin)
//文字列を連結
+ (NSString *) join:(NSArray *)array{
    return [NSString join: array glue:nil];
}

//文字列を連結
+ (NSString *) join:(NSArray *)array glue:(NSString *)glue{
    if(array == nil){
        return @"";
    }
    NSInteger count = [array count];
    if(count == 0){
        return @"";
    }else if(count == 1){
        if([[array objectAtIndex: 0] isKindOfClass: NSString.class] == NO){
            return @"";
        }
        return [array objectAtIndex: 0];
    }
    
    NSString *retval = @"";
    for(int i = 0; i < count; i++){
        id str = [array objectAtIndex: i];
        if([str isKindOfClass: NSString.class] == NO){
            continue;
        }
        
        retval = [retval stringByAppendingString: str];
        if(i == count - 1){
            continue;
        }
        if(glue != nil){
            retval = [retval stringByAppendingString: glue];
        }
    }
    return retval;
}
@end
