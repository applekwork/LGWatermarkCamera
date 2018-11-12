//
//  LGWatermarkCameraViewController.m
//  LGWatermarkCamera
//
//  Created by LG on 2018/11/12.
//  Copyright © 2018年 LG. All rights reserved.
//

#import "LGWatermarkCameraViewController.h"
#import <AVFoundation/AVFoundation.h>
#import "LGWatermarkUtility.h"
#import "UIImage+LGWatermarkUtility.h"

@interface LGWatermarkCameraViewController () <AVCaptureMetadataOutputObjectsDelegate>

//捕获设备，通常是前置摄像头，后置摄像头，麦克风（音频输入）
@property(nonatomic) AVCaptureDevice *captureDevice;

//AVCaptureDeviceInput 代表输入设备，他使用AVCaptureDevice 来初始化
@property(nonatomic) AVCaptureDeviceInput *captureDeviceInput;

// 获得的图片
@property(nonatomic) AVCaptureStillImageOutput *imageOutput;

//captureSession：由他把输入输出结合在一起，并开始启动捕获设备（摄像头）
@property(nonatomic) AVCaptureSession *captureSession;

//图像预览层，实时显示捕获的图像
@property(nonatomic) AVCaptureVideoPreviewLayer *previewLayer;

// 加在 previewLayer 之上
@property(nonatomic, retain) UIView *previewCoverView;

// 返回/重拍
@property(nonatomic, strong) UIButton *controlButton;

// 切换前/后 确认选择
@property(nonatomic, strong) UIButton *changeButton;

// 拍摄按钮
@property(nonatomic, strong) UIButton *shootButton;

// 闪光灯
@property(nonatomic, strong) UIButton *flashlightButton;

@property(nonatomic, assign) NSUInteger flashModeFlag;


// 拍摄完成预览 ImageView
@property(nonatomic, strong) UIImageView *previewImageView;

@property(nonatomic, strong) UILabel *watermarkLabel;

// 水印的富文本效果
@property(nonatomic, copy) NSAttributedString *watermarkAttributedString;

@property(nonatomic, strong) NSShadow *textShadow;

// 相机对焦的 View
@property(nonatomic) UIView *focusView;

@property(nonatomic, strong) UITapGestureRecognizer *tapGestureRecognizer;

@property(nonatomic, strong) UIImageView *watermarkImageView;

@property(nonatomic, strong) UIImage *watermarkImage;

@property(nonatomic, assign) CGRect watermarkImageRect;

@property(nonatomic, assign) AVCaptureDevicePosition position;

@property(nonatomic, assign) BOOL useFrontCamera;

@end

@implementation LGWatermarkCameraViewController

#ifndef kScreenBounds
#define kScreenBounds   [UIScreen mainScreen].bounds
#endif

#ifndef kScreenWidth
#define kScreenWidth    kScreenBounds.size.width * 1.0
#endif

#ifndef kScreenHeight
#define kScreenHeight   kScreenBounds.size.height * 1.0
#endif

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    if (self.backgroundColor) {
        self.view.backgroundColor = self.backgroundColor;
    } else {
        self.view.backgroundColor = UIColor .blackColor;
    }
    self.position = AVCaptureDevicePositionBack;

    self.flashModeFlag = 0;
    
    if (self.canUseCamera) {
        [self setupCamera];
    } else {
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, NSEC_PER_SEC * 0.3), dispatch_get_main_queue(), ^{
            [self showCameraAlert];
        });
    }
    [self setupUI];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (BOOL)canUseCamera {
    AVAuthorizationStatus authStatus = [AVCaptureDevice authorizationStatusForMediaType:AVMediaTypeVideo];
    if (authStatus == AVAuthorizationStatusDenied) {
        return NO;
    } else {
        return YES;
    }
}

- (void)showCameraAlert {
    UIAlertController *alertController = [UIAlertController alertControllerWithTitle:@"提示"
                                                                             message:@"请到设置中开启相机的访问权限"
                                                                      preferredStyle:UIAlertControllerStyleAlert];
    UIAlertAction *cancelAction = [UIAlertAction actionWithTitle:@"取消"
                                                           style:UIAlertActionStyleCancel
                                                         handler:^(UIAlertAction * _Nonnull action) {
                                                             [self handleCancel];
                                                         }];
    UIAlertAction *settingAction = [UIAlertAction actionWithTitle:@"设置"
                                                            style:UIAlertActionStyleDefault
                                                          handler:^(UIAlertAction * _Nonnull action) {
                                                              [self handleCameraSetting];
                                                          }];
    [alertController addAction:cancelAction];
    [alertController addAction:settingAction];
    
    [self presentViewController:alertController
                       animated:NO
                     completion:nil];
}

- (void)handleCancel {
    [self dismissViewControllerAnimated:NO completion:nil];
}

- (void)handleCameraSetting {
    NSURL *URL = [NSURL URLWithString:UIApplicationOpenSettingsURLString];
    if (@available(iOS 10, *)) {
        [[UIApplication sharedApplication] openURL:URL
                                           options:nil
                                 completionHandler:nil];
    } else {
        [[UIApplication sharedApplication] openURL:URL];
    }
}

- (void)setupCamera{
    if ([self.captureSession isRunning]) {
        [self.captureSession stopRunning];
        
        self.captureDevice = nil;
        self.captureDeviceInput = nil;
        self.imageOutput = nil;
        self.captureSession = nil;
    }
    //使用AVMediaTypeVideo 指明self.device代表视频，默认使用后置摄像头进行初始化
    self.captureDevice = [self captureDeviceWithPosition:self.position];

    //使用设备初始化输入
    self.captureDeviceInput = [[AVCaptureDeviceInput alloc]initWithDevice:self.captureDevice error:nil];

    //生成输出对象
    self.imageOutput = [[AVCaptureStillImageOutput alloc] init];

    //生成会话，用来结合输入输出
    self.captureSession = [[AVCaptureSession alloc]init];

    if ([self.captureSession canSetSessionPreset:AVCaptureSessionPreset1280x720]) {
        self.captureSession.sessionPreset = AVCaptureSessionPreset1280x720;
    }
    if ([self.captureSession canAddInput:self.captureDeviceInput]) {
        [self.captureSession addInput:self.captureDeviceInput];
    }

    if ([self.captureSession canAddOutput:self.imageOutput]) {
        [self.captureSession addOutput:self.imageOutput];
    }
    
    if (self.previewLayer) {
        [self.previewLayer removeFromSuperlayer];
        self.previewLayer = nil;
    }

    //使用self.captureSession，初始化预览层，self.session负责驱动input进行信息的采集，layer负责把图像渲染显示
    self.previewLayer = [[AVCaptureVideoPreviewLayer alloc]initWithSession:self.captureSession];

    // 以 竖屏 3:4 的比例显示
    self.previewLayer.frame = CGRectMake(0, (kScreenHeight - kScreenWidth / 3 * 4) / 2, kScreenWidth, kScreenWidth / 3 * 4);
    self.previewLayer.videoGravity = AVLayerVideoGravityResizeAspectFill;
//    [self.view.layer addSublayer:self.previewLayer];
    [self.view.layer insertSublayer:self.previewLayer atIndex:0];
//    [self.view.layer bri];

    //开始启动
    [self.captureSession startRunning];
    if ([_captureDevice lockForConfiguration:nil]) {
        // 自动闪光灯
        if ([_captureDevice isFlashModeSupported:AVCaptureFlashModeAuto]) {
            [_captureDevice setFlashMode:AVCaptureFlashModeAuto];
        }
        //自动白平衡
        if ([_captureDevice isWhiteBalanceModeSupported:AVCaptureWhiteBalanceModeAutoWhiteBalance]) {
            [_captureDevice setWhiteBalanceMode:AVCaptureWhiteBalanceModeAutoWhiteBalance];
        }
        [_captureDevice unlockForConfiguration];
    }
}

- (void)setupUI {
    [self.view addSubview:self.previewCoverView];
    [self.view addSubview:self.flashlightButton];
    [self.view addSubview:self.shootButton];
    [self.view addSubview:self.controlButton];
    [self.view addSubview:self.changeButton];
    [self.previewCoverView addGestureRecognizer:self.tapGestureRecognizer];
    [self.previewCoverView addSubview:self.focusView];
    if (self.watermarkText.length > 0) {
        [self.previewCoverView addSubview:self.watermarkLabel];
    } else if (self.watermarkView) {
        [self.previewCoverView addSubview:self.watermarkView];
    } else if (self.watermarkImage) {
        [self.previewCoverView addSubview:self.watermarkImageView];
    }
    [self.previewCoverView addSubview:self.previewImageView];
    self.watermarkLabel.attributedText = self.watermarkAttributedString;
    self.watermarkLabel.frame = self.watermarkLabelRect;
}

- (CGRect)watermarkLabelRect {
    return [LGWatermarkUtility rectWithText:self.watermarkText inRectBoundsSize:self.previewCoverView.bounds.size scale:0];
}

- (UIImageView *)previewImageView {
    if (!_previewImageView) {
        _previewImageView = [[UIImageView alloc] initWithFrame:self.previewCoverView.bounds];
        _previewImageView.layer.masksToBounds = YES;
    }
    return _previewImageView;
}

- (UILabel *)watermarkLabel {
    if (!_watermarkLabel) {
        _watermarkLabel = [[UILabel alloc] init];
        _watermarkLabel.font = [UIFont systemFontOfSize:15];
        _watermarkLabel.numberOfLines = 0;
    }
    return _watermarkLabel;
}


- (NSShadow *)textShadow {
    if (!_textShadow) {
        _textShadow = [[NSShadow alloc] init];
        _textShadow.shadowBlurRadius = 2.0;
        _textShadow.shadowColor = UIColor .blackColor;
    }
    return _textShadow;
}

- (UIView *)focusView {
    if (!_focusView) {
        _focusView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 80, 80)];
        _focusView.layer.borderWidth = 1.0;
        _focusView.layer.borderColor = UIColor .greenColor.CGColor;
        _focusView.backgroundColor = UIColor .clearColor;
        _focusView.hidden = YES;
    }
    return _focusView;
}

- (UIView *)previewCoverView {
    if (!_previewCoverView) {
        _previewCoverView = [[UIView alloc] initWithFrame:CGRectMake(0, (kScreenHeight - kScreenWidth / 3 * 4) / 2, kScreenWidth, kScreenWidth / 3 * 4)];
        _previewCoverView.backgroundColor = UIColor .clearColor;
    }
    return _previewCoverView;
}

- (UITapGestureRecognizer *)tapGestureRecognizer {
    if (!_tapGestureRecognizer) {
        _tapGestureRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self
                action:@selector(focusViewTap:)];
    }
    return _tapGestureRecognizer;
}

- (UIImageView *)watermarkImageView {
    if (!_watermarkImageView) {
        _watermarkImageView = [[UIImageView alloc] initWithImage:self.watermarkImage];
        _watermarkImageView.frame = self.watermarkImageRect;
    }
    return _watermarkImageView;
}


- (void)focusViewTap:(UITapGestureRecognizer *)sender {
    CGPoint location = [sender locationInView:self.previewCoverView];

    CGSize size = self.previewCoverView.bounds.size;
    CGPoint focusPoint = CGPointMake(location.x / size.width, location.y / size.height);

    NSError *error;
    if ([self.captureDevice lockForConfiguration:&error]) {
        if ([self.captureDevice isFocusModeSupported:AVCaptureFocusModeAutoFocus]) {
            [self.captureDevice setFocusPointOfInterest:focusPoint];
            [self.captureDevice setFocusMode:AVCaptureFocusModeAutoFocus];
        }

        if ([self.captureDevice isExposureModeSupported:AVCaptureExposureModeAutoExpose ]) {
            [self.captureDevice setExposurePointOfInterest:focusPoint];
            [self.captureDevice setExposureMode:AVCaptureExposureModeAutoExpose];
        }

        [self.captureDevice unlockForConfiguration];
        self.focusView.center = location;
        self.focusView.hidden = NO;
        [UIView animateWithDuration:0.3
                         animations:^{
                             self.focusView.transform = CGAffineTransformMakeScale(1.25, 1.25);
                         }
                         completion:^(BOOL finished) {
            [UIView animateWithDuration:0.5
                             animations:^{
                                 self.focusView.transform = CGAffineTransformIdentity;
                             }
                             completion:^(BOOL finished) {
                                 self.focusView.hidden = YES;
                             }];
                         }];

    }
}


- (UIButton *)controlButton {
    if (!_controlButton) {
        _controlButton = [UIButton buttonWithType:UIButtonTypeCustom];
        _controlButton.frame = CGRectMake(45, kScreenHeight - 125, 75, 75);
        [_controlButton addTarget:self
                action:@selector(controlButtonTouchUpInside:)
                 forControlEvents:UIControlEventTouchUpInside];
        [_controlButton setImage:[UIImage lg_imageInBundleNamed:@"ic-camera-control-normal"]
                        forState:UIControlStateNormal];
        [_controlButton setImage:[UIImage lg_imageInBundleNamed:@"ic-camera-control-selected"]
                        forState:UIControlStateSelected];

    }
    return _controlButton;
}

- (void)controlButtonTouchUpInside:(UIButton *)sender {
    if (sender.selected) { // 重拍
        [self restartSession];
    } else { // 取消
        [self dismissViewControllerAnimated:NO completion:nil];
    }
}

- (void)restartSession {
    self.controlButton.selected = NO;
    self.shootButton.selected = NO;
    self.changeButton.selected = NO;
    self.flashlightButton.hidden = NO;
    self.previewImageView.image = nil;
    [self.captureSession startRunning];
}

- (UIButton *)changeButton {
    if (!_changeButton) {
        _changeButton = [UIButton buttonWithType:UIButtonTypeCustom];
        _changeButton.frame = CGRectMake(kScreenWidth - 120, kScreenHeight - 125, 75, 75);
        [_changeButton addTarget:self
                           action:@selector(changeButtonTouchUpInside:)
                 forControlEvents:UIControlEventTouchUpInside];

        [_changeButton setImage:[UIImage lg_imageInBundleNamed:@"ic-camera-change-normal"]
                        forState:UIControlStateNormal];
        [_changeButton setImage:[UIImage lg_imageInBundleNamed:@"ic-camera-change-selected"]
                        forState:UIControlStateSelected];
    }
    return _changeButton;
}

- (void)changeButtonTouchUpInside:(UIButton *)sender {
    if (!sender.selected) { // 切换前后摄像头
        if (self.useFrontCamera) {
            self.position = AVCaptureDevicePositionBack;
        } else {
            self.position = AVCaptureDevicePositionFront;
        }
        self.useFrontCamera = !self.useFrontCamera;
        [self setupCamera];
    } else {
        if ([self.delegate respondsToSelector:@selector(watermarkCameraViewController:takeImage:)]) {
            [self.delegate watermarkCameraViewController:self takeImage:self.previewImageView.image];
        }
    }

}


- (AVCaptureDevice *)captureDeviceWithPosition:(AVCaptureDevicePosition)position {
    NSArray *devices = [AVCaptureDevice devicesWithMediaType:AVMediaTypeVideo];
    for ( AVCaptureDevice *device in devices )
        if ( device.position == position ){
            return device;
        }
    return nil;
}


- (UIButton *)shootButton {
    if (!_shootButton) {
        _shootButton = [UIButton buttonWithType:UIButtonTypeCustom];
        _shootButton.frame = CGRectMake((kScreenWidth - 75) / 2.0 , kScreenHeight - 125, 75, 75);
        [_shootButton addTarget:self
                action:@selector(shootButtonTouchUpInside:)
               forControlEvents:UIControlEventTouchUpInside];
        [_shootButton setImage:[UIImage lg_imageInBundleNamed:@"ic-camera-shoot-normal"]
                                forState:UIControlStateNormal];
        [_shootButton setImage:[[UIImage alloc] init]
                                forState:UIControlStateSelected];
    }
    return _shootButton;
}

- (UIButton *)flashlightButton {
    if (!_flashlightButton) {
        _flashlightButton = [UIButton buttonWithType:UIButtonTypeCustom];
        _flashlightButton.frame = CGRectMake(CGRectGetWidth([UIScreen mainScreen].bounds) - 40 - 15, 30, 40, 40);
        [_flashlightButton setImage:[UIImage lg_imageInBundleNamed:@"ic-camera-flash-auto"] forState:UIControlStateNormal];
        [_flashlightButton addTarget:self action:@selector(flashlightButtonTouchUpInside:) forControlEvents:UIControlEventTouchUpInside];


    }
    return _flashlightButton;
}

- (void)flashlightButtonTouchUpInside:(UIButton *)sender {
    self.flashModeFlag += 1;
    AVCaptureFlashMode mode = AVCaptureFlashModeAuto;
    NSUInteger index = self.flashModeFlag % 3;
    switch (index) {

        case 0: {
             mode = AVCaptureFlashModeAuto;

            [self.flashlightButton setImage:[UIImage lg_imageInBundleNamed:@"ic-camera-flash-auto"] forState:UIControlStateNormal];
        }
            break;
        case 1: {
            mode = AVCaptureFlashModeOn;

            [self.flashlightButton setImage:[UIImage lg_imageInBundleNamed:@"ic-camera-flash-on"] forState:UIControlStateNormal];
        }
            break;
        case 2: {
            mode = AVCaptureFlashModeOff;

            [self.flashlightButton setImage:[UIImage lg_imageInBundleNamed:@"ic-camera-flash-off"] forState:UIControlStateNormal];
        }
            break;
        default:
            break;
    }

    if ([_captureDevice lockForConfiguration:nil]) {
        // 自动闪光灯
        if ([_captureDevice isFlashModeSupported:mode]) {
            [_captureDevice setFlashMode:mode];
        }
        //自动白平衡
        if ([_captureDevice isWhiteBalanceModeSupported:AVCaptureWhiteBalanceModeAutoWhiteBalance]) {
            [_captureDevice setWhiteBalanceMode:AVCaptureWhiteBalanceModeAutoWhiteBalance];
        }
        [_captureDevice unlockForConfiguration];
    }
}


// 拍摄
- (void)shootButtonTouchUpInside:(UIButton *)sender {
    if (sender.selected) {
        

        return;
    }
    AVCaptureConnection * videoConnection = [self.imageOutput connectionWithMediaType:AVMediaTypeVideo];
    if (!videoConnection) {
        NSLog(@"take photo failed!");
        return;
    }

    [self.imageOutput captureStillImageAsynchronouslyFromConnection:videoConnection completionHandler:^(CMSampleBufferRef imageDataSampleBuffer, NSError *error) {
        if (imageDataSampleBuffer == NULL) {
            return;
        }
        self.shootButton.selected = YES;
        self.controlButton.selected = YES;
        self.changeButton.selected = YES;
        self.flashlightButton.hidden = YES;

        NSData * imageData = [AVCaptureStillImageOutput jpegStillImageNSDataRepresentation:imageDataSampleBuffer];
        UIImage *image = [UIImage imageWithData:imageData];
        UIImage *clipScaleImage = [image lg_clipScaleImageToSize:CGSizeMake(750, 1000)];

        UIImage *watermarkImage = nil;
        if (self.watermarkText.length > 0) {
            watermarkImage = [clipScaleImage lg_imageWithWatermarkText:self.watermarkText];
        } else if (self.watermarkView) {
            watermarkImage = [clipScaleImage lg_imageWithWatermarkView:self.watermarkView];
        } else if (self.watermarkImage) {
            watermarkImage = [clipScaleImage lg_imageWithWatermarkImage:self.watermarkImage
                                                                   rect:self.watermarkImageRect];
        } else {
            watermarkImage = clipScaleImage;
        }

        self.previewImageView.image = watermarkImage;

        [self.captureSession stopRunning];
    }];
}

- (void)setWatermarkText:(NSString *)watermarkText {
    if ([_watermarkText isEqualToString:watermarkText]) {
        return;
    }
    _watermarkText = [watermarkText mutableCopy];

    self.watermarkAttributedString = [[NSAttributedString alloc] initWithString:_watermarkText
                                                                     attributes:@{
                                                                             NSShadowAttributeName: self.textShadow,
                                                                             NSFontAttributeName: [UIFont systemFontOfSize:15],
                                                                             NSForegroundColorAttributeName: [UIColor whiteColor],

                                                                     }];
    if (!_watermarkLabel) { // View 尚未初始化,不更新 UI
        return;
    }
    self.watermarkLabel.attributedText = self.watermarkAttributedString;
}

- (void)setWatermarkImage:(UIImage *)image rect:(CGRect)rect {
    self.watermarkImage = image;
    self.watermarkImageRect = rect;
}


@end
