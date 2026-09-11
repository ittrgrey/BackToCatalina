#include "BackToCatalina.h"
#include "ZKSwizzle.h"
#include <objc/runtime.h>

extern void objc_storeStrong(id __unsafe_unretained *location, id value);

@interface CombinedSidebarTabGroupToolbarButton : NSView @end

@interface UnifiedFieldBezelView : NSTextField @end

@interface UnifiedFieldButtonMetrics : NSObject @end

@interface UnifiedField : NSTextField
@property (weak, nonatomic) UnifiedFieldBezelView *bezelView;
@end

@interface ToolbarController : NSObject
- (UnifiedField *)unifiedField;
@end

@interface NSView (Corner)
- (CGFloat)_cornerRadius;
- (void)_setCornerRadius:(CGFloat)cornerRadius;
@end

hook(WindowControlShadowView)
+ (id)windowControlShadowViewWithWindow:(NSWindow *)wind {
    return nil;
}
endhook

hook(BadgeButton)
- (BOOL)allowsVibrancy {
    return NO;
}
endhook

hook(UnifiedField)
- (NSSize)_defaultButtonSize {
    return CGSizeMake(22, 28);
}
- (CGFloat)_defaultButtonYOffset {
    return -1;
}
+ (CGFloat)urlTextYOffset {
    return -2;
}
- (CGFloat)_siteIconYOffset {
    return 4;
}
- (CGFloat)_urlTextHeight {
    return isTahoeOrLater ? 26 : 23;
}
- (CGFloat)_urlFieldHeight {
    return [self _urlTextHeight];
}
- (CGFloat)_progressBarDrawingOffset {
    return 0;
}
- (CGFloat)marginBeforeFirstComponent {
    return 7;
}
- (CGFloat)_progressBarCornerRadius {
    NSUInteger browsingMode = ZKHookIvar(self, NSUInteger, "_browsingMode");
    if (browsingMode == 1) {
        return 4.5;
    } else {
        return 3.5;
    }
}
- (void)_updateProgressFillCornerRadius {
    _orig(void);
    if (isTahoeOrLater) {
        NSView *progressFillLayerClipView = ZKHookIvar(self, NSView *, "_progressFillLayerClipView");
        [progressFillLayerClipView _setCornerRadius:[self _progressBarCornerRadius]];
    }
}
endhook

hook(ToolbarController)
- (UnifiedField *)_createUnifiedFieldForToolbar:(BOOL)toolbar {
    UnifiedField *field = _orig(UnifiedField *, toolbar);
    field.controlSize = NSControlSizeRegular;
    return field;
}

- (NSView *)unifiedFieldContainerView {
    if (isTahoeOrLater) {
        UnifiedFieldBezelView *existingBezelView = ZKHookIvar(self, UnifiedFieldBezelView *, "_unifiedFieldBezelView");
        if (!existingBezelView) {
            UnifiedFieldBezelView *bezelView = [[NSClassFromString(@"UnifiedFieldBezelView") alloc] init];
            bezelView.autoresizingMask = NSViewWidthSizable | NSViewHeightSizable;
            objc_storeStrong((id __unsafe_unretained *)ZKIvarPointer(self, "_unifiedFieldBezelView"), bezelView);
            UnifiedField *unifiedField = ((ToolbarController *)self).unifiedField;
            unifiedField.bezelView = bezelView;
        }
    }
    NSView *view = _orig(NSView *);
    return view;
}
endhook

BOOL pendingCellFrameOffsetIncrease = NO;

hook(FavoriteButtonCell)
- (NSSize)cellSize {
    NSSize size = _orig(NSSize);
    if (isTahoeOrLater && ZKHookIvar(self, NSInteger, "_buttonStyle") == 0) {
        size.width += 8;
    }
    return size;
}
- (void)drawInteriorWithFrame:(CGRect)frame inView:(NSView *)view {
    if (isTahoeOrLater) {
        pendingCellFrameOffsetIncrease = YES;
    }
    _orig(void, frame, view);
    pendingCellFrameOffsetIncrease = NO;
}
endhook

hook(RolloverTextButtonCell)
- (void)drawInteriorWithFrame:(CGRect)frame inView:(NSView *)view {
    if (pendingCellFrameOffsetIncrease) {
        frame.origin.y += 1;
    }
    _orig(void, frame, view);
}
endhook

hook(CombinedSideBarTabGroupImageView)
- (BOOL)allowsVibrancy {
    return NO;
}
endhook

static void * ConstraintsWhenHasTitlePropertyKey = &ConstraintsWhenHasTitlePropertyKey;
static void * ConstraintWhenNoTitlePropertyKey = &ConstraintWhenNoTitlePropertyKey;

hook(CombinedSidebarTabGroupToolbarButton)
- (NSArray<NSLayoutConstraint *> *)constraintsWhenHasTitle {
    return objc_getAssociatedObject(self, ConstraintsWhenHasTitlePropertyKey);
}

- (void)setConstraintsWhenHasTitle:(NSArray<NSLayoutConstraint *> *)constraintsWhenHasTitle {
    objc_setAssociatedObject(self, ConstraintsWhenHasTitlePropertyKey, constraintsWhenHasTitle, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

- (NSLayoutConstraint *)constraintWhenNoTitle {
    return objc_getAssociatedObject(self, ConstraintWhenNoTitlePropertyKey);
}

- (void)setConstraintWhenNoTitle:(NSLayoutConstraint *)constraintWhenNoTitle {
    objc_setAssociatedObject(self, ConstraintWhenNoTitlePropertyKey, constraintWhenNoTitle, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

- (BOOL)allowsVibrancy {
    return NO;
}

- (instancetype)initWithSidebarVisibility:(BOOL)visibility privateBrowsing:(BOOL)private {
    CombinedSidebarTabGroupToolbarButton *combined = _orig(CombinedSidebarTabGroupToolbarButton *, visibility, private);
    NSButton *sidebarButton = ZKHookIvar(combined, NSButton *, "_sidebarButton");
    sidebarButton.imagePosition = NSImageAbove;
    NSTextField *privateBrowsingLabel = ZKHookIvar(combined, NSTextField *, "_privateBrowsingLabel");
    privateBrowsingLabel.stringValue = [NSString stringWithFormat:@"  %@", privateBrowsingLabel.stringValue];
    privateBrowsingLabel.font = [NSFont systemFontOfSize:13];
    NSButton *tabGroupPickerButton = ZKHookIvar(combined, NSButton *, "_tabGroupPickerButton");
    tabGroupPickerButton.font = [NSFont systemFontOfSize:13];
    [self setConstraintsWhenHasTitle:@[
        [tabGroupPickerButton.widthAnchor constraintLessThanOrEqualToConstant:200],
        [tabGroupPickerButton.widthAnchor constraintGreaterThanOrEqualToConstant:17.5],
    ]];
    [self setConstraintWhenNoTitle:[tabGroupPickerButton.widthAnchor constraintEqualToConstant:15]];
    [NSLayoutConstraint activateConstraints:self.constraintsWhenHasTitle];
    return self;
}

- (void)setLocatedInSidebar:(BOOL)inSidebar {
    _orig(void, YES);
}

- (void)setTabGroupPickerButtonTitle:(NSString *)title withIcon:(id)icon {
    if (title.length) {
        title = [NSString stringWithFormat:@"  %@", title];
        [NSLayoutConstraint deactivateConstraints:@[self.constraintWhenNoTitle]];
        [NSLayoutConstraint activateConstraints:self.constraintsWhenHasTitle];
    } else {
        [NSLayoutConstraint deactivateConstraints:self.constraintsWhenHasTitle];
        [NSLayoutConstraint activateConstraints:@[self.constraintWhenNoTitle]];
    }
    _orig(void, title, icon);
}
endhook


static NSImage *_backgroundPrivateWindowCapLeft(void)
{
    if (carBundle) return [carBundle imageForResource:@"com.apple.Safari.PrivateWindowUnifiedFieldCapLeft"];
    
    return [NSBundle.mainBundle imageForResource:@"com.apple.Safari.PrivateWindowUnifiedFieldCapLeft"];
}

static NSImage *_backgroundPrivateWindowCapRight(void)
{
    if (carBundle) return [carBundle imageForResource:@"com.apple.Safari.PrivateWindowUnifiedFieldCapRight"];
    
    return [NSBundle.mainBundle imageForResource:@"com.apple.Safari.PrivateWindowUnifiedFieldCapRight"];
}

static NSImage *_backgroundPrivateWindowFill(void)
{
    if (carBundle) return [carBundle imageForResource:@"com.apple.Safari.PrivateWindowUnifiedFieldStretch"];
    
    return [NSBundle.mainBundle imageForResource:@"com.apple.Safari.PrivateWindowUnifiedFieldStretch"];
}

hook(UnifiedFieldBezelView)
- (void)_updateBackingMaterial {
}

- (void)_updateAppearance {
}

- (void)_setLayerBorderWidthIfNeeded:(id)arg {
}

- (void)_finishInitialization {
    UnifiedFieldBezelView *view = (UnifiedFieldBezelView *)self;
    view.editable = NO;
    view.drawsBackground = NO;
}

- (void)_drawDarkPrivateBrowsingBezel
{
    NSRect strokeRect = NSInsetRect(((UnifiedFieldBezelView *)self).bounds, 1, 1);
    strokeRect.size.height = 22;
    NSRect fillRect = NSInsetRect(strokeRect, 1, 1);
    NSBezierPath *fillPath = [NSBezierPath bezierPathWithRoundedRect:fillRect xRadius:3.75 yRadius:3.75];
    [[NSColor colorNamed:@"UnifiedFieldPrivateBrowsingBezelFillColor"] set];
    [fillPath fill];
    NSBezierPath *strokePath = [NSBezierPath bezierPathWithRoundedRect:strokeRect xRadius:3.75 yRadius:3.75];
    [strokePath setClip];
    strokePath.lineWidth = 2;
    [[NSColor colorNamed:@"UnifiedFieldPrivateBrowsingBezelStrokeColor"] set];
    [strokePath stroke];
}

- (void)drawRect:(NSRect)rect {
    UnifiedFieldBezelView *view = (UnifiedFieldBezelView *)self;
    NSRect bounds = view.bounds;
    NSUInteger browsingMode = ZKHookIvar(self, NSUInteger, "_browsingMode");
    if (browsingMode == 1) {
        if ([[view.effectiveAppearance bestMatchFromAppearancesWithNames:@[ NSAppearanceNameAqua, NSAppearanceNameDarkAqua ]] isEqualToString:NSAppearanceNameDarkAqua]) {
            [self _drawDarkPrivateBrowsingBezel];
        } else {
            NSDrawThreePartImage(bounds, _backgroundPrivateWindowCapLeft(), _backgroundPrivateWindowFill(), _backgroundPrivateWindowCapRight(), NO, NSCompositingOperationSourceOver, 1.0, view.isFlipped);
        }
    } else {
        [view.cell drawWithFrame:bounds inView:view];
    }
}
endhook

hook(UnifiedFieldButtonMetrics)
- (instancetype)initForBrowsingMode:(NSUInteger)mode {
    UnifiedFieldButtonMetrics *metrics = _orig(UnifiedFieldButtonMetrics *, mode);
    CGFloat *yOffset = &ZKHookIvar(metrics, CGFloat, "_yOffset");
    *yOffset = 0;
    return self;
}
endhook

hook(ToolbarDownloadsButton)
- (void)layout {
    _orig(void);
    NSView *progressBar = ZKHookIvar(self, NSView *, "_progressBar");
    NSRect frame = progressBar.frame;
    frame.origin.y = frame.origin.y - (isTahoeOrLater ? 0 : 5);
    progressBar.frame = frame;

}
endhook

// For some reason, Safari uses a lot of duplicated classes that eschew the NeXTSTEP prefix
// The procedure matches the one applied elsewhere for NSTabBarViewButton
hook(TabBarViewButton)

- (BOOL)isOpaque {
    // Unhide the top border view
    NSView* topBorderView = ZKHookIvar(self, NSView*, "_topBorderView");
    topBorderView.hidden = NO;
    
    // Return our original value since, well, we don't actually need to change the function output :P
    return ZKOrig(BOOL);
}

endhook

// The same type of thing we have for NSTabBar but, obviously, for Safari's custom weird implementation
hook(TabBarView)

- (CGRect)frame {
    // The original value to modify...
    CGRect tabFrame = ZKOrig(CGRect);
    
    // The view in Safari is merged and doesn't require the superview override
    // Why this isn't standardised with the wider OS impl is beyond me and I'm surprised Apple have never taken the time to eliminate this oddity; does Safari really need these custom controls that look exactly the same as the standard ones?
    // Anyway...
    
    // Set intended height (26pt for Catalina, 28pt for Big Sur)
    tabFrame.size.height = 26;
    
    // Return the modified tab frame itself
    return tabFrame;
}

endhook

hook(WBSFeatureAvailability)
+ (BOOL)isSolariumEnabled {
    return NO;
}
endhook

hook(FeatureAvailability)
+ (BOOL)usesUnifiedTabBarInSeparateLayout {
    return NO;
}
endhook
