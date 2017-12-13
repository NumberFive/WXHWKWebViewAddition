//
//  TestViewController.m
//  WXHWKWebViewAddition
//
//  Created by 伍小华 on 2017/12/12.
//  Copyright © 2017年 wxh. All rights reserved.
//

#import "TestViewController.h"
#import "TestView.h"
#import "UIViewController+WXHWKWebView.h"
#import <WebKit/WebKit.h>

@interface TestViewController ()<WKScriptMessageHandler>
@property (nonatomic, strong) TestView *testView;
@end

@implementation TestViewController
- (void)viewDidLoad {
    [super viewDidLoad];
    
    [self.view addSubview:self.testView];
    self.testView.frame = self.view.bounds;
    self.testView.backgroundColor = [UIColor grayColor];
    
    UIButton *button = [UIButton buttonWithType:UIButtonTypeCustom];
    button.frame = CGRectMake(0, self.view.frame.size.height-100, self.view.frame.size.width, 100);
    [button setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    [button setTitle:@"调用js方法" forState:UIControlStateNormal];
    button.backgroundColor = [UIColor brownColor];
    [button addTarget:self action:@selector(buttonAction) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:button];
    
    [self.testView.backButton addTarget:self action:@selector(backButtonAction) forControlEvents:UIControlEventTouchUpInside];
    
    [self registerWebView:self.testView.webView];
    [self addScriptMessageHandlerForNames:@[@"TestA",@"TestB",@"TestC"]];
}
- (void)backButtonAction
{
    [self dismissViewControllerAnimated:YES completion:nil];
}
- (void)buttonAction
{
    [self javaScript:@"changeContent"
          parameters:@[@"say:\"hello world\""]
          completion:^(id x, NSError *error) {
              if (error) {
                  NSLog(@"%@",error.localizedDescription);
              }
          }];
}
- (void)dealloc
{
    NSLog(@"TestViewController dealloc");
}
- (void)webButtonDidTap
{
    NSLog(@"webButtonDidTap");
}

- (void)webButtonDidTapWithData:(id)data
{
    NSLog(@"webButtonDidTapWithData: %@",data);
}
#pragma mark - WKScriptMessageHandler
- (void)userContentController:(WKUserContentController *)userContentController
      didReceiveScriptMessage:(WKScriptMessage *)message
{
    NSLog(@"%@",message.body);
}

- (TestView *)testView
{
    if (!_testView) {
        _testView = [[TestView alloc] init];
    }
    return _testView;
}
@end
