//
//  NSString+ENGJoin.h
//
//  Created by ISHITOYA Kentaro on 10/09/29.
//

#import <Foundation/Foundation.h>


@interface NSString (ENGJoin)
+ (NSString *) join: (NSArray *) array;
+ (NSString *) join: (NSArray *) array glue:(NSString *) glue;
@end
