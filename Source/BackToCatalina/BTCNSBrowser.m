//
//  BTCNSBrowser.m
//  BackToCatalina
//
//  Created by ittrgrey on 29/07/2026.
//

#include <AppKit/AppKit.h>
#include "BackToCatalina.h"
#include "ZKSwizzle.h"

hook(NSBrowser)

- (void)setControlSize:(NSControlSize)controlSize {
   // NSControlSizeLarge did not exist prior to macOS 11
   if (controlSize == NSControlSizeLarge) controlSize = NSControlSizeRegular;
   
   return ZKOrig(void, controlSize);
}

endhook

@interface _NSBrowserColumnView : NSScrollView @end
hook(_NSBrowserColumnView)

- (void)tile {
    ZKOrig(void);

    if (!isTahoeOrLater) return;

    NSWindow *window = [(NSView *)self window];
    NSView *contentView = window.contentView;
    if (!window || !contentView) return;

    CGFloat expectedTop = NSHeight(contentView.bounds) - NSMaxY(window.contentLayoutRect);
    if (expectedTop < 0) expectedTop = 0;

    NSEdgeInsets insets = [(NSScrollView *)self contentInsets];
    if (fabs(insets.top - expectedTop) > 0.5) {
        insets.top = expectedTop;
        [(NSScrollView *)self setContentInsets:insets];
    }
}

endhook
