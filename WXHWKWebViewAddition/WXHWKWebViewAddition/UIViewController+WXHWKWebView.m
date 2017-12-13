//
//  UIViewController+WXHWKWebView.m
//  WXHWKWebViewAddition
//
//  Created by 伍小华 on 2017/12/13.
//  Copyright © 2017年 wxh. All rights reserved.
//

#import "UIViewController+WXHWKWebView.h"
#import <WebKit/WebKit.h>
#import <objc/runtime.h>
#import <WebKit/WKScriptMessageHandler.h>


//DEBUG 模式下打印日志,当前行
#ifdef DEBUG
# define DEBUGLOG(fmt, ...) NSLog((@"%s [Line %d] " fmt), __PRETTY_FUNCTION__, __LINE__, ##__VA_ARGS__);
#else
# define DEBUGLOG(...)
#endif


#pragma mark - WeakScriptMessageDelegate
@protocol WeakScriptMessageDelegate<NSObject>
- (void)weakUserContentController:(WKUserContentController *)userContentController
          didReceiveScriptMessage:(WKScriptMessage *)message;
@end

#pragma mark - WeakScriptMessageHandler
@interface WeakScriptMessageHandler : NSObject<WKScriptMessageHandler>
@property (nonatomic, weak) id<WeakScriptMessageDelegate> scriptDelegate;
@end

@implementation WeakScriptMessageHandler
- (instancetype)initWithDelegate:(id<WeakScriptMessageDelegate>)scriptDelegate
{
    self = [super init];
    if (self) {
        _scriptDelegate = scriptDelegate;
    }
    return self;
}

- (void)userContentController:(WKUserContentController *)userContentController
      didReceiveScriptMessage:(WKScriptMessage *)message
{
    if (self.scriptDelegate &&
        [self.scriptDelegate respondsToSelector:@selector(weakUserContentController:didReceiveScriptMessage:)])
    {
        [self.scriptDelegate weakUserContentController:userContentController
                               didReceiveScriptMessage:message];
    }
}
@end

#pragma mark - UIViewController+WXHWKWebView
static char const * const KWXHWebView= "KWXHWebView";
static char const * const KWXHWebDidLoadOperationQueue = "KWXHWebDidLoadOperationQueue";
static char const * const KWXHScriptMessageNames = "KWXHScriptMessageNames";

@interface UIViewController()<WeakScriptMessageDelegate>
@property (nonatomic, strong) WKWebView *wxhWebView;
@property (nonatomic, strong) NSOperationQueue *wxhWebDidLoadOperationQueue;
@property (nonatomic, strong) NSMutableArray *scriptMessageNames;
@end
@implementation UIViewController (WXHWKWebView)
- (void)registerWebView:(WKWebView *)webView
{
    if (!self.wxhWebView) {
        self.wxhWebView = webView;

        [self addScriptMessageHandlerForNames:@[@"WXHWKWebViewFunction",@"WXHWKWebViewDidLoad"]];
        [self addUserScript:self.wxhWebView];
        [self swizzledDealloc];
    }
}
- (void)addUserScript:(WKWebView *)webview
{
    NSString *path = [[NSBundle mainBundle] pathForResource:@"WXHWKWebViewAddition" ofType:@"js"];
    NSString *source = [NSString stringWithContentsOfFile:path encoding:NSUTF8StringEncoding error:nil];
    WKUserScript *script = [[WKUserScript alloc] initWithSource:source
                                                  injectionTime:WKUserScriptInjectionTimeAtDocumentStart
                                               forMainFrameOnly:NO];
    [self.wxhWebView.configuration.userContentController addUserScript:script];
}
- (void)swizzledDealloc
{
    static dispatch_once_t swizzledDealloc_once_t;
    dispatch_once(&swizzledDealloc_once_t,^{
        SEL originalSelector = NSSelectorFromString(@"dealloc");
        SEL swizzledSelector = @selector(additionDealloc);
        Class class = [self class];
        
        Method originalMethod = class_getInstanceMethod(class, originalSelector);
        Method swizzledMethod = class_getInstanceMethod(class, swizzledSelector);
        
        BOOL didAddMethod = class_addMethod([self class],
                                            originalSelector,
                                            method_getImplementation(swizzledMethod),
                                            method_getTypeEncoding(swizzledMethod));
        if (didAddMethod) {
            class_replaceMethod(class,
                                swizzledSelector,
                                method_getImplementation(originalMethod),
                                method_getTypeEncoding(originalMethod));
        } else {
            method_exchangeImplementations(originalMethod, swizzledMethod);
        }
    });
}
-(void)additionDealloc{
    DEBUGLOG(@"additionDealloc");
    [self.wxhWebDidLoadOperationQueue cancelAllOperations];
    self.wxhWebView.scrollView.delegate = nil;
    
    [self removeAllScriptMessageHandler];
    [self additionDealloc];
}

#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wobjc-protocol-method-implementation"
- (void)weakUserContentController:(WKUserContentController *)userContentController
          didReceiveScriptMessage:(WKScriptMessage *)message
{
    NSString *scriptMessageName = message.name;
    if ([scriptMessageName isEqualToString:@"WXHWKWebViewFunction"]) {
        id body = message.body;
        if ([body isKindOfClass:[NSDictionary class]]) {
            NSDictionary *dict = (NSDictionary *)body;
            NSString *selectorString = dict[@"selector"];
            if (selectorString.length) {
                BOOL hasObject = [selectorString containsString:@":"];
                SEL selector = NSSelectorFromString(selectorString);
                if ([self respondsToSelector:selector]) {
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Warc-performSelector-leaks"
                    if (hasObject) {
                        id object = dict[@"data"];
                        [self performSelector:selector withObject:object];
                    } else {
                        [self performSelector:selector];
                    }
#pragma clang diagnostic pop
                } else {
                    DEBUGLOG(@"unrecognized selector -: %@",selectorString);
                }
            }
        }
    } else if ([scriptMessageName isEqualToString:@"WXHWKWebViewDidLoad"]) {
        self.wxhWebDidLoadOperationQueue.suspended = NO;
    } else {
        if ([self respondsToSelector:@selector(userContentController:didReceiveScriptMessage:)]) {
            [self performSelector:@selector(userContentController:didReceiveScriptMessage:)
                       withObject:userContentController
                       withObject:message];
        }
    }
}
#pragma clang diagnostic pop

- (void)addWebOperationBlock:(void(^)(void))block_
{
    NSBlockOperation *operation = [NSBlockOperation blockOperationWithBlock:^{
        dispatch_async(dispatch_get_main_queue(),^{
            if (block_) { block_();}
        });
    }];
    [self.wxhWebDidLoadOperationQueue addOperation:operation];
}
- (void)javaScript:(NSString *)function
        parameters:(NSArray *)parameters
        completion:(void (^)(id x, NSError *error))completion
{
    NSString *script = function;
    if ([parameters count]) {
        NSString *string;
        NSInteger index = 0;
        for (id parameter in parameters) {
            if (index == 0) {
                string = [NSString stringWithFormat:@"'%@'",parameter];
            } else {
                string = [NSString stringWithFormat:@"%@,'%@'",string,parameter];
            }
            index++;
        }
        script = [NSString stringWithFormat:@"%@(%@)",script,string];
    } else {
        script = [NSString stringWithFormat:@"%@()",script];
    }
    __weak UIViewController *weakSelf = self;
    [self addWebOperationBlock:^{
        [weakSelf.wxhWebView evaluateJavaScript:script
                              completionHandler:completion];
    }];
}

- (void)addScriptMessageHandlerForNames:(NSArray<NSString *> *)names
{
    WKUserContentController *controller = self.wxhWebView.configuration.userContentController;
    WeakScriptMessageHandler *handle = [[WeakScriptMessageHandler alloc] initWithDelegate:self];
    for (NSString *script in names) {
        if (![self.scriptMessageNames containsObject:script]) {
            [self.scriptMessageNames addObject:script];
            [controller addScriptMessageHandler:handle name:script];
        }
    }
}
- (void)removeAllScriptMessageHandler
{
    for (NSString *script in self.scriptMessageNames) {
        WKUserContentController *controller = self.wxhWebView.configuration.userContentController;
        [controller removeScriptMessageHandlerForName:script];
    }
}
#pragma mark - Setter / Getter
- (WKWebView *)wxhWebView
{
    return objc_getAssociatedObject(self, KWXHWebView);
}
- (void)setWxhWebView:(WKWebView *)wxhWebView
{
    objc_setAssociatedObject(self, KWXHWebView, wxhWebView, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

- (NSOperationQueue *)wxhWebDidLoadOperationQueue
{
    NSOperationQueue *oprationQueue = objc_getAssociatedObject(self, KWXHWebDidLoadOperationQueue);
    if (!oprationQueue) {
        oprationQueue = [[NSOperationQueue alloc] init];
        oprationQueue.maxConcurrentOperationCount = 1;
        oprationQueue.suspended = YES;
        [self setWxhWebDidLoadOperationQueue:oprationQueue];
    }
    return oprationQueue;
}
- (void)setWxhWebDidLoadOperationQueue:(NSOperationQueue *)wxhWebDidLoadOperationQueue
{
    objc_setAssociatedObject(self, KWXHWebDidLoadOperationQueue, wxhWebDidLoadOperationQueue, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}
- (NSMutableArray *)scriptMessageNames
{
    NSMutableArray *array = objc_getAssociatedObject(self, KWXHScriptMessageNames);
    if (!array) {
        array = [NSMutableArray array];
        [self setScriptMessageNames:array];
    }
    return array;
}
- (void)setScriptMessageNames:(NSMutableArray *)scriptMessageNames
{
    objc_setAssociatedObject(self, KWXHScriptMessageNames, scriptMessageNames, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}
@end
