//
//  ToolbarButtons.m
//  BackToCatalina
//
//  Created by ittrgrey on 29/08/2026.
//

#include "shared.h"
#include "../ZKSwizzle.h"

NSImage* FindLegacyToolbarGlyph(NSString* symbolName) {
    if (carBundle) {
        // We can humbly assume that if our appearance bundle exists, its contents also do
        NSString* legacyGlyphName = toolbarGlyphMap[symbolName];
        if (legacyGlyphName) {
            NSString* directory = @"/private/var/ammonia/core/tweaks/libBackToCatalina/BTC_VisualStyle.bundle/Contents/Resources/Glyphs/";
            NSString* path = [directory stringByAppendingFormat:@"%@", legacyGlyphName];
            
            NSImage* image = [[NSImage alloc] initWithContentsOfFile:path];
            [image setTemplate:YES];
            [image setAccessibilityDescription:legacyGlyphName]; // Useful for detecting and modifying the NSImage offsets to match what we're after in NSSegmentItemImageView
            
            return image;
        }
    }
    
    return NULL;
}

NSImage* GetToolbarButtonImage(NSView* view, NSImage* symbol) {
    NSString* identifier = [symbol valueForKey:@"_symbolName"];
    NSImage* glyph = FindLegacyToolbarGlyph(identifier);
    
    // Depending on whether it exists, return either our glyph, or the SF Symbol
    // We also check that we're inside a toolbar view before applying our override - we don't want to replace stuff unintentionally
    return glyph && [view isDescendantOf:[[view window] _toolbarView]] ? glyph : symbol;
}

CGRect CalculateToolbarImageFrame(NSView* view, NSImage* image, CGRect frame) {
    if (![[image accessibilityDescription] containsString:@".pdf"]) {
        // Return unmodified frame if we are still using SF Symbols in this case
        return frame;
    }
    
    NSView* superview = view.superview;
    CGRect buttonBox = superview.bounds;
    
    CGPoint center = CGPointMake((buttonBox.size.width / 2) - (image.size.width / 2), floor((buttonBox.size.height / 2) - (image.size.height / 2)));
    
    if ([superview.className containsString:@"PopUp"] || [superview.className containsString:@"PullDown"]) {
        // calling valueForKey does not work here so we have to cast to the relevant class to check arrowPosition attribute
        NSPopUpButtonCell* button = (NSPopUpButtonCell*)superview;
        
        if (button.arrowPosition != NSPopUpNoArrow) {
            center.x -= buttonBox.size.width / 8;
        }
    }
    
    return CGRectMake(center.x, center.y, image.size.width, image.size.height);
}

hook(NSSegmentItemImageView)

- (NSImage*)image {
    return GetToolbarButtonImage((NSView*)self, ZKOrig(NSImage*));
}

- (void)setFrame:(CGRect)frame {
    frame = CalculateToolbarImageFrame((NSView*)self, [self image], frame);
    return ZKOrig(void, frame);
}

endhook

hook(NSButtonImageView)

- (NSImage*)image {
    return GetToolbarButtonImage((NSView*)self, ZKOrig(NSImage*));
}

- (void)setFrame:(CGRect)frame {
    frame = CalculateToolbarImageFrame((NSView*)self, [self image], frame);
    return ZKOrig(void, frame);
}

endhook
