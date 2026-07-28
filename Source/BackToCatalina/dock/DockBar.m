//
//  DockBar.m
//  BackToCatalina
//
//  Created by ittrgrey on 27/07/2026.
//

#include <Cocoa/Cocoa.h>
#include "../ZKSwizzle.h"
#include "shared.h"

hook(DockBar)

- (float)distanceBottom {
    return ZKOrig(float) - 5.0;
}

- (void)setFloorFrame:(CGRect)frame {
    NSString* orientation = GetDockOrientation();
    
    if ([orientation isEqualToString:@"bottom"]) {
        frame.size.height += 6.0;
    } else if ([orientation isEqualToString:@"left"]) {
        frame.size.width += 6.0;
    } else if ([orientation isEqualToString:@"right"]) {
        frame.size.width += 7.0;
    }
    
    return ZKOrig(void, frame);
}

endhook
