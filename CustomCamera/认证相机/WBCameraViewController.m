//
//  WBCameraViewController.m
//  CustomCamera
//
//  Created by mac on 15/4/29.
//  Copyright (c) 2015年 mac. All rights reserved.
//

#import "WBCameraViewController.h"
#import "WBCameraSessionManager.h"
#import "UIImage+CropSize.h"
#import "WBCameraHeader.h"
@interface WBCameraViewController ()
{
    BOOL _isShowBtnView;
    int alphaTimes;
    CGPoint currTouchPoint;
}

@property (nonatomic,strong) UIImage *fontImage;//身份证正面
@property (nonatomic,strong) UIImage *backImage;//身份证反面

@property (nonatomic, strong) WBCameraSessionManager *captureManager;




@property (nonatomic, strong) UIView *bottomView;//除了顶部标题、拍照区域剩下的所有区域
@property (nonatomic, strong) UIView *topView;//网格、闪光灯、前后摄像头等按钮

@property (nonatomic, strong) NSMutableSet *cameraBtnSet;


@property (nonatomic,strong) UIImageView *showImageView;//照片展示图片
@property (nonatomic,strong) UIImageView *promptImageView;//提示图片

@property (nonatomic,strong) UIButton *takePhotoBtn;//拍照按钮
@property (nonatomic,strong) UIButton *showBtn1;//取消 重拍按钮
@property (nonatomic,strong) UIButton *showBtn2;//继续拍摄 提交照片按钮

@property (nonatomic,strong) UIButton *showImageBtn;//展示拍照之后的照片

@property (nonatomic,strong) NSMutableArray *flashArr;//闪光灯按钮数组

@property (nonatomic,strong) NSMutableArray *imageArr;//存放照片的数组




@end

@implementation WBCameraViewController
- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
        alphaTimes = -1;
        currTouchPoint = CGPointZero;
        
        _cameraBtnSet = [[NSMutableSet alloc] init];
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    _isShowBtnView = NO;
    self.fontImage = [UIImage imageNamed:@"头像页.png"];
    self.backImage = [UIImage imageNamed:@"国徽页.png"];
    
    
    self.view.backgroundColor = [UIColor blackColor];
    if (self.navigationController && !self.navigationController.navigationBarHidden)
    {
        self.navigationController.navigationBarHidden = YES;
    }
    
    //status bar
    if (!self.navigationController) {
        _isStatusBarHiddenBeforeShowCamera = [UIApplication sharedApplication].statusBarHidden;
        if ([UIApplication sharedApplication].statusBarHidden == NO) {
            //iOS7，需要plist里设置 View controller-based status bar appearance 为NO
            [[UIApplication sharedApplication] setStatusBarHidden:YES withAnimation:UIStatusBarAnimationSlide];
        }
    }
    
    //notification
//    [[NSNotificationCenter defaultCenter] removeObserver:self name:kNotificationOrientationChange object:nil];
//    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(orientationDidChange:) name:kNotificationOrientationChange object:nil];
    
    //session manager
    
    self.imageArr = [[NSMutableArray alloc] initWithCapacity:0];
    WBCameraSessionManager *manager = [[WBCameraSessionManager alloc] init];
    
    //AvcaptureManager
    if (CGRectEqualToRect(_previewRect, CGRectZero)) {
        self.previewRect = CGRectMake(0, SC_TOP_VIEW_HEIGHT, SC_DEVICE_SIZE.width, SC_DEVICE_SIZE.height-SC_BOTTOM_VIEW_HEIGHT-SC_TOP_VIEW_HEIGHT);
    }
    [manager configureWithParentLayer:self.view previewRect:_previewRect];
    
    [self.view addSubview:self.showImageView];
    self.captureManager = manager;
    [self.view addSubview:self.topView];
    [self.view addSubview:self.bottomView];

    
    [_captureManager.session startRunning];
    
#if SWITCH_SHOW_DEFAULT_IMAGE_FOR_NONE_CAMERA
    if (![UIImagePickerController isSourceTypeAvailable:UIImagePickerControllerSourceTypeCamera]) {
        [SVProgressHUD showErrorWithStatus:@"设备不支持拍照功能，给个妹纸给你喵喵T_T"];
        
        UIImageView *imgView = [[UIImageView alloc] initWithFrame:CGRectMake(0, CAMERA_TOPVIEW_HEIGHT, self.view.frame.size.width, self.view.frame.size.width)];
        imgView.clipsToBounds = YES;
        imgView.contentMode = UIViewContentModeScaleAspectFill;
        imgView.image = [UIImage imageWithContentsOfFile:[[NSBundle mainBundle] pathForResource:@"meizi" ofType:@"jpg"]];
        [self.view addSubview:imgView];
    }
#endif

}
- (UIImageView *)showImageView
{
    if (!_showImageView) {
        _showImageView = [[UIImageView alloc] initWithFrame:self.previewRect];
        _showImageView.contentMode = UIViewContentModeScaleAspectFill;
        _showImageView.clipsToBounds = YES;
        _showImageView.userInteractionEnabled = YES;
        
        [_showImageView addSubview:self.promptImageView];
        _showImageBtn = [UIButton buttonWithType:UIButtonTypeCustom];
        CGFloat showImageBtnWidth = 50.0f;
        CGFloat showImageBtnHeight = 50.0f;
        _showImageBtn.frame = CGRectMake(_showImageView.frame.size.width-10-showImageBtnWidth, _showImageView.frame.size.height-10-showImageBtnHeight, showImageBtnWidth, showImageBtnHeight);
        _showImageBtn.imageView.contentMode = UIViewContentModeScaleAspectFill;
        _showImageBtn.imageView.clipsToBounds = YES;
        [_showImageBtn addTarget:self action:@selector(showSomething) forControlEvents:UIControlEventTouchUpInside];
        _showImageBtn.enabled = NO;
        [_showImageView addSubview:_showImageBtn];
    }
    return _showImageView;
}
- (UIImageView *)promptImageView
{
    if (!_promptImageView) {
        _promptImageView = [[UIImageView alloc] initWithImage:self.fontImage];
        CGFloat promptImageViewHeight = (self.fontImage.size.height/self.fontImage.size.width)*50.0f;
        _promptImageView.frame = CGRectMake(0.0f, 0.0f, 50.0f, promptImageViewHeight);
        _promptImageView.center = CGPointMake(_showImageView.frame.size.width/2, _showImageView.frame.size.height/2);
    }
    return _promptImageView;
}
- (void)showSomething
{
    _takePhotoBtn.alpha = 0.0f;
    _takePhotoBtn.enabled = NO;
    
    //                UIImage *cropImage = [UIImage imageWithCGImage:CGImageCreateWithImageInRect([stillImage CGImage ], _previewRect)];
    //展示图片
    _showImageView.image = _imageArr[0];
    __selectImage = _imageArr[0];
    
    [_showImageBtn setBackgroundImage:nil forState:UIControlStateNormal];
    _showImageBtn.enabled = NO;
    
    //设置按钮的title
    [_showBtn1 setTitle:@"重拍" forState:UIControlStateNormal];
    _showBtn2.enabled = YES;
    [_showBtn2 setTitle:@"继续拍摄反面" forState:UIControlStateNormal];
    
    for (UIView *view in [_topView subviews]) {
        view.alpha = 0.0;
        if ([view isKindOfClass:[UIButton class]]) {
            UIButton *button = (UIButton *)view;
            button.enabled = NO;
        }
    }
    
    //移除
    [self.promptImageView removeFromSuperview];
}
//底部拍照View
- (UIView *)bottomView
{
    if (!_bottomView) {
        _bottomView = [[UIView alloc] initWithFrame:CGRectMake(0, SC_DEVICE_SIZE.height-SC_BOTTOM_VIEW_HEIGHT, SC_DEVICE_SIZE.width, SC_BOTTOM_VIEW_HEIGHT)];
        _bottomView.backgroundColor = [UIColor blackColor];
        
        _takePhotoBtn = [UIButton buttonWithType:UIButtonTypeCustom];
        _takePhotoBtn.frame = CGRectMake((_bottomView.frame.size.width-60.0f)/2, 5.0f, 60.0f, 60.0f);
        [_takePhotoBtn setBackgroundImage:[UIImage imageNamed:@"按钮.png"] forState:UIControlStateNormal];
        _takePhotoBtn.layer.cornerRadius = 30.0f;
        [_takePhotoBtn addTarget:self action:@selector(takePictureBtnPressed:) forControlEvents:UIControlEventTouchUpInside];
        [_bottomView addSubview:_takePhotoBtn];
        
        _showBtn1 = [UIButton buttonWithType:UIButtonTypeCustom];
        _showBtn1.frame = CGRectMake(10, 0, 80.0f, SC_BOTTOM_VIEW_HEIGHT);
        [_showBtn1 setContentHorizontalAlignment:UIControlContentHorizontalAlignmentLeft];
        [_showBtn1 setTitle:@"取消" forState:UIControlStateNormal];
        [_showBtn1 setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
        [_showBtn1 addTarget:self action:@selector(doSomething:) forControlEvents:UIControlEventTouchUpInside];
        [_bottomView addSubview:_showBtn1];
        
        _showBtn2 = [UIButton buttonWithType:UIButtonTypeCustom];
        _showBtn2.frame = CGRectMake(_bottomView.frame.size.width-120.0f, 0.0f, 110.0f, SC_BOTTOM_VIEW_HEIGHT);
        [_showBtn2 setContentHorizontalAlignment:UIControlContentHorizontalAlignmentRight];
        [_showBtn2 setTitle:@"" forState:UIControlStateNormal];
        [_showBtn2 setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
        [_showBtn2 addTarget:self action:@selector(doSomething:) forControlEvents:UIControlEventTouchUpInside];
        _showBtn2.enabled = NO;
        [_bottomView addSubview:_showBtn2];
    }
    return _bottomView;
}
- (BOOL)prefersStatusBarHidden
{
    return YES;
}
//上部管理View
- (UIView *)topView
{
    if (!_topView)
    {
        _topView= [[UIView alloc] initWithFrame:CGRectMake(0, 0, SC_DEVICE_SIZE.width, SC_TOP_VIEW_HEIGHT)];
        _topView.backgroundColor = [UIColor blackColor];
        
        UIImageView *flashImageView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"闪光灯.png"]];
        flashImageView.frame = CGRectMake(10.0f, 10.0f, 20.0f, 20.0f);
        [_topView addSubview:flashImageView];
        
        if (!_flashArr) {
            _flashArr = [[NSMutableArray alloc] initWithCapacity:0];
        }
        NSArray *titleArr = @[@"自动",@"打开",@"关闭"];
        for (int i=0; i<3; i++) {
            UIButton *flashBtn = [UIButton buttonWithType:UIButtonTypeCustom];
            [flashBtn setTitle:titleArr[i] forState:UIControlStateNormal];
            flashBtn.frame = CGRectMake(flashImageView.frame.origin.x+flashImageView.frame.size.width, 10.0f, 40.0f, 20.0f);
            [flashBtn addTarget:self action:@selector(flashBtnPressed:) forControlEvents:UIControlEventTouchUpInside];
            [_flashArr addObject:flashBtn];
        }
        UIButton *button = _flashArr[0];
        [button setTitle:@"自动" forState:UIControlStateNormal];
        [_topView addSubview:button];
        
        UIButton *switchCameraBtn = [UIButton buttonWithType:UIButtonTypeCustom];
        switchCameraBtn.frame = CGRectMake(_topView.frame.size.width-30.0f, 10.0f, 25.0f, 25.0f);

        [switchCameraBtn setBackgroundImage:[UIImage imageNamed:@"旋转.png"] forState:UIControlStateNormal];
        [switchCameraBtn addTarget:self action:@selector(switchCameraBtnPressed:) forControlEvents:UIControlEventTouchUpInside];
        [_topView addSubview:switchCameraBtn];
    }
    return _topView;
}
//拍照页面，切换前后摄像头按钮按钮
- (void)switchCameraBtnPressed:(UIButton*)sender {
    sender.selected = !sender.selected;
    [_captureManager switchCamera:sender.selected];
}

//拍照页面，闪光灯按钮
- (void)flashBtnPressed:(UIButton*)sender {
    UIButton *autoBtn = _flashArr[0];
    UIButton *openBtn = _flashArr[1];

    AVCaptureFlashMode flashMode = AVCaptureFlashModeAuto;
    if (sender == autoBtn)
    {
        if (_isShowBtnView == NO) {
            [self openBtnWith:YES];
            _isShowBtnView = YES;
        }else
        {
            [self openBtnWith:NO];
            [autoBtn setTitle:@"自动" forState:UIControlStateNormal];
            _isShowBtnView = NO;
            flashMode = AVCaptureFlashModeAuto;
        }
        
    }else
    {
        if (_isShowBtnView == NO) {
            [self openBtnWith:YES];
            _isShowBtnView = YES;
        }else
        {
            [self openBtnWith:NO];
            _isShowBtnView = NO;
            [autoBtn setTitle:sender.titleLabel.text forState:UIControlStateNormal];
            if (sender == openBtn) {
                flashMode = AVCaptureFlashModeOn;
            }else
            {
                flashMode = AVCaptureFlashModeOff;
            }
        }
    }
   

    [_captureManager switchFlashMode:flashMode];
}
- (void)openBtnWith:(BOOL)isOpen
{
    UIButton *autoBtn = _flashArr[0];
    UIButton *openBtn = _flashArr[1];
    UIButton *closBtn = _flashArr[2];
    if (isOpen == YES) {
        [UIView animateWithDuration:0.35 animations:^{
            [autoBtn setTitle:@"自动" forState:UIControlStateNormal];
            
            openBtn.frame = CGRectMake(autoBtn.frame.origin.x+autoBtn.frame.size.width, 10.0f, 40.0f, 20.0f);
            [openBtn setTitle:@"打开" forState:UIControlStateNormal];
            [_topView addSubview:openBtn];
            
            closBtn.frame = CGRectMake(openBtn.frame.origin.x+openBtn.frame.size.width, 10.0f, 40.0f, 20.0f);
            [closBtn setTitle:@"关闭" forState:UIControlStateNormal];
            [_topView addSubview:closBtn];
        } completion:nil];
    }else
    {
        [UIView animateWithDuration:0.35 animations:^{
            [autoBtn setTitle:@"自动" forState:UIControlStateNormal];
            
            openBtn.frame = CGRectMake(autoBtn.frame.origin.x+autoBtn.frame.size.width, 10.0f, 40.0f, 20.0f);
            [openBtn setTitle:@"打开" forState:UIControlStateNormal];
           
            
            closBtn.frame = CGRectMake(openBtn.frame.origin.x+openBtn.frame.size.width, 10.0f, 40.0f, 20.0f);
            [closBtn setTitle:@"关闭" forState:UIControlStateNormal];
            
        } completion:^(BOOL finished) {
            [openBtn removeFromSuperview];
            [closBtn removeFromSuperview];
        }];

    }
    
}
//拍照展示View

- (void)doSomething:(UIButton *)sender
{
    if (sender == _showBtn1)
    {
        
        if ([_showBtn1.titleLabel.text isEqualToString:@"取消"])
        {
            //取消
            [self dismissViewControllerAnimated:YES completion:nil];
        }else
        {
            //重拍
            //清除数组中存取的上一张照片
            [_imageArr removeAllObjects];
            _showImageView.image = nil;
            
            [_showImageBtn setBackgroundImage:nil forState:UIControlStateNormal];
            _showImageBtn.enabled = NO;
            
            //修改按钮的标题并且显示拍照按钮
            [_showBtn1 setTitle:@"取消" forState:UIControlStateNormal];
            _showBtn2.enabled = YES;
            [_showBtn2 setTitle:@"" forState:UIControlStateNormal];
            _takePhotoBtn.alpha = 1.0f;
            _takePhotoBtn.enabled = YES;
            for (UIView *view in [_topView subviews]) {
                view.alpha = 1.0f;
                if ([view isKindOfClass:[UIButton class]]) {
                    UIButton *button = (UIButton *)view;
                    button.enabled = YES;
                }
            }
            if (_imageArr.count==1) {
                self.promptImageView.image = self.backImage;
            }else
            {
                self.promptImageView.image = self.fontImage;
            }
            [_showImageView addSubview:self.promptImageView];
        }
    }else
    {
        if ([_showBtn2.titleLabel.text isEqualToString:@"继续拍摄反面"])
        {
            //继续拍摄反面
            //展示上一张拍摄的照片
            [_showImageBtn setBackgroundImage:_imageArr[0] forState:UIControlStateNormal];
            _showImageBtn.enabled = YES;
            //修改按钮的标题并且显示拍照按钮
            _showImageView.image = nil;
            [_showBtn1 setTitle:@"取消" forState:UIControlStateNormal];
            [_showBtn2 setTitle:@"" forState:UIControlStateNormal];
            _showBtn2.enabled = NO;
            _takePhotoBtn.alpha = 1.0f;
            _takePhotoBtn.enabled = YES;
            
            for (UIView *view in [_topView subviews]) {
                view.alpha = 1.0f;
                if ([view isKindOfClass:[UIButton class]]) {
                    UIButton *button = (UIButton *)view;
                    button.enabled = YES;
                }
            }
            //重新添加提示文字图片
            [_showImageView addSubview:self.promptImageView];
        }else
        {
            //提交照片
            if ([self.delegate respondsToSelector:@selector(updataImageWithArray:)]) {
                [self.delegate updataImageWithArray:_imageArr];
            }
        }
    }
    
}

static UIImage *__selectImage;
- (void)takePictureBtnPressed:(UIButton *)sender
{
#if SWITCH_SHOW_DEFAULT_IMAGE_FOR_NONE_CAMERA
    if (![UIImagePickerController isSourceTypeAvailable:UIImagePickerControllerSourceTypeCamera]) {
        [SVProgressHUD showErrorWithStatus:@"设备不支持拍照功能T_T"];
        return;
    }
#endif
    
    [_captureManager takePicture:^(UIImage *stillImage) {
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
            //异步操作代码块
            dispatch_async(dispatch_get_main_queue(), ^{
                //回到主线程操作代码块
                
                //隐藏拍照按钮并且不让其能够点击
                _takePhotoBtn.alpha = 0.0f;
                _takePhotoBtn.enabled = NO;

//                UIImage *cropImage = [UIImage imageWithCGImage:CGImageCreateWithImageInRect([stillImage CGImage ], _previewRect)];
                //展示图片
                _showImageView.image = stillImage;
                __selectImage = stillImage;
                [_imageArr addObject:stillImage];
                
                
                //设置按钮的title
                [_showBtn1 setTitle:@"重拍" forState:UIControlStateNormal];
                for (UIView *view in [_topView subviews]) {
                    view.alpha = 0.0f;
                    if ([view isKindOfClass:[UIButton class]]) {
                        UIButton *button = (UIButton *)view;
                        button.enabled = NO;
                    }
                }
                //第一次拍照完毕之后切换提示文字 并且移除屏幕
                _promptImageView.image = self.backImage;
                [_promptImageView removeFromSuperview];
                _showBtn2.enabled = YES;
                if (_imageArr.count>=2) {
                    [_showBtn2 setTitle:@"提交照片" forState:UIControlStateNormal];
                }else
                {
                    [_showBtn2 setTitle:@"继续拍摄反面" forState:UIControlStateNormal];
                }
                
            });
        });
}];
}
- (UIImage *)cropImageWithImage:(UIImage *)image
{
    CGPoint startPoint = [self.showImageView convertPoint:CGPointZero toView:self.showImageView];
    CGPoint endPoint = [self.showImageView convertPoint:CGPointMake(CGRectGetMaxX(self.showImageView.bounds), CGRectGetMaxY(self.showImageView.bounds)) toView:self.showImageView];
    
    //这里找到的点其实是imageView在zoomScale为1的时候的实际点，而zoomScale为1的时候imageView.frame.size并不一定是实际的图片size，所以需要修正
    //    _pr(CGRectMake(startPoint.x, startPoint.y, (endPoint.x-startPoint.x), (endPoint.y-startPoint.y)));
    //zoomScale为1的时候的imageFrame
    //    _pr(CGRectMake(self.imageView.frame.origin.x/self.scrollView.zoomScale, self.imageView.frame.origin.y/self.scrollView.zoomScale, self.imageView.frame.size.width/self.scrollView.zoomScale, self.imageView.frame.size.height/self.scrollView.zoomScale));
    
    //这里获取的是实际宽度和zoomScale为1的frame宽度的比例
    
    CGRect cropRect = CGRectMake(startPoint.x, startPoint.y, (endPoint.x-startPoint.x), (endPoint.y-startPoint.y));
     UIImage *cropImage = [image croppedImage:cropRect];
    
    return cropImage;
    
}
- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

@end
