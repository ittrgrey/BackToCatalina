#import "BackToCatalina.h"

#import "dobby.h"
#import "ZKSwizzle.h"

NSBundle* carBundle;
BOOL isTahoeOrLater;

Boolean (*CompatWidgetOld)(void);
Boolean CompatWidgetNew(void) {
    return true;
}

Boolean (*SelectionRolloverOld)(void);
Boolean SelectionRolloverNew(void) {
    return false;
}

NSOperatingSystemVersion tahoeVersion = {
    .majorVersion = 26,
    .minorVersion = 0,
    .patchVersion = 0
};

WEAK_IMPORT_ATTRIBUTE
@interface load : NSObject @end

@implementation load

+(void)load {
    // This loads from a bundle that contains the asset files, but otherwise has been renamed etc so that it isn't wiped during system updates
    carBundle = [NSBundle bundleWithPath:@"/private/var/ammonia/core/tweaks/libBackToCatalina/BTC_VisualStyle.bundle"];
    
    isTahoeOrLater = [NSProcessInfo.processInfo isOperatingSystemAtLeastVersion:tahoeVersion];

    DobbyHook(DobbySymbolResolver("AppKit", "_NSToolbarItemViewerCompatabilitySelectionWidgetDefaultValueFunction"),
              CompatWidgetNew,
              &CompatWidgetOld);
    
    DobbyHook(DobbySymbolResolver("AppKit", "_NSToolbarItemViewerSupportsSelectionRolloverDefaultValueFunction"),
              SelectionRolloverNew,
              &SelectionRolloverOld);
}

@end

