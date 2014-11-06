//
//  UIImage+AutoRotation.h
//  iSticky
//
//  Created by ISHITOYA Kentaro on 11/10/18.
//  Copyright (c) 2011 cocotomo. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface UIImage (AutoRotation)
- (CGImageRef)newCGImageRefRotatedByAngle :(CGFloat)angle;
- (CGImageRef)newCGImageRefAutoRotated;
- (UIImage*) UIImageAutoRotated;
- (UIImage*) UIImageRotateByAngle :(int)angle;
- (UIImage *)fixOrientationWithOrientation:(UIImageOrientation)orientation;
- (UIImage*) fixOrientation;
@end
