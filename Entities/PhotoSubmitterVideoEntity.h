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
}

@property NSURL *url;
-(id)initWithUrl:(NSURL *)url;
@end
