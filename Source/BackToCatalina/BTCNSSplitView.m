//
//  BTCNSSplitView.m
//  BackToCatalina
//
//  Created by ittrgrey on 15/08/2026.
//

#include <AppKit/AppKit.h>
#include "ZKSwizzle.h"

hook(NSSplitView)

// Revert all sidebar dividers by returning this undocumented value
- (long long)_dividerStyleForDividerAtIndex:(unsigned long long)arg1 {
    return 4;
}

endhook

hook(NSSplitDividerView)

// Pre-Tahoe, the other function wasn't present. This is supplementary to ensure Sequoia and earlier behave ordinarily.
- (void)setStyle:(long long)style {
    return ZKOrig(void, 4);
}

endhook
