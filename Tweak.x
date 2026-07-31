// ============================================================
//  SplashText - 开屏自定义文字 dylib
//  修改下面的文字即可自定义显示内容
// ============================================================

#import <UIKit/UIKit.h>
#import <objc/runtime.h>

// ===== 在这里改文字 =====
static NSString *CUSTOM_TEXT = @"本IPA使用NSDelta的二改脚本\n仅供学习交流\n切勿商业使用\n请于24小时内删除";
static NSString *SUBTITLE_TEXT = nil;            // nil = 不显示副标题
static NSTimeInterval DISPLAY_DURATION = 4.0;    // 显示秒数
static CGFloat FONT_SIZE = 20.0;                 // 字体大小
// =====================

// 声明 CTAppController 及其私有方法
@interface CTAppController : NSObject
- (void)applicationDidFinishLaunching:(id)app;
- (void)_showOverlay;
- (void)_dismissOverlay:(id)overlay;
- (void)_dismissOverlayObj:(UIView *)overlay;
@end

#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-declarations"

%hook CTAppController

- (void)applicationDidFinishLaunching:(id)app {
    %orig;

    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 1.0 * NSEC_PER_SEC), dispatch_get_main_queue(), ^{
        UIWindow *win = nil;
        if (@available(iOS 13.0, *)) {
            for (UIScene *scene in [UIApplication sharedApplication].connectedScenes) {
                if ([scene isKindOfClass:[UIWindowScene class]]) {
                    UIWindowScene *windowScene = (UIWindowScene *)scene;
                    for (UIWindow *w in windowScene.windows) {
                        if (w.isKeyWindow) { win = w; break; }
                    }
                }
            }
        }
        if (!win) win = [UIApplication sharedApplication].keyWindow;
        if (!win) return;

        [self _showOverlay];

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

        UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(_dismissOverlayTap:)];
        objc_setAssociatedObject(tap, "ov", overlay, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
        [overlay addGestureRecognizer:tap];

        if (DISPLAY_DURATION > 0) {
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, DISPLAY_DURATION * NSEC_PER_SEC), dispatch_get_main_queue(), ^{
                [self _dismissOverlayObj:overlay];
            });
        }
    });
}

%new
- (void)_dismissOverlayTap:(UITapGestureRecognizer *)tap {
    UIView *overlay = objc_getAssociatedObject(tap, "ov");
    [self _dismissOverlayObj:overlay];
}

%new
- (void)_dismissOverlayObj:(UIView *)overlay {
    if (!overlay) return;
    [UIView animateWithDuration:0.3 animations:^{ overlay.alpha = 0; }
                     completion:^(BOOL f) { [overlay removeFromSuperview]; }];
}

%end

#pragma clang diagnostic pop
