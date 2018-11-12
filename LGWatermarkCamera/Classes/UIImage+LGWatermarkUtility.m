//
//  UIImage+lgWatermarkUtility.m
//  LGWatermarkCameraw
//
//  Created by LG on 2018/11/12.
//  Copyright © 2018年 LG. All rights reserved.
//

#import "UIImage+LGWatermarkUtility.h"

#import "LGWatermarkUtility.h"
#import "UIView+LGSnapshot.h"

@implementation UIImage (lgWatermarkUtility)

- (UIImage *)lg_imageWithWatermarkText:(NSString *)text {
    if (text.length == 0) {
        return self;
    }
    UIGraphicsBeginImageContext(self.size);

    [self drawInRect:CGRectMake(0, 0, self.size.width, self.size.height)];
    CGFloat scale = self.size.width / CGRectGetWidth([UIScreen mainScreen].bounds);
    [text drawInRect:[LGWatermarkUtility rectWithText:text inRectBoundsSize:self.size scale:scale]
      withAttributes:[LGWatermarkUtility watermarkAttributesWithScale:scale]];

    UIImage *resultImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();

    return resultImage;
}

- (UIImage *)lg_imageWithWatermarkImage:(UIImage *)image rect:(CGRect)rect {
    if (!image) {
        return self;
    }
    // 为达到所见即所得的效果,对 image 的区域进行调整, 输出图片固定为 w / h = 3 / 4;
    // 5 / 375 = x / 2000
    CGFloat positionX = CGRectGetMinX(rect) * self.size.width / CGRectGetWidth([UIScreen mainScreen].bounds);
    CGFloat positionY = CGRectGetMinY(rect) * self.size.height / (CGRectGetWidth([UIScreen mainScreen].bounds) * 4 / 3);
    CGFloat positionWidth = self.size.width * CGRectGetWidth(rect) / CGRectGetWidth([UIScreen mainScreen].bounds);
    CGFloat positionHeight = self.size.height * CGRectGetHeight(rect) / (CGRectGetWidth([UIScreen mainScreen].bounds) * 4 / 3);
    CGRect trueRect = CGRectMake(
                                 positionX,
                                 positionY,
                                 positionWidth,
                                 positionHeight
                                 );
    UIGraphicsBeginImageContext(self.size);
    [self drawInRect:CGRectMake(0, 0, self.size.width, self.size.height)];
    [image drawInRect:trueRect];
    UIImage *resultImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();

    return resultImage;
}

- (UIImage *)lg_imageWithWatermarkView:(UIView *)view {
    if (!view) {
        return self;
    }
    UIImage *snapshot = view.lg_imageOfSnapshot;
    return [self lg_imageWithWatermarkImage:snapshot rect:view.frame];
}

// 裁剪 multiplier = height / width
- (UIImage *)lg_clipImageByMultiplier:(CGFloat)multiplier {
    CGImageRef imageRef = self.fixOrientation.CGImage;
    CGFloat offset = (CGImageGetHeight(imageRef) - CGImageGetWidth(imageRef) * multiplier) / 2;
    CGRect rect = CGRectMake(0, offset, CGImageGetWidth(imageRef), CGImageGetWidth(imageRef) * multiplier);
    CGImageRef newImageRef = CGImageCreateWithImageInRect(imageRef, rect);

    return [UIImage imageWithCGImage:newImageRef];
}

// 缩放
- (UIImage *)lg_scaleImageToSize:(CGSize)size {
    UIGraphicsBeginImageContext(size);
    [self.fixOrientation drawInRect:CGRectMake(0, 0, size.width, size.height)];
    UIImage *resultImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    return resultImage;
}

- (UIImage *)lg_clipScaleImageToSize:(CGSize)size {
    UIImage *clipImage = [self lg_clipImageByMultiplier:size.height / size.width];
    UIImage *scaleImage = [clipImage lg_scaleImageToSize:size];
    return scaleImage;
}

//
- (UIImage *)fixOrientation {
    // No-op if the orientation is already correct
    if (self.imageOrientation == UIImageOrientationUp)
        return self;
    
    // We need to calculate the proper transformation to make the image upright.
    // We do it in 2 steps: Rotate if Left/Right/Down, and then flip if Mirrored.
    CGAffineTransform transform = CGAffineTransformIdentity;
    
    switch (self.imageOrientation) {
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
    
    switch (self.imageOrientation) {
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
    switch (self.imageOrientation) {
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

+ (UIImage *)lg_imageInBundleNamed:(NSString *)name {
    NSBundle *bundle = [NSBundle bundleWithPath:[[NSBundle bundleForClass:NSClassFromString(@"lgWatermarkCameraViewController")].resourcePath stringByAppendingPathComponent:@"lgWatermarkCamera.bundle"]];
    return [UIImage imageNamed:name
                      inBundle:bundle
 compatibleWithTraitCollection:nil];
}

@end
