#include <AppKit/AppKit.h>
#include "BackToCatalina.h"
#include "ZKSwizzle.h"

static NSMutableDictionary<NSFont*, NSFont*> *btcNonBoldCache;

static NSFont* BTCNonBoldVariant(NSFont *font) {
    if (!font) {
        return nil;
    }
    if (!btcNonBoldCache) {
        btcNonBoldCache = [NSMutableDictionary dictionary];
    }
    NSFont *cached = btcNonBoldCache[font];
    if (cached) {
        return cached == (id)[NSNull null] ? nil : cached;
    }

    NSFontManager *fm = [NSFontManager sharedFontManager];
    if (!([fm traitsOfFont:font] & NSBoldFontMask)) {
        btcNonBoldCache[font] = (NSFont *)[NSNull null];
        return nil;
    }
    NSFont *regular = [fm convertFont:font toNotHaveTrait:NSBoldFontMask];
    btcNonBoldCache[font] = regular ?: (NSFont *)[NSNull null];
    return regular;
}

static void BTCDeboldCell(NSCell *cell) {
    NSAttributedString *attrValue = [cell attributedStringValue];
    if (attrValue.length > 0) {
        NSFont *font = [attrValue attribute:NSFontAttributeName atIndex:0 effectiveRange:NULL];
        NSFont *regular = BTCNonBoldVariant(font);
        if (regular) {
            NSMutableAttributedString *mutableCopy = [attrValue mutableCopy];
            [mutableCopy addAttribute:NSFontAttributeName value:regular range:NSMakeRange(0, mutableCopy.length)];
            [cell setAttributedStringValue:mutableCopy];
        }
    }

    NSFont *regularCellFont = BTCNonBoldVariant(cell.font);
    if (regularCellFont) {
        cell.font = regularCellFont;
    }
}

hook(NSTableView)

- (NSInteger)_resolvedSidebarType {
    return 2;
}

- (BOOL)_addSourceListCellAttributesToCell:(NSCell *)cell withData:(id)data selected:(BOOL)selected emphasized:(BOOL)emphasized {
    BOOL result = ZKOrig(BOOL, cell, data, selected, emphasized);
    if (isGoldenGateOrLater && selected) {
        BTCDeboldCell(cell);
    }
    return result;
}

- (CGSize)intercellSpacing {
    CGSize orig = ZKOrig(CGSize);
    
    if (orig.width == 17 && orig.height == 0) {
        return CGSizeMake(3, 2);
    }
    
    return orig;
}

- (CGFloat)rowHeight {
    CGFloat orig = ZKOrig(CGFloat);
    
    if (orig == 24.0 && [(NSTableView*)self rowSizeStyle] == NSTableViewRowSizeStyleCustom) {
        return 17.0;
    }
    
    return orig;
}

endhook

hook(NSTableViewStyleData)

// If NSSidebarUsesGoldenMetrics are on, it results in stuff being rounded and looking strange
// This addresses that - other differentials do however remain at the moment.

- (double)rowBackgroundInset {
    return 0;
}

- (double)cornerRadius {
    return 0;
}

endhook
