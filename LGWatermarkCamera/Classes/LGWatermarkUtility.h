//
//  LGWatermarkUtility.h
//  LGWatermarkCamera
//
//  Created by LG on 2018/11/12.
//  Copyright © 2018年 LG. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface LGWatermarkUtility : NSObject

/**
 * 计算文字在指定区域范围内的实际区域
 * @param text 文字内容
 * @param size 指定区域范围
 * @return 实际区域
 */
+ (CGRect)rectWithText:(NSString *)text
      inRectBoundsSize:(CGSize)size
                 scale:(CGFloat)scale;

+ (instancetype)sharedInstance;

+ (NSDictionary<NSAttributedStringKey, id> *)watermarkAttributesWithScale:(CGFloat)scale;

@end
