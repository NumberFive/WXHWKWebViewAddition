//
//  UIViewController+WXHWKWebView.h
//  WXHWKWebViewAddition
//
//  Created by 伍小华 on 2017/12/13.
//  Copyright © 2017年 wxh. All rights reserved.
//

#import <UIKit/UIKit.h>
@class WKWebView;
@interface UIViewController (WXHWKWebView)
- (void)registerWebView:(WKWebView *)webView;

- (void)addWebOperationBlock:(void(^)(void))block;

- (void)javaScript:(NSString *)function
        parameters:(NSArray *)parameters
        completion:(void (^)(id x, NSError *error))completion;

- (void)addScriptMessageHandlerForNames:(NSArray<NSString *> *)names;
@end
