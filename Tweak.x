// ============================================================
//  SplashText - 开屏自定义文字 dylib（零依赖，可注入 IPA）
//  修改下面的文字即可自定义显示内容
// ============================================================

#import <UIKit/UIKit.h>
#import <objc/runtime.h>

// ===== 在这里改文字 =====
static NSString *CUSTOM_TEXT = @"本IPA使用NSDelta的二改脚本修改\n原脚本由\ndennis96292\n制作\n仅供学习交流\n切勿商业使用\n请于24小时内删除";
static NSString *SUBTITLE_TEXT = nil;
static NSTimeInterval DISPLAY_DURATION = 4.0;
static CGFloat FONT_SIZE = 20.0;
// =====================

static IMP original_didFinishLaunching = NULL;

static void showOverlay(UIWindow *win) {
    UIView *overlay = [[UIView alloc] initWithFrame:win.bounds];
    overlay.backgroundColor = [[UIColor blackColor] colorWithAlphaComponent:0.75];
    overlay.alpha = 0;
    overlay.tag = 9999;
    [win addSubview:overlay];

    UILabel *mainLabel = [[UILabel alloc] init];
    mainLabel.text = CUSTOM_TEXT;
    mainLabel.textColor = [UIColor whiteColor];
    mainLabel.textAlignment = NSTextAlignmentCenter;
    mainLabel.font = [UIFont boldSystemFontOfSize:FONT_SIZE];
    mainLabel.numberOfLines = 0;
    mainLabel.translatesAutoresizingMaskIntoConstraints = NO;
    [overlay addSubview:mainLabel];

    [mainLabel.centerXAnchor constraintEqualToAnchor:overlay.centerXAnchor].active = YES;
    [mainLabel.centerYAnchor constraintEqualToAnchor:overlay.centerYAnchor constant:-20].active = YES;
    [mainLabel.leadingAnchor constraintGreaterThanOrEqualToAnchor:overlay.leadingAnchor constant:30].active = YES;
    [mainLabel.trailingAnchor constraintLessThanOrEqualToAnchor:overlay.trailingAnchor constant:-30].active = YES;

    if (SUBTITLE_TEXT) {
        UILabel *subLabel = [[UILabel alloc] init];
        subLabel.text = SUBTITLE_TEXT;
        subLabel.textColor = [UIColor lightGrayColor];
        subLabel.textAlignment = NSTextAlignmentCenter;
        subLabel.font = [UIFont systemFontOfSize:14.0];
        subLabel.numberOfLines = 0;
        subLabel.translatesAutoresizingMaskIntoConstraints = NO;
        [overlay addSubview:subLabel];
        [subLabel.centerXAnchor constraintEqualToAnchor:overlay.centerXAnchor].active = YES;
        [subLabel.topAnchor constraintEqualToAnchor:mainLabel.bottomAnchor constant:12].active = YES;
    }

    [UIView animateWithDuration:0.4 animations:^{ overlay.alpha = 1; }];

    UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc] initWithTarget:overlay action:@selector(dismissSelf:)];
    [overlay addGestureRecognizer:tap];
    tap.cancelsTouchesInView = YES;

    if (DISPLAY_DURATION > 0) {
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, DISPLAY_DURATION * NSEC_PER_SEC), dispatch_get_main_queue(), ^{
            [UIView animateWithDuration:0.3 animations:^{ overlay.alpha = 0; }
                             completion:^(BOOL f) { [overlay removeFromSuperview]; }];
        });
    }
}

static void hooked_didFinishLaunching(id self, SEL _cmd, id app) {
    // 调用原始实现
    if (original_didFinishLaunching) {
        ((void(*)(id, SEL, id))original_didFinishLaunching)(self, _cmd, app);
    }

    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 1.0 * NSEC_PER_SEC), dispatch_get_main_queue(), ^{
        UIWindow *win = nil;
        if (@available(iOS 13.0, *)) {
            for (UIScene *scene in [UIApplication sharedApplication].connectedScenes) {
                if ([scene isKindOfClass:[UIWindowScene class]]) {
                    for (UIWindow *w in ((UIWindowScene *)scene).windows) {
                        if (w.isKeyWindow) { win = w; break; }
                    }
                }
            }
        }
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-declarations"
        if (!win) win = [UIApplication sharedApplication].keyWindow;
#pragma clang diagnostic pop
        if (!win) return;

        showOverlay(win);
    });
}

// UIView category for dismiss gesture
@interface UIView (SplashDismiss)
- (void)dismissSelf:(UITapGestureRecognizer *)tap;
@end

@implementation UIView (SplashDismiss)
- (void)dismissSelf:(UITapGestureRecognizer *)tap {
    [UIView animateWithDuration:0.3 animations:^{ self.alpha = 0; }
                     completion:^(BOOL f) { [self removeFromSuperview]; }];
}
@end

__attribute__((constructor))
static void SplashTextInit(void) {
    Class cls = NSClassFromString(@"CTAppController");
    if (!cls) return;

    SEL sel = NSSelectorFromString(@"applicationDidFinishLaunching:");
    Method m = class_getInstanceMethod(cls, sel);
    if (!m) return;

    // 添加新实现，如果类已有该方法则替换
    IMP newImp = (IMP)hooked_didFinishLaunching;
    const char *types = method_getTypeEncoding(m);
    if (class_addMethod(cls, sel, newImp, types)) {
        original_didFinishLaunching = method_getImplementation(m);
    } else {
        original_didFinishLaunching = method_setImplementation(m, newImp);
    }
}
