//
//  UIImage+ENGAutoRotation.m
//
//  Created by ISHITOYA Kentaro on 11/10/18.
//

#import "UIImage+ENGAutoRotation.h"

@implementation UIImage (ENGAutoRotation)

/*!
 * return cgimage rotated specified angle
 */
- (CGImageRef)newCGImageRefRotatedByAngle:(CGFloat)angle
{
    CGFloat angleInRadians = angle * (M_PI / 180);
    CGImageRef imgRef = self.CGImage;
    CGFloat width = CGImageGetWidth(imgRef);
    CGFloat height = CGImageGetHeight(imgRef);
    

    CGRect imgRect = CGRectMake(0, 0, width, height);
    CGAffineTransform transform = CGAffineTransformMakeRotation(angleInRadians);
    CGRect rotatedRect = CGRectApplyAffineTransform(imgRect, transform);
    
    CGContextRef bmContext = CGBitmapContextCreate(NULL,
                                                   rotatedRect.size.width,
                                                   rotatedRect.size.height,
                                                   8,
                                                   0,
                                                   CGImageGetColorSpace(imgRef),
                                                   CGImageGetAlphaInfo(imgRef));
    CGContextSetInterpolationQuality(bmContext, kCGInterpolationNone);
    CGContextTranslateCTM(bmContext,
                          +(rotatedRect.size.width/2),
                          +(rotatedRect.size.height/2));
    CGContextRotateCTM(bmContext, angleInRadians);
    CGRect drawRect = CGRectMake(-width/2, -height/2, width, height);
    CGContextDrawImage(bmContext, drawRect, imgRef);
    
    CGImageRef rotatedImage = CGBitmapContextCreateImage(bmContext);
    CFRelease(bmContext);
    return rotatedImage;
}

/*!
 * return rotated image
 */
-(CGImageRef)newCGImageRefAutoRotated{
    switch (self.imageOrientation) {
        case UIImageOrientationDown:
            return [self newCGImageRefRotatedByAngle:180.0];
        case UIImageOrientationLeft:
            return [self newCGImageRefRotatedByAngle:90.0];
        case UIImageOrientationRight:
            return [self newCGImageRefRotatedByAngle:270.0];
        default:
            return [self newCGImageRefRotatedByAngle:0];
    }
}

/*!
 * return rotated image
 */
-(UIImage *)ENGUIImageAutoRotated{
    CGImageRef ir = [self newCGImageRefAutoRotated];
    UIImage* image = [UIImage imageWithCGImage: ir];
    CGImageRelease(ir);
    return image;
}

/*!
 * return rotated image by pointed angle
 */
- (UIImage*) UIImageRotateByAngle :(int)angle
{
    CGImageRef ir = [self newCGImageRefRotatedByAngle:angle];
    UIImage* image = [UIImage imageWithCGImage: ir];
    CGImageRelease(ir);
    return image;    
}

/*!
 * fix orientation
 * http://stackoverflow.com/questions/5427656/ios-uiimagepickercontroller-result-image-orientation-after-upload
 */
- (UIImage *)fixOrientationWithOrientation:(UIImageOrientation)orientation {
    // No-op if the orientation is already correct
    if (orientation == UIImageOrientationUp) return self;
    
    // We need to calculate the proper transformation to make the image upright.
    // We do it in 2 steps: Rotate if Left/Right/Down, and then flip if Mirrored.
    CGAffineTransform transform = CGAffineTransformIdentity;
    
    switch (orientation) {
        case UIImageOrientationDown:
        case UIImageOrientationDownMirrored:
            transform = CGAffineTransformTranslate(transform, self.size.width, self.size.height);
            transform = CGAffineTransformRotate(transform, M_PI);
            break;
            
        case UIImageOrientationLeft:
        case UIImageOrientationLeftMirrored:
            transform = CGAffineTransformTranslate(transform, self.size.width, 0);
            transform = CGAffineTransformRotate(transform, M_PI_2);
            break;
            
        case UIImageOrientationRight:
        case UIImageOrientationRightMirrored:
            transform = CGAffineTransformTranslate(transform, 0, self.size.height);
            transform = CGAffineTransformRotate(transform, -M_PI_2);
            break;
        default:
            break;
    }
    
    switch (orientation) {
        case UIImageOrientationUpMirrored:
        case UIImageOrientationDownMirrored:
            transform = CGAffineTransformTranslate(transform, self.size.width, 0);
            transform = CGAffineTransformScale(transform, -1, 1);
            break;
            
        case UIImageOrientationLeftMirrored:
        case UIImageOrientationRightMirrored:
            transform = CGAffineTransformTranslate(transform, self.size.height, 0);
            transform = CGAffineTransformScale(transform, -1, 1);
            break;
        default:
            break;
    }
    
    // Now we draw the underlying CGImage into a new context, applying the transform
    // calculated above.
    CGContextRef ctx = CGBitmapContextCreate(NULL, self.size.width, self.size.height,
                                             CGImageGetBitsPerComponent(self.CGImage), 0,
                                             CGImageGetColorSpace(self.CGImage),
                                             CGImageGetBitmapInfo(self.CGImage));
    CGContextConcatCTM(ctx, transform);
    switch (orientation) {
        case UIImageOrientationLeft:
        case UIImageOrientationLeftMirrored:
        case UIImageOrientationRight:
        case UIImageOrientationRightMirrored:
            // Grr...
            CGContextDrawImage(ctx, CGRectMake(0,0,self.size.height,self.size.width), self.CGImage);
            break;
            
        default:
            CGContextDrawImage(ctx, CGRectMake(0,0,self.size.width,self.size.height), self.CGImage);
            break;
    }
    
    // And now we just create a new UIImage from the drawing context
    CGImageRef cgimg = CGBitmapContextCreateImage(ctx);
    UIImage *img = [UIImage imageWithCGImage:cgimg];
    CGContextRelease(ctx);
    CGImageRelease(cgimg);
    return img;

}

/*!
 * fix orientation
 */
- (UIImage *)fixOrientation {
    return [self fixOrientationWithOrientation:self.imageOrientation];
}
@end