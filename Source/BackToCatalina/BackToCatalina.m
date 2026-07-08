#import "BackToCatalina.h"

#import "dobby.h"
#import "ZKSwizzle.h"
#import <UserNotifications/UserNotifications.h>

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
@interface notificationHook : NSUserNotification @end
@interface notificationHook2 : UNNotificationSound @end

@implementation load

+(void)load {
    carBundle = [NSBundle bundleWithPath:@"/private/var/ammonia/core/tweaks/libBackToCatalina/SystemAppearance.bundle"];
    isTahoeOrLater = [NSProcessInfo.processInfo isOperatingSystemAtLeastVersion:tahoeVersion];

    DobbyHook(DobbySymbolResolver("AppKit", "_NSToolbarItemViewerCompatabilitySelectionWidgetDefaultValueFunction"),
              CompatWidgetNew,
              &CompatWidgetOld);
    
    DobbyHook(DobbySymbolResolver("AppKit", "_NSToolbarItemViewerSupportsSelectionRolloverDefaultValueFunction"),
              SelectionRolloverNew,
              &SelectionRolloverOld);
    
    ZKSwizzle(notificationHook, _NSConcreteUserNotification);
    ZKSwizzle(notificationHook2, UNNotificationSound);
}

@end

@implementation notificationHook
- (void)setSoundName:(NSString *)soundName {
    if ([soundName isEqual:NSUserNotificationDefaultSoundName])
        return ZKOrig(void, @"Tri-tone");
    return ZKOrig(void, soundName);
}

@end

@implementation notificationHook2
+ (id)_soundWithAlertType:(long long)a0 audioVolume:(id)a1 critical:(BOOL)a2 toneFileName:(id)a3 {
    if(a3 == nil)
        return ZKOrig(id, a0, a1, a2, @"Tri-Tone");
    return ZKOrig(id, a0, a1, a2, a3);
}

@end
