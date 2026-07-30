#import <UIKit/UIKit.h>

// ═══════════════════════════════════════════════════
// 可自定义文字内容（修改下面的字符串即可）
// ═══════════════════════════════════════════════════
static NSString *CUSTOM_TEXT = @"⚠️ 本IPA为elisif公共服专用\n使用NSDelta的\n二改patcher修改\n仅供学习交流\n严禁商业用途\n24小时内请删除";
static NSString *SUBTITLE_TEXT = nil;   // nil = 不显示副标题
static NSTimeInterval DISPLAY_DURATION = 4.0; // 显示秒数
static CGFloat FONT_SIZE = 20.0;
// ═══════════════════════════════════════════════════

%hook CTAppController

- (void)applicationDidFinishLaunching:(id)app {
    %orig;

    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 1.0 * NSEC_PER_SEC),
                   dispatch_get_main_queue(), ^{
        [self _showOverlay];
    });
}

%new
- (void)_showOverlay {
    UIWindow *win = nil;
    if (@available(iOS 13.0, *)) {
        for (UIScene *scene in [UIApplication sharedApplication].connectedScenes) {
            if (![scene isKindOfClass:[UIWindowScene class]]) continue;
            UIWindowScene *ws = (UIWindowScene *)scene;
            for (UIWindow *w in ws.windows) {
                if (w.isKeyWindow) { win = w; break; }
            }
        }
    }
    if (!win) win = [UIApplication sharedApplication].keyWindow;
    if (!win) return;

    CGFloat w = win.bounds.size.width;
    CGFloat h = win.bounds.size.height;

    // 半透明遮罩
    UIView *overlay = [[UIView alloc] initWithFrame:win.bounds];
    overlay.backgroundColor = [[UIColor blackColor] colorWithAlphaComponent:0.55];
    overlay.tag = 0xDEAD;
    overlay.alpha = 0;

    // 主文字
    UILabel *label = [[UILabel alloc] initWithFrame:CGRectMake(30, h * 0.35, w - 60, 120)];
    label.text = CUSTOM_TEXT;
    label.textColor = [UIColor whiteColor];
    label.font = [UIFont boldSystemFontOfSize:FONT_SIZE];
    label.textAlignment = NSTextAlignmentCenter;
    label.numberOfLines = 0;
    [overlay addSubview:label];

    // 副标题
    if (SUBTITLE_TEXT) {
        UILabel *sub = [[UILabel alloc] initWithFrame:CGRectMake(30, h * 0.35 + 130, w - 60, 40)];
        sub.text = SUBTITLE_TEXT;
        sub.textColor = [UIColor colorWithWhite:0.8 alpha:1.0];
        sub.font = [UIFont systemFontOfSize:14];
        sub.textAlignment = NSTextAlignmentCenter;
        [overlay addSubview:sub];
    }

    // 底部提示
    UILabel *tip = [[UILabel alloc] initWithFrame:CGRectMake(0, h - 100, w, 30)];
    tip.text = @"tap to dismiss";
    tip.textColor = [UIColor colorWithWhite:0.5 alpha:1.0];
    tip.font = [UIFont systemFontOfSize:12];
    tip.textAlignment = NSTextAlignmentCenter;
    [overlay addSubview:tip];

    // 点击消失
    UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc]
        initWithTarget:self action:@selector(_dismissOverlay:)];
    [overlay addGestureRecognizer:tap];

    [win addSubview:overlay];

    // 淡入
    [UIView animateWithDuration:0.4 animations:^{ overlay.alpha = 1; }];

    // 自动淡出
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW,
        (int64_t)(DISPLAY_DURATION * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        [self _dismissOverlay:overlay];
    });
}

%new
- (void)_dismissOverlay:(id)sender {
    UIView *overlay;
    if ([sender isKindOfClass:[UITapGestureRecognizer class]]) {
        overlay = [(UITapGestureRecognizer *)sender view];
    } else {
        overlay = sender;
    }
    if (!overlay || overlay.tag != 0xDEAD) return;

    [UIView animateWithDuration:0.3 animations:^{ overlay.alpha = 0; }
                     completion:^(BOOL done) { [overlay removeFromSuperview]; }];
}

%end
