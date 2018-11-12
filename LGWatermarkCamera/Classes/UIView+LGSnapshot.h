//
//  UIView+LGSnapshot.h
//  LGWatermarkCamera
//
//  Created by LG on 2018/11/12.
//  Copyright © 2018年 LG. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface UIView (LGSnapshot)

/**
 * 生成截图
 * @return 截图
 */
- (UIImage *)lg_imageOfSnapshot;

@end
