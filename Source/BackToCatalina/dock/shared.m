//
//  shared.m
//  BackToCatalina
//
//  Created by ittrgrey on 28/07/2026.
//

#include "shared.h"
#include "../ZKSwizzle.h"

NSString* GetDockOrientation(void) {
    return [[[NSUserDefaults standardUserDefaults] persistentDomainForName:@"com.apple.dock"] valueForKey:@"orientation"];
}

static BOOL DockInjectionShouldBeDisabled(void) {
    NSOperatingSystemVersion tahoeOrLater = { .majorVersion = 26, .minorVersion = 0, .patchVersion = 0 };
    NSString* systemDockPath = @"/System/Library/CoreServices/Dock.app/Contents/MacOS/Dock";
    return [NSProcessInfo.processInfo isOperatingSystemAtLeastVersion:tahoeOrLater] && [NSBundle.mainBundle.executablePath isEqualToString:systemDockPath];
}

__attribute__((constructor))
static void DockHooksInit(void) {
    if (!DockInjectionShouldBeDisabled()) {
        ZKSwizzleGroup(BTCDock);
    }
}
