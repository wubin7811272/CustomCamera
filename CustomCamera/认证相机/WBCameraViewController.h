//
//  WBCameraViewController.h
//  CustomCamera
//
//  Created by mac on 15/4/29.
//  Copyright (c) 2015年 mac. All rights reserved.
//

#import <UIKit/UIKit.h>
@protocol WBCameraViewControllerDelegate;
@interface WBCameraViewController : UIViewController

@property (nonatomic, assign) CGRect previewRect;
@property (nonatomic, assign) BOOL isStatusBarHiddenBeforeShowCamera;
@property (nonatomic, assign) id<WBCameraViewControllerDelegate>delegate;
@end

@protocol WBCameraViewControllerDelegate <NSObject>

@optional
- (void)updataImageWithArray:(NSArray *)imageArr;

@end