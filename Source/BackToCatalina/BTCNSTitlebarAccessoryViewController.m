//
//  BTCNSTitlebarAccessoryViewController.m
//  BackToCatalina
//
//  Created by ittrgrey on 22/07/2026.
//

#include <Cocoa/Cocoa.h>
#include "ZKSwizzle.h"

hook(NSTitlebarAccessoryViewController)

// Reverts to pre-BigSur behaviour
- (BOOL)allowsAutomaticSeparator {
    return true;
}

endhook

