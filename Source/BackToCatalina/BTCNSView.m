//
//  BTCNSView.m
//  BackToCatalina
//
//  Created by ittrgrey on 26/07/2026.
//

#include <Cocoa/Cocoa.h>
#include "ZKSwizzle.h"

// Class used in Finder is TTextField - not part of standard OS-level headers
hook(NSView)

- (void)setFrameOrigin:(NSPoint)origin {
    NSString* identifier = [self valueForKey:@"identifier"];
    
    // Fix the lack of padding from the left-hand side
    // The header should always have this identifier
    if ([identifier isEqualToString:@"xSidebarHeader"]) {
        // Check that the origin value is already lower than it ought to be to avoid affecting visuals when NSSidebarUsesGoldenStyles is enabled
        if (origin.x <= 6) origin.x += 6.0;
    }
    
    return ZKOrig(void, origin);
}

endhook

