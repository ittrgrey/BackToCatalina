#include <AppKit/AppKit.h>
#include "ZKSwizzle.h"

@interface NSContextMenuImpl : NSResponder
- (NSMenu*)menu;
@end

hook(NSContextMenuImpl)

- (int)_backgroundStyle {
    return 0;
}

- (double)markWidthsForItem:(id)item {
    return 4.0;
}

- (NSObject*)selectionMaterialView {
    return ZKOrig(NSObject*);
}

- (CGRect)_selectionLayerFrameForView:(id)view {
    CGRect orig = ZKOrig(CGRect, view);
    orig.size = [view bounds].size;
    orig.origin.x = 0;
    NSVisualEffectView* backing = [[self selectionMaterialView] valueForKey:@"_backingView"];
    [backing setValue:@(0) forKey:@"_materialCornerRadius"];
    return orig;
}

- (double)_targetWidth {
    return ZKOrig(double) - ([[self valueForKey:@"_maxModifiersWidth"] doubleValue] > 0 ? 26 : 0);
}

- (double)preferredViewHeightForMenuItemAtIndex:(unsigned long long)index {
    double orig = ZKOrig(double, index);
    
    return (orig > 19) && (orig < 27) ? 19 + (orig - 19) / 1000 : orig;
}

- (double)_targetHeight:(bool)unk {
    double orig = ZKOrig(double, unk);
    
    NSInteger itemTotal = [[(NSContextMenuImpl*)self menu] numberOfItems];
    
    for (NSInteger x = 0; x < itemTotal; x++) {
        double prefHeight = [self preferredViewHeightForMenuItemAtIndex:x];
        
        if ((prefHeight > 19) && (prefHeight < 20)) {
            orig -= 1000 * (prefHeight - 19);
        }
    }
    
    return orig;
}

endhook
