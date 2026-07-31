// ============================================================
//  SplashText - 开屏自定义文字 dylib
//  修改下面的文字即可自定义显示内容
// ============================================================

// ===== 在这里改文字 =====
static NSString *CUSTOM_TEXT = @"本IPA使用NSDelta的二改脚本\n仅供学习交流\n切勿商业使用\n请于24小时内删除";
static NSString *SUBTITLE_TEXT = nil;            // nil = 不显示副标题
static NSTimeInterval DISPLAY_DURATION = 4.0;    // 显示秒数
static CGFloat FONT_SIZE = 20.0;                 // 字体大小
// =====================

#import <UIKit/UIKit.h>

// 声明 CTAppController 的私有方法，避免编译器报错
@interface CTAppController : NSObject
- (void)applicationDidFinishLaunching:(id)app;
@end

@interface CTAppController (SplashTextPrivate)
- (void)_showOverlay;
- (void)_dismissOverlay:(id)overlay;
@end

#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-declarations"

%hook CTAppController

- (void)applicationDidFinishLaunching:(id)app {
    %orig;

    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 1.0 * NSEC_PER_SEC), dispatch_get_main_queue(), ^{
        // 获取 keyWindow
        UIWindow *win = nil;
        if (@available(iOS 13.0, *)) {
            for (UIScene *scene in [UIApplication sharedApplication].connectedScenes) {
                if ([scene isKindOfClass:[UIWindowScene class]]) {
                    UIWindowScene *windowScene = (UIWindowScene *)scene;
                    for (UIWindow *w in windowScene.windows) {
                        if (w.isKeyWindow) {
                            win = w;
                            break;
                        }
                    }
                }
            }
        }
        if (!win) {
            win = [UIApplication sharedApplication].keyWindow;
        }
        if (!win) return;

        [self _showOverlay];

        // 半透明背景
        UIView *overlay = [[UIView alloc] initWithFrame:win.bounds];
        overlay.backgroundColor = [[UIColor blackColor] colorWithAlphaComponent:0.75];
        overlay.alpha = 0;
        overlay.tag = 9999;
        [win addSubview:overlay];

        // 主文字
        UILabel *mainLabel = [[UILabel alloc] initWithFrame:CGRectZero];
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

        // 副标题
        if (SUBTITLE_TEXT) {
            UILabel *subLabel = [[UILabel alloc] initWithFrame:CGRectZero];
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

        // 淡入动画
        [UIView animateWithDuration:0.4 animations:^{
            overlay.alpha = 1;
        }];

        // 点击或延时消失
        UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(_dismissOverlay:)];
        // 把 overlay 对象关联到手势上
        objc_setAssociatedObject(tap, "overlay", overlay, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
        [overlay addGestureRecognizer:tap];

        if (DISPLAY_DURATION > 0) {
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, DISPLAY_DURATION * NSEC_PER_SEC), dispatch_get_main_queue(), ^{
                [self _dismissOverlayObj:overlay];
            });
        }
    });
}

%new
- (void)_showOverlay {
    // 占位，适配原始方法
}

%new
- (void)_dismissOverlay:(UITapGestureRecognizer *)tap {
    UIView *overlay = objc_getAssociatedObject(tap, "overlay");
    if (!overlay) {
        overlay = [tap.view superview] ? tap.view : nil;
    }
    [self _dismissOverlayObj:overlay ?: [UIApplication sharedApplication].keyWindow.viewWithTag:9999];
}

%new
- (void)_dismissOverlayObj:(UIView *)overlay {
    if (!overlay) return;
    [UIView animateWithDuration:0.3 animations:^{
        overlay.alpha = 0;
    } completion:^(BOOL finished) {
        [overlay removeFromSuperview];
    }];
}

%end

#pragma clang diagnostic pop
