//
//  UIImage+GeoTagging.m
//  tottepost
//
//  Created by ISHITOYA Kentaro on 11/12/25.
//  Copyright (c) 2011 cocotomo. All rights reserved.
//

#if ! __has_feature(objc_arc)
#error This file must be compiled with ARC. Use -fobjc-arc flag (or convert project to ARC).
#endif

#import <ImageIO/ImageIO.h>
#import "UIImage+EXIF.h"

@implementation UIImage (EXIF)
/*!
 * add geolocation and comment to image
 */
-(NSData *) geoTaggedDataWithLocation:(CLLocation *)location andComment:(NSString *)comment{
    NSData *data = UIImageJPEGRepresentation(self, 1.0);
    return [UIImage geoTaggedData:data withLocation:location andComment:comment];
}

/*!
 * add geolocation and comment to image
 */
+(NSData *) geoTaggedData:(NSData *)data withLocation:(CLLocation *)location andComment:(NSString *)comment{
    CGImageSourceRef img = CGImageSourceCreateWithData((__bridge CFDataRef)data, NULL);
	NSMutableDictionary* exifDict = [[NSMutableDictionary alloc] init];
	NSMutableDictionary* locDict = [[NSMutableDictionary alloc] init];
	NSDateFormatter* dateFormatter = [[NSDateFormatter alloc] init];
	[dateFormatter setDateFormat:@"yyyy:MM:dd HH:mm:ss"];
	NSString* datetime = [dateFormatter stringFromDate:location.timestamp];
	[exifDict setObject:datetime forKey:(NSString*)kCGImagePropertyExifDateTimeOriginal];
	[exifDict setObject:datetime forKey:(NSString*)kCGImagePropertyExifDateTimeDigitized];
    if(comment != nil){
        [exifDict setObject:comment forKey:(NSString*)kCGImagePropertyExifUserComment];
    }
	[locDict setObject:location.timestamp forKey:(NSString*)kCGImagePropertyGPSTimeStamp];
	if (location.coordinate.latitude <0.0){ 
		[locDict setObject:@"S" forKey:(NSString*)kCGImagePropertyGPSLatitudeRef];
	}else{ 
		[locDict setObject:@"N" forKey:(NSString*)kCGImagePropertyGPSLatitudeRef];
	} 
	[locDict setObject:[NSNumber numberWithFloat:location.coordinate.latitude] forKey:(NSString*)kCGImagePropertyGPSLatitude];
	if (location.coordinate.longitude < 0.0){ 
		[locDict setObject:@"W" forKey:(NSString*)kCGImagePropertyGPSLongitudeRef];
	}else{ 
		[locDict setObject:@"E" forKey:(NSString*)kCGImagePropertyGPSLongitudeRef];
	} 
	[locDict setObject:[NSNumber numberWithFloat:location.coordinate.longitude] forKey:(NSString*)kCGImagePropertyGPSLongitude];
    
	NSMutableData* imageData = [[NSMutableData alloc] init];
	CGImageDestinationRef dest = CGImageDestinationCreateWithData((__bridge CFMutableDataRef)imageData, CGImageSourceGetType(img), 1, NULL);
    
    NSMutableDictionary *metadata = 
        [NSDictionary dictionaryWithObjectsAndKeys:
                    locDict,  (NSString*)kCGImagePropertyGPSDictionary,
                    exifDict, (NSString*)kCGImagePropertyExifDictionary, nil];
	CGImageDestinationAddImageFromSource(dest, img, 0, (__bridge CFDictionaryRef)metadata);
	CGImageDestinationFinalize(dest);
	CFRelease(img);
	CFRelease(dest);
    return imageData;
}
/*!
 * load metadata
 */
+(NSDictionary *)extractMetadata:(NSData *)data{
    CGImageSourceRef image = CGImageSourceCreateWithData((__bridge CFDataRef)data, NULL);
    NSMutableDictionary *metadata = [NSMutableDictionary dictionaryWithDictionary:(__bridge_transfer NSDictionary *)CGImageSourceCopyPropertiesAtIndex(image, 0, nil)];
    CFRelease(image);
    return metadata;
}
@end
