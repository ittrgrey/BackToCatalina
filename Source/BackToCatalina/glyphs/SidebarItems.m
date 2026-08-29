//
//  SidebarItems.m
//  BackToCatalina
//
//  Created by ittrgrey on 29/08/2026.
//

#include "shared.h"
#include "../ZKSwizzle.h"

NSImage* FindLegacySidebarGlyph(NSString* symbolName) {
    if (carBundle) {
        // We can humbly assume that if our appearance bundle exists, its contents also do
        NSString* legacyGlyphName = sidebarGlyphMap[symbolName];
        if (legacyGlyphName) {
            if ([legacyGlyphName containsString:@"/"]) {
                // path likely already included
                NSImage* image = [[NSImage alloc] initWithContentsOfFile:legacyGlyphName];
                [image setTemplate:YES];
                [image setAccessibilityDescription:legacyGlyphName];
                
                return image;
            } else if (legacyGlyphName) {
                // Do the same as we do for toolbar glyphs
                NSString* directory = @"/private/var/ammonia/core/tweaks/libBackToCatalina/BTC_VisualStyle.bundle/Contents/Resources/Glyphs/";
                NSString* path = [directory stringByAppendingFormat:@"%@", legacyGlyphName];
            
                NSImage* image = [[NSImage alloc] initWithContentsOfFile:path];
                [image setTemplate:YES];
                [image setAccessibilityDescription:legacyGlyphName];
                
                return image;
                
            }
        }
    }
    
    return NULL;
}

NSImage* GetSidebarButtonImage(NSView* view, NSImage* symbol) {
    NSString* identifier = [symbol valueForKey:@"_symbolName"];
    NSImage* glyph = FindLegacySidebarGlyph(identifier);
    
    // Depending on whether it exists, return either our glyph, or the SF Symbol
    return glyph ? glyph : symbol;
}

CGRect CalculateSidebarImageFrame(NSView* view, NSImage* image, CGRect frame) {
    if (![[image accessibilityDescription] containsString:@"/"]) {
        // Return unmodified frame if we are still using SF Symbols in this case
        return frame;
    }
    
    NSView* superview = view.superview;
    CGRect buttonBox = superview.bounds;
    
    int desiredSquare = 18;
    
    CGPoint center = CGPointMake((buttonBox.size.width / 2) - (desiredSquare / 2), (buttonBox.size.height / 2) - (desiredSquare / 2));
    
    // Return the new centered square box (well, offset by 1 to account for a single point difference...)
    return CGRectMake(center.x, center.y, desiredSquare, desiredSquare);
}

hook(_NSImageViewSimpleImageView)

- (NSImage*)image {
    return GetSidebarButtonImage((NSView*)self, ZKOrig(NSImage*));
}

- (void)setFrame:(CGRect)frame {
    frame = CalculateSidebarImageFrame((NSView*)self, [self image], frame);
    return ZKOrig(void, frame);
}

endhook
