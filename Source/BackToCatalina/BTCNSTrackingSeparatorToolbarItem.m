//
//  BTCNSTrackingSeparatorToolbarItem.m
//  BackToCatalina
//
//  Created by ittrgrey on 08/07/2026.
//
#import <Cocoa/Cocoa.h>
#import "ZKSwizzle.h"

hook(NSTrackingSeparatorToolbarItem)

+(instancetype)trackingSeparatorToolbarItemWithIdentifier:(NSToolbarItemIdentifier)identifier splitView:(NSSplitView *)splitView dividerIndex:(NSInteger)dividerIndex {
    return ZKOrig(NSTrackingSeparatorToolbarItem*, identifier, nil, dividerIndex);
}

-(BOOL)isHidden {
    return true;
}

endhook
