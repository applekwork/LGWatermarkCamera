//
//  UIView+LGSnapshot.m
//  LGWatermarkCamera
//
//  Created by LG on 2018/11/12.
//  Copyright © 2018年 LG. All rights reserved.
//

#import "UIView+LGSnapshot.h"

@implementation UIView (LGSnapshot)

- (UIImage *)lg_imageOfSnapshot {
    UIGraphicsBeginImageContextWithOptions(self.bounds.size, NO, 0);
    [self.layer renderInContext:UIGraphicsGetCurrentContext()];
    UIImage *snap = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    return snap;
}

@end
