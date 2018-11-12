//
//  UIImage+LGWatermarkUtility.h
//  LGWatermarkCameraw
//
//  Created by LG on 2018/11/12.
//  Copyright © 2018年 LG. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface UIImage (LGWatermarkUtility)

/**
 * 在指定区域生成文字水印
 * @param text 水印内容
 * @return 携带水印的图片
 */
- (UIImage *)lg_imageWithWatermarkText:(NSString *)text;

/**
 * 在指定区域生成图片水印
 * @param image 水印图片
 * @param rect 指定区域
 * @return 携带水印的图片
 */
- (UIImage *)lg_imageWithWatermarkImage:(UIImage *)image rect:(CGRect)rect;

/**
 * 在指定区域生成 View 水印
 * @param view 水印 View,必须指定 Frame
 * @return 携带水印的图片
 */
- (UIImage *)lg_imageWithWatermarkView:(UIView *)view;

/**
 * 裁剪并缩放图片为指定尺寸
 * @param size 最终得到的图片尺寸,单位为 pt
 * @return 最终得到的图片
 */
- (UIImage *)lg_clipScaleImageToSize:(CGSize)size;

+ (UIImage *)lg_imageInBundleNamed:(NSString *)name;

@end
