//
//  ItemView.m
//  BackToCatalina
//
//  Created by ittrgrey on 15/10/2026.
//

#include "../BackToCatalina.h"
#include "../ZKSwizzle.h"

@interface NSMenuBarItemView : NSView
- (BOOL)_isAppleMenu;
@end

#ifdef APPLY_SYRAH
hook(NSMenuBarItemView)

- (id)_applicableTitle {
    if ([(NSMenuBarItemView*)self _isAppleMenu]) {
        return nil;
    }
    
    return ZKOrig(id);
}

endhook
#endif

