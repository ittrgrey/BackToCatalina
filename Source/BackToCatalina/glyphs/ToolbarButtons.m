//
//  ToolbarButtons.m
//  BackToCatalina
//
//  Created by ittrgrey on 29/08/2026.
//

#include "shared.h"
#include "../ZKSwizzle.h"

hook(NSSegmentItemImageView)

- (NSImage*)image {
    return GetToolbarButtonImage((NSView*)self, ZKOrig(NSImage*));
}

- (void)setFrame:(CGRect)frame {
    frame = CalculateImageFrame((NSView*)self, [self image], frame);
    return ZKOrig(void, frame);
}

endhook

hook(NSButtonImageView)

- (NSImage*)image {
    return GetToolbarButtonImage((NSView*)self, ZKOrig(NSImage*));
}

- (void)setFrame:(CGRect)frame {
    frame = CalculateImageFrame((NSView*)self, [self image], frame);
    return ZKOrig(void, frame);
}

endhook
