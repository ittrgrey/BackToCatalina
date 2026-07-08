//
//  BTCNSSplitViewItem.m
//  BackToCatalina
//
//  Created by ittrgrey on 08/07/2026.
//
#import <Cocoa/Cocoa.h>
#import "ZKSwizzle.h"

hook(NSSplitViewItem)

-(BOOL)allowsFullHeightLayout {
    return false;
}

endhook

