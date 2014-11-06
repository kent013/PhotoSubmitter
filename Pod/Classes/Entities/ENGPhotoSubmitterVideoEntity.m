//
//  ENGPhotoSubmitterVideoEntity.m
//
//  Created by Kentaro ISHITOYA on 12/03/16.
//

#import "ENGPhotoSubmitterVideoEntity.h"

//-----------------------------------------------------------------------------
//Private Implementations
//-----------------------------------------------------------------------------
@interface ENGPhotoSubmitterVideoEntity(PrivateImplementatio)
@end

@implementation ENGPhotoSubmitterVideoEntity(PrivateImplementation)
@end

//-----------------------------------------------------------------------------
//Public Implementations
//----------------------------------------------------------------------------
@implementation ENGPhotoSubmitterVideoEntity
@synthesize url = url_;
/*!
 * init with url
 */
- (id)initWithUrl:(NSURL *)url{
    self = [super init];
    if(self){
        url_ = url;
        path_ = [url_ path];
        data_ = [NSData dataWithContentsOfURL:url];
    }
    return self;
}

/*!
 * type
 */
- (ENGPhotoSubmitterContentType)type{
    return ENGPhotoSubmitterContentTypeVideo;
}
@end