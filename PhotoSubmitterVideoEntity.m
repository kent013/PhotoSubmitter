//
//  PhotoSubmitterVideoEntity.m
//  tottepost
//
//  Created by Kentaro ISHITOYA on 12/03/16.
//  Copyright (c) 2012 cocotomo. All rights reserved.
//

#import "PhotoSubmitterVideoEntity.h"

//-----------------------------------------------------------------------------
//Private Implementations
//-----------------------------------------------------------------------------
@interface PhotoSubmitterVideoEntity(PrivateImplementatio)
@end

@implementation PhotoSubmitterVideoEntity(PrivateImplementation)
@end

//-----------------------------------------------------------------------------
//Public Implementations
//----------------------------------------------------------------------------
@implementation PhotoSubmitterVideoEntity
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
- (PhotoSubmitterContentType)type{
    return PhotoSubmitterContentTypeVideo;
}
@end