//
//  BTCNSTextField.m
//  BackToCatalina
//
//  Created by ittrgrey on 10/07/2026.
//

#import <Cocoa/Cocoa.h>
#import "ZKSwizzle.h"

hook(NSTextField)

// No slop 4 u
+ (BOOL)allowsWritingTools {
    return NO;
}

- (void)setAllowsWritingTools:(BOOL)allowsWritingTools {
    return ZKOrig(void, NO);
}

- (BOOL)isBezeled {
    return ZKOrig(BOOL);
}

- (BOOL)_wantsSeparatedSubviews {
    return ZKOrig(BOOL);
}

// Fix searchbox height in System Settings
- (void)setFrameSize:(CGSize)frameSize {
    // HACKY!!
    // Actual core of the problem relates to the way the image is incompatible with the 9-silce format that newer SystemAppearance *is* compatible with. Pre-BigSur, all input fields therefore had to be the same height. Catalina and earlier therefore need this issue mitigated.
    frameSize.height = ([self isBezeled] && [self _wantsSeparatedSubviews]) ? MIN(frameSize.height, 22.0) : frameSize.height;
    
    return ZKOrig(void, frameSize);
}

// Fix overall textbox height so that it cannot be absurdly large
- (void)setControlSize:(NSControlSize)controlSize {
    // NSControlSizeLarge did not exist prior to macOS 11
    if (controlSize == NSControlSizeLarge) controlSize = NSControlSizeRegular;
    
    return ZKOrig(void, controlSize);
}

endhook
