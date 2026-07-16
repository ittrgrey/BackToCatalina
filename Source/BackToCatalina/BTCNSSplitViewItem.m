//
//  BTCNSSplitViewItem.m
//  BackToCatalina
//
//  Created by ittrgrey on 08/07/2026.
//
#import <Cocoa/Cocoa.h>
#import "ZKSwizzle.h"

hook(NSSplitViewItem)

- (BOOL)allowsFullHeightLayout {
    NSSplitViewItem *item = (NSSplitViewItem *)self;
    item.allowsFullHeightLayout = NO;
    return _orig(BOOL);
}

- (void)setAllowsFullHeightLayout:(BOOL)allows {
    _orig(void, NO);
}

endhook

