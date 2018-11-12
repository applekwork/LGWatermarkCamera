//
//  LGWatermarkCameraViewController.h
//  LGWatermarkCamera
//
//  Created by LG on 2018/11/12.
//  Copyright © 2018年 LG. All rights reserved.
//

#import <UIKit/UIKit.h>

@protocol LGWatermarkCameraViewControllerDelegate;

@interface LGWatermarkCameraViewController : UIViewController

@property(nullable, nonatomic, copy) UIColor *backgroundColor;

/**
 * 要显示的水印文字
 */
@property(nonatomic, copy) NSString *watermarkText;

@property(nonatomic, strong) UIView *watermarkView;

@property(nonatomic, weak) id <LGWatermarkCameraViewControllerDelegate> delegate;

- (void)setWatermarkImage:(UIImage *)image rect:(CGRect)rect;

@end

@protocol LGWatermarkCameraViewControllerDelegate <NSObject>

- (void)watermarkCameraViewController:(LGWatermarkCameraViewController *)watermarkCameraViewController
                            takeImage:(UIImage *)image;

@end
