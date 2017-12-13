//
//  ViewController.m
//  WXHWKWebViewAddition
//
//  Created by 伍小华 on 2017/12/12.
//  Copyright © 2017年 wxh. All rights reserved.
//

#import "ViewController.h"
#import "TestViewController.h"
@interface ViewController ()

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
}
- (IBAction)buttonAction:(UIButton *)sender {
    TestViewController *vc = [[TestViewController alloc] init];
    [self presentViewController:vc animated:YES completion:nil];
}



@end
