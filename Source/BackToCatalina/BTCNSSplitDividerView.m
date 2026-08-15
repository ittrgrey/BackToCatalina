//
//  BTCNSSplitDividerView.m
//  BackToCatalina
//
//  Created by ittrgrey on 15/08/2026.
//

#include <AppKit/AppKit.h>
#include "ZKSwizzle.h"

hook(NSSplitDividerView)

// Setting this to 4 brings back the old divider line for Finder on launch - otherwise, only applies after resizing the window
// Likely some custom behaviour going on via subclass that should be properly investigated in future
- (long long)style {
    // If not applied, Finder doesn't apply it on launch
    // Only applied to Finder however, because setting the value this early can cause crashing issues on some applications, like UTM
    return [[[NSBundle mainBundle] bundleIdentifier] isEqualToString:@"com.apple.finder"] ? 4 : ZKOrig(long long);
}

// Safer way of applying our changes for most other applications at least as far as restoring the divider line goes
- (void)setStyle:(long long)style {
    return ZKOrig(void, 4);
}

// We also do it like this which catches the divider view early on during application init and eliminates the extra "bar", except for Finder for some reason
- (void)layout {
    [self setValue:([NSNumber numberWithLongLong:4]) forKey:@"style"];
    return ZKOrig(void);
}

endhook
