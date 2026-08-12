//
//  BTCNSTitlebarAccessoryViewController.m
//  BackToCatalina
//
//  Created by ittrgrey on 22/07/2026.
//

#include <AppKit/AppKit.h>
#include "ZKSwizzle.h"

hook(NSTitlebarAccessoryViewController)

// Reverts to pre-BigSur behaviour
- (BOOL)allowsAutomaticSeparator {
    return NO;
}

- (double)fullScreenMinHeight {
    return 25; // Reverts height for unified toolbar as used in Safari etc
}

endhook

hook(NSTitlebarSeparatorView)

// NSTitlebarSeparatorStyle was added in Big Sur
// So we eliminate it
- (void)setType:(NSTitlebarSeparatorStyle)type {
    return ZKOrig(void, NSTitlebarSeparatorStyleNone);
}

endhook

hook(_NSTitlebarDecorationView)

// We don't make any changes to the window, we just need it for accessing whether we have a toolbar or not
- (NSWindow*)window {
    return ZKOrig(NSWindow*);
}

// This brings back the old bottom separator - we just have to eliminate the "new" separator style elsewhere, in NSWindow
- (void)_updateBottomSeparatorLayer {
    // Force separator to render for toolbars
    if ([[[self window] toolbar] isVisible] && ![[self window] titlebarAppearsTransparent]) {
        [self setValue:([NSNumber numberWithBool:YES]) forKey:@"drawsBottomSeparator"];
    }
    
    // Just returning here brings it back for most window frame designs...
    return;
}

endhook
