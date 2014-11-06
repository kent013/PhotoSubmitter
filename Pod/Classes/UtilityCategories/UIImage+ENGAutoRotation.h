//
//  UIImage+ENGAutoRotation.h
//
//  Created by ISHITOYA Kentaro on 11/10/18.
//

#import <UIKit/UIKit.h>

@interface UIImage (ENGAutoRotation)
- (CGImageRef)newCGImageRefRotatedByAngle :(CGFloat)angle;
- (CGImageRef)newCGImageRefAutoRotated;
- (UIImage*) UIImageRotateByAngle :(int)angle;
- (UIImage *)fixOrientationWithOrientation:(UIImageOrientation)orientation;
- (UIImage*) fixOrientation;
@end
