//
//  ENGPhotoSubmitterImageEntity.h
//
//  Created by ISHITOYA Kentaro on 12/01/22.
//

#import <Foundation/Foundation.h>
#import <CoreLocation/CoreLocation.h>
#import "ENGPhotoSubmitterContentEntity.h"

@interface ENGPhotoSubmitterImageEntity : ENGPhotoSubmitterContentEntity {
    __strong NSData *autoRotatedData_;
    __strong UIImage *image_;
    __strong NSMutableDictionary *resizedImages_;
    __strong NSMutableDictionary *preservedMetadata_;
    __strong UIImage *imageForPreview_;
    CGRect squareCropRect_;
}
@property (readonly, nonatomic) NSMutableDictionary *metadata;
@property (readonly, nonatomic) UIImage *image;
@property (assign, nonatomic) CGRect squareCropRect;

- (id) initWithImage:(UIImage *)image;
- (void) preprocess;
- (UIImage *) resizedImage: (CGSize) size;
- (UIImage *) squareImage: (CGSize) size;
- (UIImage *) imageForPreviewWithOrientation: (UIDeviceOrientation) orientation;
- (NSData *) squareData: (CGSize) size;
- (NSData *) autoRotatedData;
@end
