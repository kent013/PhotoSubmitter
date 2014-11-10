//
//  ENGImageUtil.h
//
//  Created by Kentaro ISHITOYA on 14/11/10.
//

#import <Foundation/Foundation.h>

@interface ENGImageLoader : NSObject{
}

+ (UIImage *) loadImageNamed:(NSString *)name;
+ (UIImage *) loadImageNamed:(NSString *)name fromBundle:(NSString *)bundle;
@end
