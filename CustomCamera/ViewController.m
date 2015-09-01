//
//  ViewController.m
//  CustomCamera
//
//  Created by mac on 15/4/29.
//  Copyright (c) 2015年 mac. All rights reserved.
//

#import "ViewController.h"
#import "WBCameraViewController.h"
@interface ViewController ()

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor = [UIColor whiteColor];
    UIButton *button = [UIButton buttonWithType:UIButtonTypeCustom];
    button.frame = CGRectMake(0 , 64, 100, 100);
    [button setTitle:@"button" forState:UIControlStateNormal];
    button.backgroundColor = [UIColor redColor];
    [button addTarget:self action:@selector(btnClick) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:button];
}
- (void)btnClick
{
    [self presentViewController:[[WBCameraViewController alloc] init] animated:YES completion:nil];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
