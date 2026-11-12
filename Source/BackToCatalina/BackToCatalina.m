#include "BackToCatalina.h"

#include "dobby.h"
#include "ZKSwizzle.h"

NSBundle* carBundle;
BOOL isTahoeOrLater;
BOOL isGoldenGateOrLater;
BOOL isSafari27OrLater;
BOOL isPhotos;
BOOL isMessages;
BOOL isReminders;
BOOL isWeather;
BOOL isFinder;
BOOL isShortcuts;

Boolean (*CommonOld)(void);

void BTCInstallToolbarAnimationHooks(void);
void BTCInstallSidebarFontHook(void);

__attribute__((constructor)) static void BTCInstallAppHooks(void) {
    ZKSwizzleGroup(BTCSwiftUIToolbarButtons);
    ZKSwizzleGroup(BTCWindowSidebarActions);

    if (isShortcuts) ZKSwizzleGroup(BTCShortcuts);
    if (isTahoeOrLater) ZKSwizzleGroup(BTCWindowAnimation);
    if (isTahoeOrLater) BTCInstallToolbarAnimationHooks();
    if (isTahoeOrLater && isReminders) ZKSwizzleGroup(BTCReminders);
    if (isTahoeOrLater && isPhotos) {
        ZKSwizzleGroup(BTCPhotos);
    } else {
        ZKSwizzleGroup(BTCDefaultWindowToolbarStyle);
    }
    if (isTahoeOrLater && isMessages) {
        ZKSwizzleGroup(BTCMessages);
    } else {
        ZKSwizzleGroup(BTCDisableSectionTracking);
    }

    if (isGoldenGateOrLater && isFinder) ZKSwizzleGroup(BTCFinderTableSpacing);
    if (isGoldenGateOrLater) ZKSwizzleGroup(BTCGoldenGateToolbarContextMenu);
    if (isGoldenGateOrLater) {
        BTCInstallSidebarFontHook();
        ZKSwizzleGroup(BTCGoldenGateSidebarFont);
    }
    if (isWeather && isGoldenGateOrLater) ZKSwizzleGroup(BTCWeather);
}

CTFontRef (*_FontCreateWithFontDescriptorOld)(CTFontDescriptorRef _Nonnull descriptor, CGFloat size, const CGAffineTransform * _Nullable matrix);
CTFontRef FontCreateWithFontDescriptorNew(CTFontDescriptorRef _Nonnull descriptor, CGFloat size, const CGAffineTransform * _Nullable matrix) {
    // Read descriptor
    CFDictionaryRef dictionary = CTFontDescriptorCopyAttributes(descriptor);
    NSString *fontName = CFDictionaryGetValue(dictionary, (__bridge CFStringRef)NSFontNameAttribute);
    NSString *uiAttr = CFDictionaryGetValue(dictionary, @"NSCTFontUIUsageAttribute");
    if (uiAttr || (!fontName && !([[[NSBundle mainBundle] bundleIdentifier] containsString:@"Pages"] || [[[NSBundle mainBundle] bundleIdentifier] containsString:@"Keynote"] || [[[NSBundle mainBundle] bundleIdentifier] containsString:@"Numbers"])) || ([fontName containsString:@"AppleSystemUIFont"] &&
         !([[[NSBundle mainBundle] bundleIdentifier] containsString:@"Passwords"]
            || [[[NSBundle mainBundle] bundleIdentifier] containsString:@"Safari"] ))) {
            // Update descriptor
            NSMutableDictionary *mutableDictionary = [(__bridge NSDictionary *)dictionary mutableCopy];
            [mutableDictionary removeObjectForKey:@"NSCTFontTraitsAttribute"];
            [mutableDictionary removeObjectForKey:@"NSCTFontUIUsageAttribute"];
        
            // Unlike with Lucida, it's a font collection so we don't need to specify variants
            // Setting this value reverts SF Pro usage to Helvetica Neue
            [mutableDictionary setValue:(@"AppleSystemUIFont") forKey:NSFontNameAttribute];
            descriptor = CTFontDescriptorCreateWithAttributes((__bridge CFDictionaryRef)mutableDictionary);
    }
    
    return _FontCreateWithFontDescriptorOld(descriptor, size, matrix);
}

Boolean CommonAppKitTrue(void) {
    return YES;
}

Boolean CommonAppKitFalse(void) {
    return NO;
}

NSOperatingSystemVersion tahoeVersion = {
    .majorVersion = 26,
    .minorVersion = 0,
    .patchVersion = 0
};

NSOperatingSystemVersion goldenGateVersion = {
    .majorVersion = 27,
    .minorVersion = 0,
    .patchVersion = 0
};

WEAK_IMPORT_ATTRIBUTE
@interface load : NSObject @end

@implementation load

+(void)load {
    // This loads from a bundle that contains the asset files, but otherwise has been renamed etc so that it isn't wiped during system updates
    NSString* carPath = @"/private/var/ammonia/core/tweaks/libBackToCatalina/BTC_VisualStyle.bundle";
    carBundle = [NSBundle bundleWithPath:carPath];
    
    // Check if we are on Tahoe or later
    isTahoeOrLater = [NSProcessInfo.processInfo isOperatingSystemAtLeastVersion:tahoeVersion];
    isGoldenGateOrLater = [NSProcessInfo.processInfo isOperatingSystemAtLeastVersion:goldenGateVersion];
    isPhotos = [NSBundle.mainBundle.bundleIdentifier isEqualToString:@"com.apple.Photos"];
    isFinder = [NSBundle.mainBundle.bundleIdentifier isEqualToString:@"com.apple.finder"];
    isShortcuts = [NSBundle.mainBundle.bundleIdentifier isEqualToString:@"com.apple.shortcuts"];
    isMessages = [NSBundle.mainBundle.bundleIdentifier isEqualToString:@"com.apple.MobileSMS"];
    isReminders = [NSBundle.mainBundle.bundleIdentifier isEqualToString:@"com.apple.reminders"];
    isWeather = [NSBundle.mainBundle.bundleIdentifier isEqualToString:@"com.apple.weather"];
    
    NSString *versionString = [[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleShortVersionString"];
    if (versionString) {
        NSComparisonResult result = [versionString compare:@"27.0" options:NSNumericSearch];
        if (result != NSOrderedAscending) {
            isSafari27OrLater = YES;
        }
    }
#ifdef APPLY_SYRAH
    
    DobbyHook(DobbySymbolResolver(NULL, "CTFontCreateWithFontDescriptor"), FontCreateWithFontDescriptorNew, (void**)&_FontCreateWithFontDescriptorOld);
    
    
#endif
    DobbyHook(DobbySymbolResolver("AppKit", "_NSToolbarItemViewerCompatabilitySelectionWidgetDefaultValueFunction"),
              CommonAppKitTrue,
              &CommonOld);
    
    DobbyHook(DobbySymbolResolver("AppKit", "_NSToolbarItemViewerSupportsSelectionRolloverDefaultValueFunction"),
              CommonAppKitFalse,
              &CommonOld);
    
}

@end

