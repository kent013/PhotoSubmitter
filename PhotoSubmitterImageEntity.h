//
//  PhotoSubmitterImageEntity.h
//  tottepost
//
//  Created by ISHITOYA Kentaro on 12/01/22.
//  Copyright (c) 2012 cocotomo. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreLocation/CoreLocation.h>
#import "PhotoSubmitterContentEntity.h"

@interface PhotoSubmitterImageEntity : PhotoSubmitterContentEntity {
    __strong NSData *autoRotatedData_;
    __strong UIImage *image_;
    __strong NSMutableDictionary *resizedImages_;
    __strong NSMutableDictionary *preservedMetadata_;
}
@property (readonly, nonatomic) NSMutableDictionary *metadata;
@property (readonly, nonatomic) UIImage *image;

- (id) initWithImage:(UIImage *)image;
- (void) preprocess;
- (UIImage *) resizedImage: (CGSize) size;
- (NSData *) autoRotatedData;
@end
