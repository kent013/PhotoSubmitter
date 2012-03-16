//
//  PhotoSubmitterImageEntity.m
//  tottepost
//
//  Created by ISHITOYA Kentaro on 12/01/22.
//  Copyright (c) 2012 cocotomo. All rights reserved.
//

#if ! __has_feature(objc_arc)
#error This file must be compiled with ARC. Use -fobjc-arc flag (or convert project to ARC).
#endif

#import <ImageIO/ImageIO.h>
#import "PhotoSubmitterImageEntity.h"
#import "NSData+Digest.h"
#import "UIImage+Resize.h"
#import "UIImage+AutoRotation.h"
#import "NSData+Base64.h"
#import "PhotoSubmitterSettings.h"
#import "UIImage+Enhancing.h"

//-----------------------------------------------------------------------------
//Private Implementations
//-----------------------------------------------------------------------------
@interface PhotoSubmitterImageEntity(PrivateImplementatio)
- (void) preserveMetadata;
- (void) applyMetadata:(NSData *)data preservedMetadata:(NSMutableDictionary *)preservedMetadata;
- (void) autoEnhance;
@end

@implementation PhotoSubmitterImageEntity(PrivateImplementation)
/*!
 * preserve metadata
 */
- (void)preserveMetadata{
    preservedMetadata_ = self.metadata;
}

/*!
 * auto enhance
 */
- (void)autoEnhance{
    UIImage *image = [UIImage imageWithData:data_];
    [image autoEnhance];
    data_ = UIImageJPEGRepresentation(image, 1.0);
}

/*!
 * apply metadata
 */
- (void)applyMetadata:(NSData *)data preservedMetadata:(NSMutableDictionary *)preservedMetadata{
    CGImageSourceRef img = CGImageSourceCreateWithData((__bridge CFDataRef)data, NULL);
	NSMutableDictionary* exifDict = [[NSMutableDictionary alloc] initWithDictionary:[preservedMetadata objectForKey:(NSString *)kCGImagePropertyExifDictionary]]; 
	NSMutableDictionary* locDict = [[NSMutableDictionary alloc] init];
	NSDateFormatter* dateFormatter = [[NSDateFormatter alloc] init];
	[dateFormatter setDateFormat:@"yyyy:MM:dd HH:mm:ss"];
	NSString* datetime = [dateFormatter stringFromDate:timestamp_];
	[exifDict setObject:datetime forKey:(NSString*)kCGImagePropertyExifDateTimeOriginal];
	[exifDict setObject:datetime forKey:(NSString*)kCGImagePropertyExifDateTimeDigitized];
    if(self.comment != nil){
        [exifDict setObject:self.comment forKey:(NSString*)kCGImagePropertyExifUserComment];
    }
    if(self.location != nil){
        [locDict setObject:self.location.timestamp forKey:(NSString*)kCGImagePropertyGPSTimeStamp];
        if (self.location.coordinate.latitude <0.0){ 
            [locDict setObject:@"S" forKey:(NSString*)kCGImagePropertyGPSLatitudeRef];
        }else{ 
            [locDict setObject:@"N" forKey:(NSString*)kCGImagePropertyGPSLatitudeRef];
        } 
        [locDict setObject:[NSNumber numberWithFloat:self.location.coordinate.latitude] forKey:(NSString*)kCGImagePropertyGPSLatitude];
        if (self.location.coordinate.longitude < 0.0){ 
            [locDict setObject:@"W" forKey:(NSString*)kCGImagePropertyGPSLongitudeRef];
        }else{ 
            [locDict setObject:@"E" forKey:(NSString*)kCGImagePropertyGPSLongitudeRef];
        } 
        [locDict setObject:[NSNumber numberWithFloat:self.location.coordinate.longitude] forKey:(NSString*)kCGImagePropertyGPSLongitude];
    }
	CGImageDestinationRef dest = CGImageDestinationCreateWithData((__bridge CFMutableDataRef)data_, CGImageSourceGetType(img), 1, NULL);
    
    [preservedMetadata setObject:exifDict forKey:(NSString *)kCGImagePropertyExifDictionary];
    [preservedMetadata setObject:locDict forKey:(NSString *)kCGImagePropertyGPSDictionary];
	CGImageDestinationAddImageFromSource(dest, img, 0, (__bridge CFDictionaryRef)preservedMetadata);
	CGImageDestinationFinalize(dest);
	CFRelease(img);
	CFRelease(dest);
}
@end

//-----------------------------------------------------------------------------
//Public Implementations
//----------------------------------------------------------------------------
@implementation PhotoSubmitterImageEntity

/*!
 * init with data
 */
- (id)initWithData:(NSData *)inData{
    self = [super initWithData:inData];
    if(self){
        resizedImages_ = [[NSMutableDictionary alloc] init];
    }
    return self;
}

/*!
 * init with data
 */
- (id)initWithImage:(UIImage *)inImage{
    self = [super init];
    if(self){
        image_ = inImage;
        data_ = UIImageJPEGRepresentation(image_, 1.0);
        timestamp_ = [NSDate date];
        resizedImages_ = [[NSMutableDictionary alloc] init];
    }
    return self;
}

/*!
 * apply metadata
 */
- (void)preprocess{
    [self preserveMetadata];
    if([PhotoSubmitterSettings getInstance].autoEnhance){
        [self autoEnhance];
    }
    [self applyMetadata:data_ preservedMetadata:preservedMetadata_];
}

/*!
 * populate image
 */
- (UIImage *)image{
    if(image_ == nil){
        image_ = [[UIImage imageWithData:self.data] fixOrientation];
    }
    return image_;
}

/*!
 * populate resized image 
 */
- (UIImage *)resizedImage:(CGSize)size{
    if(CGSizeEqualToSize(size, self.image.size)){
        return self.image;
    }
    
    NSString *key = NSStringFromCGSize(size);
    UIImage *resized = [resizedImages_ objectForKey:key];
    if(resized){
        return resized;
    }
    
    resized = [[self.image resizedImage:size
                   interpolationQuality:kCGInterpolationHigh] fixOrientation];
    
    NSData *resizedData = UIImageJPEGRepresentation(resized, 1.0);
    CGImageSourceRef resizedCFImage = CGImageSourceCreateWithData((__bridge CFDataRef)resizedData, NULL);
    
    NSMutableDictionary *metadata = self.metadata;
    NSMutableDictionary *resizedMetadata = [NSMutableDictionary dictionaryWithDictionary:(__bridge NSDictionary *)CGImageSourceCopyPropertiesAtIndex(resizedCFImage, 0, nil)];
    NSMutableDictionary *exifMetadata = [metadata objectForKey:(NSString *)kCGImagePropertyExifDictionary];
    [resizedMetadata setValue:exifMetadata forKey:(NSString *)kCGImagePropertyExifDictionary];
    CGImageDestinationRef dest = CGImageDestinationCreateWithData((__bridge CFMutableDataRef)resizedData, CGImageSourceGetType(resizedCFImage), 1, NULL);
    CGImageDestinationAddImageFromSource(dest, resizedCFImage, 0, (__bridge CFDictionaryRef)resizedMetadata);
    CGImageDestinationFinalize(dest);
    CFRelease(resizedCFImage);
    
    [resizedImages_ setObject:resized forKey:key];
    return resized;
}

/*!
 * populate resized image 
 */
- (NSData *) autoRotatedData{    
    if(autoRotatedData_){
        return autoRotatedData_;
    }
    [self preserveMetadata];
    UIImage *rotatedImage = [[UIImage imageWithData:data_] fixOrientation];
    NSData *rotatedData = UIImageJPEGRepresentation(rotatedImage, 1.0);
    
    [self applyMetadata: rotatedData preservedMetadata:preservedMetadata_];
    
    autoRotatedData_ = rotatedData;
    return rotatedData;
}

/*!
 * extract metadata from image data
 */
- (NSMutableDictionary *)metadata{
    CGImageSourceRef cfImage = CGImageSourceCreateWithData((__bridge CFDataRef)data_, NULL);
    NSDictionary *metadata = (__bridge NSDictionary *)CGImageSourceCopyPropertiesAtIndex(cfImage, 0, nil);
    CFRelease(cfImage);
    return [NSMutableDictionary dictionaryWithDictionary:metadata];
}

/*!
 * clone and auto rotate image
 */
- (PhotoSubmitterImageEntity *)autoRotatedImageEntity{
    return nil;
}

/*!
 * init with coder
 */
- (id)initWithCoder:(NSCoder*)coder {
    self = [super initWithCoder:coder];
    if (self) {
        resizedImages_ = [[NSMutableDictionary alloc] init];
    }
    return self;
}

/*!
 * type
 */
- (PhotoSubmitterContentType)type{
    return PhotoSubmitterContentTypePhoto;
}
@end
