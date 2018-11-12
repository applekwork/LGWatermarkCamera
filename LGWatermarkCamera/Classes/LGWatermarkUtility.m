//
//  LGWatermarkUtility.m
//  LGWatermarkCamera
//
//  Created by LG on 2018/11/12.
//  Copyright © 2018年 LG. All rights reserved.
//

#import "LGWatermarkUtility.h"

@implementation LGWatermarkUtility

+ (instancetype)sharedInstance {
    static id _sharedInstance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        _sharedInstance = [[self alloc] init];
    });
    

    return _sharedInstance;
}

+ (CGRect)rectWithText:(NSString *)text
      inRectBoundsSize:(CGSize)size
                 scale:(CGFloat)scale {
    if (text.length == 0) {
        return CGRectZero;
    }
    if (scale == 0) {
        scale = 1;
    }

    NSMutableParagraphStyle *paragraph = [[NSMutableParagraphStyle alloc] init];
    paragraph.lineBreakMode = NSLineBreakByWordWrapping;
    NSDictionary *attributes = @{
            NSFontAttributeName: [UIFont systemFontOfSize:(15 * scale)],
            NSParagraphStyleAttributeName: paragraph,
    };
    CGSize textSize = [text boundingRectWithSize:CGSizeMake(size.width - 12.5 * scale * 2, CGFLOAT_MAX)
                                                       options:(NSStringDrawingUsesLineFragmentOrigin |
                                                               NSStringDrawingTruncatesLastVisibleLine)
                                                    attributes:attributes
                                                       context:nil].size;
    CGRect result = CGRectMake(12.5 * scale, size.height - 12.5 * scale - textSize.height, size.width - 12.5 * scale * 2, textSize.height);
    return result;
}

+ (NSDictionary<NSAttributedStringKey, id> *)watermarkAttributesWithScale:(CGFloat)scale {

    NSShadow *textShadow = [[NSShadow alloc] init];
    textShadow.shadowBlurRadius = 2.0 * scale;
    textShadow.shadowColor = UIColor .blackColor;
    

    return @{
            NSFontAttributeName: [UIFont systemFontOfSize:15 * scale],
            NSForegroundColorAttributeName: [UIColor whiteColor],
            NSShadowAttributeName: textShadow,
    };
}


@end
