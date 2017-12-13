//
//  TestView.h
//  WXHWKWebViewAddition
//
//  Created by 伍小华 on 2017/12/12.
//  Copyright © 2017年 wxh. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <WebKit/WebKit.h>
@interface TestView : UIView
@property (nonatomic, strong) WKWebView *webView;
@property (nonatomic, strong) UIButton *backButton;
@end
