//
//  ToolbarButtons.m
//  BackToCatalina
//
//  Created by ittrgrey on 29/08/2026.
//

#include "shared.h"
#include "../ZKSwizzle.h"

NSImage* FindLegacyToolbarGlyph(NSString* symbolName, BOOL isPrefsWnd) {
    if (carBundle) {
        // We can humbly assume that if our appearance bundle exists, its contents also do
        NSString* legacyGlyphName = nil;
        
        if (isPrefsWnd) {
            // Per-application override to fix any conflicting glyphs
            NSDictionary* glyphMap = applicationPrefsGlyphMap[NSBundle.mainBundle.bundleIdentifier];
            legacyGlyphName = glyphMap[symbolName];
            
            // Use miscellaneous glyph map
            if (!legacyGlyphName) legacyGlyphName = prefsGlyphMap[symbolName];
        } else {
            // Standard toolbar items
            legacyGlyphName = toolbarGlyphMap[symbolName];
        }
        
        // Only proceed if we actually have a resource that we can load
        if (legacyGlyphName) {
            NSString* directory = @"/private/var/ammonia/core/tweaks/libBackToCatalina/BTC_VisualStyle.bundle/Contents/Resources/Glyphs/";
            NSString* path = [directory stringByAppendingFormat:@"%@", legacyGlyphName];
            
            NSImage* image = [[NSImage alloc] initWithContentsOfFile:path]; // first try
            if (!image) image = [[NSImage alloc] initWithContentsOfFile:legacyGlyphName]; // second try
            [image setTemplate:(!isPrefsWnd ? YES : NO)];
            
            // third and final attempt -- are we using a PNG resource from our bundle?
            if (!image) {
                image = [carBundle imageForResource:legacyGlyphName];
                [image setTemplate:NO]; // Likely NOT a template image...
            }
            
            return image;
        }
    }
    
    return NULL;
}

NSImage* GetToolbarButtonImage(NSView* view, NSImage* symbol) {
    // We check that we're inside a toolbar view before calculating and applying our override - we don't want to replace stuff unintentionally, or do unnecessary calculations here
    BOOL isToolbar = ([[[view window] className] isEqualToString:@"NSToolbarFullScreenWindow"] || [view isDescendantOf:[[view window] _toolbarView]]);
    
    if (!isToolbar) {
        return symbol;
    }
    
    BOOL isPrefsWnd = NO;
    for (NSView* potentialWidget in view.superview.superview.subviews) {
        if ([[potentialWidget className] isEqualToString:@"NSWidgetView"]) {
            isPrefsWnd = YES;
        }
    }
    
    NSString* identifier = [symbol valueForKey:@"_symbolName"];
    NSImage* glyph = FindLegacyToolbarGlyph(identifier, isPrefsWnd);
    
    // Depending on whether it exists, return either our glyph, or the SF Symbol
    return glyph ? glyph : symbol;
}

CGRect CalculateToolbarImageFrame(NSView* view, NSImage* image, CGRect frame) {
    BOOL isSymbolImage = [image _isSymbolImage];
    BOOL isToolbar = ([[[view window] className] isEqualToString:@"NSToolbarFullScreenWindow"] || [view isDescendantOf:[[view window] _toolbarView]]);
    
    if (isSymbolImage || !isToolbar) {
        // Return unmodified frame if we are still using SF Symbols, or are not inside a toolbar
        return frame;
    }
    
    NSView* superview = view.superview;
    CGRect buttonBox = superview.bounds;
    
    BOOL isPrefsWnd = NO;
    for (NSView* potentialWidget in superview.superview.subviews) {
        if ([[potentialWidget className] isEqualToString:@"NSWidgetView"]) {
            isPrefsWnd = YES;
        }
    }
    
    double widthForCalc = isPrefsWnd ? 32 : image.size.width;
    double heightForCalc = isPrefsWnd ? widthForCalc : image.size.height;
    
    CGPoint center = CGPointMake((buttonBox.size.width / 2) - (widthForCalc / 2), floor((buttonBox.size.height / 2) - (heightForCalc / 2)));
    
    if ([superview.className containsString:@"PopUp"] || [superview.className containsString:@"PullDown"]) {
        // calling valueForKey does not work here so we have to cast to the relevant class to check arrowPosition attribute
        NSPopUpButtonCell* button = (NSPopUpButtonCell*)superview;
        
        if (button.arrowPosition != NSPopUpNoArrow) {
            center.x = 9;
        }
    }
    
    return CGRectMake(center.x, center.y, widthForCalc, heightForCalc);
}

hook(NSSegmentItemImageView)

- (NSImage*)image {
    return GetToolbarButtonImage((NSView*)self, ZKOrig(NSImage*));
}

- (void)setFrame:(CGRect)frame {
    frame = CalculateToolbarImageFrame((NSView*)self, [self image], frame);
    return ZKOrig(void, frame);
}

- (int)_vibrancyBlendMode {
    // Fix prefs window tab icon colorization
    return 0;
}

endhook

hook(NSButtonImageView)

- (NSImage*)image {
    return GetToolbarButtonImage((NSView*)self, ZKOrig(NSImage*));
}

- (void)setFrame:(CGRect)frame {
    return ZKOrig(void, CalculateToolbarImageFrame((NSView*)self, [self image], frame));
}

- (int)_vibrancyBlendMode {
    // Fix prefs window tab icon colorization
    return 0;
}

- (void)_configureSymbolLayer {
    
}

endhook
