//
//  PhotoSubmitterVideoEntity.h
//  tottepost
//
//  Created by Kentaro ISHITOYA on 12/03/16.
//  Copyright (c) 2012 cocotomo. All rights reserved.
//

#import "PhotoSubmitterContentEntity.h"

@interface PhotoSubmitterVideoEntity : PhotoSubmitterContentEntity{
    NSURL *url_;
    int length_;
    int width_;
    int height_;
}

@property NSURL *url;
@property int length;
@property int width;
@property int height;
-(id)initWithUrl:(NSURL *)url;
@end
