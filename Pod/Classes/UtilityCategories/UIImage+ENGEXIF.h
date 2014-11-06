//
//  UIImage+ENGEXIF.h
//
//  Created by ISHITOYA Kentaro on 11/12/25.
//

#import <UIKit/UIKit.h>
#import <CoreLocation/CoreLocation.h>

@interface UIImage (ENGEXIF)
-(NSData *) geoTaggedDataWithLocation:(CLLocation *)location andComment:(NSString *)comment;
+(NSData *) geoTaggedData:(NSData *)data withLocation:(CLLocation *)location andComment:(NSString *)comment;
+(NSDictionary *)extractMetadata:(NSData *)data;
@end
