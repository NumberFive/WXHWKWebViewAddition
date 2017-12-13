//
//  TestView.m
//  WXHWKWebViewAddition
//
//  Created by 伍小华 on 2017/12/12.
//  Copyright © 2017年 wxh. All rights reserved.
//

#import "TestView.h"

@implementation TestView
- (instancetype)init
{
    self = [super init];
    if (self) {
        [self addSubview:self.webView];
        NSURL *url = [[NSBundle mainBundle] URLForResource:@"htmlTest" withExtension:@"html"];
        NSURLRequest *request = [NSURLRequest requestWithURL:url];
        [_webView loadRequest:request];
        
        [self addSubview:self.backButton];
    }
    return self;
}
- (void)layoutSubviews
{
    [super layoutSubviews];
    self.backButton.frame = CGRectMake(0, 30, 100, 64);
    self.webView.frame = self.bounds;
}
- (WKWebView *)webView
{
    if (!_webView) {
        _webView = [[WKWebView alloc] init];
    }
    return _webView;
}
- (UIButton *)backButton
{
    if (!_backButton) {
        _backButton = [UIButton buttonWithType:UIButtonTypeCustom];
        _backButton.backgroundColor = [UIColor brownColor];
        [_backButton setTitle:@"返回" forState:UIControlStateNormal];
        [_backButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    }
    return _backButton;
}

@end
