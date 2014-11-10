//
//  ENGImageUtil.m
//
//  Created by Kentaro ISHITOYA on 14/11/10.
//

#import "ENGImageLoader.h"

//-----------------------------------------------------------------------------
//Private Implementations
//-----------------------------------------------------------------------------
@interface ENGImageLoader(PrivateImplementation)
@end

@implementation ENGImageLoader(PrivateImplementation)
@end

//-----------------------------------------------------------------------------
//Public Implementations
//-----------------------------------------------------------------------------
@implementation ENGImageLoader

+ (UIImage *) loadImageNamed:(NSString *)name{
    return [ENGImageLoader loadImageNamed:name fromBundle:nil];
}

+ (UIImage *) loadImageNamed:(NSString *)name fromBundle:(NSString *)bundleName{
    if(bundleName == nil){
        bundleName = @"ENGPhotoSubmitter";
    }else{
        bundleName = [NSString stringWithFormat:@"ENGPhotoSubmitter-%@", bundleName];
    }
    return [UIImage imageNamed:[NSString stringWithFormat:@"%@.bundle/%@", bundleName, name]];
}
@end
