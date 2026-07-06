#import "BTCNSMutableArray.h"
#import "ZKSwizzle.h"
#import <AppKit/NSAccessibility.h>
#import <AppKit/NSAppearance.h>
#import <os/lock.h>

NS_ASSUME_NONNULL_BEGIN

@class NSCompositeAppearance;

@interface NSAppearance ()
+ (NSCompositeAppearance *)_aquaAppearanceWithAccessibility:(BOOL)accessibility;
+ (NSCompositeAppearance *)_darkAquaAppearanceWithAccessibility:(BOOL)accessibility;
@end

@interface NSCompositeAppearance : NSAppearance
@property (copy) NSArray *appearances;
@property (copy) NSAppearanceName name;
- (id)initWithAppearances:(NSArray *)appearances;
@end

@interface NSBuiltinAppearance : NSAppearance
- (instancetype)initWithBundleResourceName:(NSString *)resourceName publicName:(NSString *)publicName catalystName:(NSString *)catalystName;
@end

@interface NSSystemAppearance : NSBuiltinAppearance
@end

@interface NSAccessibilitySystemAppearance : NSBuiltinAppearance
@end

@interface NSAquaAppearance : NSBuiltinAppearance
@end

@interface NSDarkAquaAppearance : NSBuiltinAppearance
@end

@interface NSVibrantLightAppearance : NSBuiltinAppearance
@end

@interface NSVibrantDarkAppearance : NSBuiltinAppearance
@end

NS_ASSUME_NONNULL_END


extern BOOL NSColorControlAccentIsGraphite(void);

// ---------------------------------------------------------------------------
// Appearance identity caching (recursion-crash fix)
// ---------------------------------------------------------------------------
// Every helper below is named "Cached" but the original code allocated a fresh
// NSAppearance on every call, and the composite builders (_aquaAppearance &c.)
// rebuilt a brand-new NSCompositeAppearance on every call. That breaks pointer
// identity: +[NSAppearance appearanceNamed:] returned a different object each
// time a name was resolved (and rebuilt a CoreUI theme renderer each time).
//
// Apps that observe a view's `appearance` via KVO/Combine and re-apply an
// appearance resolved by name (Apple Notes does exactly this) then never
// converge: -[NSView setAppearance:] always sees a "different" object, fires
// the KVO change, the observer re-applies, and it recurses until the thread
// stack overflows (EXC_BAD_ACCESS / SIGSEGV).
//
// The fix restores the identity invariant the real AppKit singletons have:
// the leaf appearances are memoized once, and each composite is memoized per
// (graphite, accessibility) state, so repeated resolution returns the very
// same object. Rebuilding happens only when that state actually changes.

// Memoize an invariant NSBuiltinAppearance subclass. Each expansion site gets
// its own static slot, so this yields one stable instance per helper function.
#define BTC_CACHED_BUILTIN(CLASSNAME, RESOURCE, PUBLICNAME, CATALYST) \
    ({ \
        static id _btc_cached = nil; \
        static dispatch_once_t _btc_once; \
        dispatch_once(&_btc_once, ^{ \
            _btc_cached = [[NSClassFromString(CLASSNAME) alloc] \
                initWithBundleResourceName:(RESOURCE) \
                                publicName:(PUBLICNAME) \
                              catalystName:(CATALYST)]; \
        }); \
        _btc_cached; \
    })

static os_unfair_lock BTCCompositeCacheLock = OS_UNFAIR_LOCK_INIT;

static inline NSUInteger BTCCompositeKey(BOOL graphite, BOOL accessibility) {
    return (graphite ? 2u : 0u) | (accessibility ? 1u : 0u);
}

static id BTCCompositeCacheGet(__strong id *slots, NSUInteger key) {
    os_unfair_lock_lock(&BTCCompositeCacheLock);
    id value = slots[key];
    os_unfair_lock_unlock(&BTCCompositeCacheLock);
    return value;
}

// Stores `value` only if the slot is empty; returns whichever object wins, so
// concurrent callers converge on a single shared instance.
static id BTCCompositeCacheStore(__strong id *slots, NSUInteger key, id value) {
    os_unfair_lock_lock(&BTCCompositeCacheLock);
    if (!slots[key]) slots[key] = value;
    id winner = slots[key];
    os_unfair_lock_unlock(&BTCCompositeCacheLock);
    return winner;
}

static NSAccessibilitySystemAppearance *NSCachedAccessibilitySystemCatalinaAppearance(void) {
    return BTC_CACHED_BUILTIN(@"NSAccessibilitySystemAppearance", @"Catalina/AccessibilitySystemAppearance", @"NSAppearanceNameAccessibilitySystem", @"UIAppearanceHighContrastAny");
}

static NSAquaAppearance *NSCachedAquaCatalinaAppearance(void) {
    return BTC_CACHED_BUILTIN(@"NSAquaAppearance", @"Catalina/SystemAppearance", @"NSAppearanceNameAqua", @"UIAppearanceLight");
}

static NSAquaAppearance *NSCachedGraphiteCatalinaAppearance(void) {
    return BTC_CACHED_BUILTIN(@"NSAquaAppearance", @"Catalina/GraphiteAppearance", @"NSAppearanceNameAqua", @"UIAppearanceLight");
}

static NSAquaAppearance *NSCachedAccessibilityCatalinaAppearance(void) {
    return BTC_CACHED_BUILTIN(@"NSAquaAppearance", @"Catalina/AccessibilityAppearance", @"NSAppearanceNameAccessibilityAqua", @"UIAppearanceHighContrastLight");
}

static NSAquaAppearance *NSCachedAccessibilityGraphiteCatalinaAppearance(void) {
    return BTC_CACHED_BUILTIN(@"NSAquaAppearance", @"Catalina/AccessibilityGraphiteAppearance", @"NSAppearanceNameAccessibilityAqua", @"NSAppearanceNameAccessibilityAqua");
}

static NSVibrantDarkAppearance *NSCachedVibrantDarkCatalinaAppearance(void) {
    return BTC_CACHED_BUILTIN(@"NSVibrantDarkAppearance", @"Catalina/DarkAppearance", @"NSAppearanceNameVibrantDark", @"NSAppearanceNameVibrantDark");
}

static NSVibrantDarkAppearance *NSCachedDarkGraphiteCatalinaAppearance(void) {
    return BTC_CACHED_BUILTIN(@"NSVibrantDarkAppearance", @"Catalina/GraphiteDarkAppearance", @"NSAppearanceNameVibrantDark", @"NSAppearanceNameVibrantDark");
}

static NSVibrantDarkAppearance *NSCachedAccessibilityDarkCatalinaAppearance(void) {
    return BTC_CACHED_BUILTIN(@"NSVibrantDarkAppearance", @"Catalina/AccessibilityDarkAppearance", @"NSAppearanceNameAccessibilityVibrantDark", @"NSAppearanceNameAccessibilityVibrantDark");
}

static NSVibrantDarkAppearance *NSCachedAccessibilityDarkGraphiteCatalinaAppearance(void) {
    return BTC_CACHED_BUILTIN(@"NSVibrantDarkAppearance", @"Catalina/AccessibilityDarkGraphiteAppearance", @"NSAppearanceNameAccessibilityVibrantDark", @"NSAppearanceNameAccessibilityVibrantDark");
}

static NSVibrantLightAppearance *NSCachedVibrantLightCatalinaAppearance(void) {
    return BTC_CACHED_BUILTIN(@"NSVibrantLightAppearance", @"Catalina/VibrantLightAppearance", @"NSAppearanceNameVibrantLight", @"NSAppearanceNameVibrantLight");
}

static NSVibrantLightAppearance *NSCachedAccessibilityVibrantLightCatalinaAppearance(void) {
    return BTC_CACHED_BUILTIN(@"NSVibrantLightAppearance", @"Catalina/AccessibilityVibrantLightAppearance", @"NSAppearanceNameAccessibilityVibrantLight", @"NSAppearanceNameAccessibilityVibrantLight");
}

static NSDarkAquaAppearance *NSCachedDarkAquaCatalinaAppearance(void) {
    return BTC_CACHED_BUILTIN(@"NSDarkAquaAppearance", @"Catalina/DarkAquaAppearance", @"NSAppearanceNameDarkAqua", @"UIAppearanceDark");
}

static NSDarkAquaAppearance *NSCachedDarkAquaGraphiteCatalinaAppearance(void) {
    return BTC_CACHED_BUILTIN(@"NSDarkAquaAppearance", @"Catalina/GraphiteDarkAquaAppearance", @"NSAppearanceNameDarkAqua", @"UIAppearanceDark");
}

static NSDarkAquaAppearance *NSCachedDarkAquaAccessibilityCatalinaAppearance(void) {
    return BTC_CACHED_BUILTIN(@"NSDarkAquaAppearance", @"Catalina/AccessibilityDarkAquaAppearance", @"NSAppearanceNameAccessibilityDarkAqua", @"UIAppearanceHighContrastDark");
}

static NSDarkAquaAppearance *NSCachedDarkAquaAccessibilityGraphiteCatalinaAppearance(void) {
    return BTC_CACHED_BUILTIN(@"NSDarkAquaAppearance", @"Catalina/AccessibilityGraphiteDarkAquaAppearance", @"NSAppearanceNameAccessibilityGraphiteDarkAqua", @"NSAppearanceNameAccessibilityGraphiteDarkAqua");
}

hook(NSString)
- (NSString *)stringByAppendingPathComponent:(NSString *)str {
    if (str.length == 23 && ((NSString *)self).length == 28 && [str isEqualTo:@"SystemAppearance.bundle"] && [self isEqualTo:@"/System/Library/CoreServices"]) {
        return @"/private/var/ammonia/core/tweaks/libBackToCatalina/SystemAppearance.bundle";
    }
    return _orig(NSString *, str);
}
endhook

#ifdef APPLY_BUNDLE
hook(NSAppearance)

+ (NSCompositeAppearance *)_aquaAppearanceWithAccessibility:(BOOL)accessibility {
    static id cache[4];
    BOOL grpahite = NSColorControlAccentIsGraphite();
    NSUInteger key = BTCCompositeKey(grpahite, accessibility);
    id cached = BTCCompositeCacheGet(cache, key);
    if (cached) return cached;

    NSCompositeAppearance *composite = _orig(NSCompositeAppearance *, accessibility);
    NSMutableArray *compositeAppearances = [composite.appearances mutableCopy];
    grpahite ? [compositeAppearances btc_insertObjectToFrontOfArray:NSCachedGraphiteCatalinaAppearance()] : nil;
    if (accessibility) {
        [compositeAppearances btc_insertObjectToFrontOfArray:NSCachedAccessibilitySystemCatalinaAppearance()];
        [compositeAppearances btc_insertObjectToFrontOfArray:NSCachedAccessibilityCatalinaAppearance()];
    }
    if (grpahite && accessibility) {
        [compositeAppearances btc_insertObjectToFrontOfArray:NSCachedAccessibilityGraphiteCatalinaAppearance()];
    }
    composite = [[NSClassFromString(@"NSCompositeAppearance") alloc] initWithAppearances:compositeAppearances];
    return BTCCompositeCacheStore(cache, key, composite);
}

+ (NSAppearance *)_aquaAppearance {
    static id cache[4];
    BOOL useAccessibility = NSWorkspace.sharedWorkspace.accessibilityDisplayShouldIncreaseContrast;
    BOOL useGraphite = NSColorControlAccentIsGraphite();
    NSUInteger key = BTCCompositeKey(useGraphite, useAccessibility);
    id cached = BTCCompositeCacheGet(cache, key);
    if (cached) return cached;

    NSCompositeAppearance *composite = _orig(NSCompositeAppearance *);
    NSMutableArray *appearances = [composite.appearances mutableCopy];

    [appearances btc_insertObjectToFrontOfArray:NSCachedAquaCatalinaAppearance()];
    if (useGraphite) {
        [appearances btc_insertObjectToFrontOfArray:NSCachedGraphiteCatalinaAppearance()];
    }
    if (useAccessibility) {
        [appearances btc_insertObjectToFrontOfArray:NSCachedAccessibilitySystemCatalinaAppearance()];
        [appearances btc_insertObjectToFrontOfArray:NSCachedAccessibilityCatalinaAppearance()];
    }
    if (useGraphite && useAccessibility) {
        [appearances btc_insertObjectToFrontOfArray:NSCachedAccessibilityGraphiteCatalinaAppearance()];
    }
    composite = [[NSClassFromString(@"NSCompositeAppearance") alloc] initWithAppearances:appearances];
    composite.name = @"NSAppearanceNameAqua";
    return BTCCompositeCacheStore(cache, key, composite);
}

+ (NSAppearance *)_vibrantDarkAppearance {
    static id cache[4];
    BOOL useAccessibility = NSWorkspace.sharedWorkspace.accessibilityDisplayShouldIncreaseContrast;
    BOOL useGraphite = NSColorControlAccentIsGraphite();
    NSUInteger key = BTCCompositeKey(useGraphite, useAccessibility);
    id cached = BTCCompositeCacheGet(cache, key);
    if (cached) return cached;

    NSCompositeAppearance *composite = _orig(NSCompositeAppearance *);
    NSMutableArray *appearances = [composite.appearances mutableCopy];
    [appearances btc_insertObjectToFrontOfArray:NSCachedDarkAquaCatalinaAppearance()];
    useGraphite ? [appearances btc_insertObjectToFrontOfArray:NSCachedDarkAquaGraphiteCatalinaAppearance()] : nil;
    if (useAccessibility) {
        [appearances btc_insertObjectToFrontOfArray:NSCachedVibrantDarkCatalinaAppearance()];
        useGraphite ? [appearances btc_insertObjectToFrontOfArray:NSCachedDarkGraphiteCatalinaAppearance()] : nil;
        [appearances btc_insertObjectToFrontOfArray:NSCachedAccessibilitySystemCatalinaAppearance()];
        [appearances btc_insertObjectToFrontOfArray:NSCachedDarkAquaAccessibilityCatalinaAppearance()];
        useGraphite ? [appearances btc_insertObjectToFrontOfArray:NSCachedDarkAquaAccessibilityGraphiteCatalinaAppearance()] : nil;
        [appearances btc_insertObjectToFrontOfArray:NSCachedAccessibilityDarkCatalinaAppearance()];
        useGraphite ? [appearances btc_insertObjectToFrontOfArray:NSCachedAccessibilityDarkGraphiteCatalinaAppearance()] : nil;
    } else {
        [appearances btc_insertObjectToFrontOfArray:NSCachedVibrantDarkCatalinaAppearance()];
        useGraphite ? [appearances btc_insertObjectToFrontOfArray:NSCachedDarkGraphiteCatalinaAppearance()] : nil;
    }
    composite = [[NSClassFromString(@"NSCompositeAppearance") alloc] initWithAppearances:appearances];
    composite.name = @"NSAppearanceNameVibrantDark";
    return BTCCompositeCacheStore(cache, key, composite);
}

+ (NSAppearance *)_vibrantLightAppearance {
    static id cache[4];
    BOOL useAccessibility = NSWorkspace.sharedWorkspace.accessibilityDisplayShouldIncreaseContrast;
    BOOL useGraphite = NSColorControlAccentIsGraphite();
    NSUInteger key = BTCCompositeKey(useGraphite, useAccessibility);
    id cached = BTCCompositeCacheGet(cache, key);
    if (cached) return cached;

    NSCompositeAppearance *composite = _orig(NSCompositeAppearance *);
    NSMutableArray *appearances = [composite.appearances mutableCopy];
    [appearances btc_insertObjectToFrontOfArray:NSCachedAquaCatalinaAppearance()];
    useGraphite ? [appearances btc_insertObjectToFrontOfArray:NSCachedGraphiteCatalinaAppearance()] : nil;
    if (useAccessibility) {
        [appearances btc_insertObjectToFrontOfArray:NSCachedAccessibilitySystemCatalinaAppearance()];
        [appearances btc_insertObjectToFrontOfArray:NSCachedAccessibilityCatalinaAppearance()];
        useGraphite ? [appearances btc_insertObjectToFrontOfArray:NSCachedAccessibilityGraphiteCatalinaAppearance()] : nil;
    }
    [appearances btc_insertObjectToFrontOfArray:NSCachedVibrantLightCatalinaAppearance()];
    useAccessibility ? [appearances btc_insertObjectToFrontOfArray:NSCachedAccessibilityVibrantLightCatalinaAppearance()] : nil;
    composite = [[NSClassFromString(@"NSCompositeAppearance") alloc] initWithAppearances:appearances];
    composite.name = @"NSAppearanceNameVibrantLight";
    return BTCCompositeCacheStore(cache, key, composite);
}

+ (NSAppearance *)_darkAquaAppearanceWithAccessibility:(BOOL)useAccessibility {
    static id cache[4];
    BOOL useGraphite = NSColorControlAccentIsGraphite();
    NSUInteger key = BTCCompositeKey(useGraphite, useAccessibility);
    id cached = BTCCompositeCacheGet(cache, key);
    if (cached) return cached;

    NSCompositeAppearance *composite = _orig(NSCompositeAppearance *, useAccessibility);
    NSMutableArray *appearances = [composite.appearances mutableCopy];
    if (useAccessibility) {
        [appearances btc_insertObjectToFrontOfArray:NSCachedAccessibilitySystemCatalinaAppearance()];
        [appearances btc_insertObjectToFrontOfArray:NSCachedDarkAquaAccessibilityCatalinaAppearance()];
    }

    if (useGraphite) {
        [appearances btc_insertObjectToFrontOfArray:NSCachedDarkAquaGraphiteCatalinaAppearance()];
    }
    
    if (useGraphite && useAccessibility) {
        [appearances btc_insertObjectToFrontOfArray:NSCachedDarkAquaAccessibilityGraphiteCatalinaAppearance()];
    }
    composite = [[NSClassFromString(@"NSCompositeAppearance") alloc] initWithAppearances:appearances];
    return BTCCompositeCacheStore(cache, key, composite);
}

+ (NSAppearance *)_darkAquaAppearance {
    static id cache[4];
    BOOL useAccessibility = NSWorkspace.sharedWorkspace.accessibilityDisplayShouldIncreaseContrast;
    BOOL useGraphite = NSColorControlAccentIsGraphite();
    NSUInteger key = BTCCompositeKey(useGraphite, useAccessibility);
    id cached = BTCCompositeCacheGet(cache, key);
    if (cached) return cached;

    NSCompositeAppearance *composite = _orig(NSCompositeAppearance *);
    NSMutableArray *appearances = [composite.appearances mutableCopy];
    [appearances btc_insertObjectToFrontOfArray:NSCachedDarkAquaCatalinaAppearance()];
    useGraphite ? [appearances btc_insertObjectToFrontOfArray:NSCachedDarkAquaGraphiteCatalinaAppearance()] : nil;
    if (useAccessibility) {
        [appearances btc_insertObjectToFrontOfArray:NSCachedAccessibilitySystemCatalinaAppearance()];
        [appearances btc_insertObjectToFrontOfArray:NSCachedDarkAquaAccessibilityCatalinaAppearance()];
    }
    if (useGraphite && useAccessibility) {
        [appearances btc_insertObjectToFrontOfArray:NSCachedDarkAquaAccessibilityGraphiteCatalinaAppearance()];
    }
    composite = [[NSClassFromString(@"NSCompositeAppearance") alloc] initWithAppearances:appearances];
    composite.name = @"NSAppearanceNameDarkAqua";
    return BTCCompositeCacheStore(cache, key, composite);
}
endhook
#endif

hook(NSCompositeAppearance)
- (BOOL)_usesMetricsAppearance {
    return NO;
}
endhook

// Customize Toolbar: show button with bezels
hook(NSVibrantDarkAppearance)

- (NSAppearance *)_appearanceForNonVibrantContent {
    return [NSAppearance appearanceNamed:@"NSAppearanceNameDarkAqua"];
}

- (BOOL)_usesMetricsAppearance {
    return NO;
}

endhook

hook(NSVibrantLightAppearance)

- (NSAppearance *)_appearanceForNonVibrantContent {
    return [NSAppearance appearanceNamed:@"NSAppearanceNameAqua"];
}

- (BOOL)_usesMetricsAppearance {
    return NO;
}

endhook

hook(NSAquaAppearance)
- (BOOL)_usesMetricsAppearance {
    return NO;
}
endhook

hook(NSDarkAquaAppearance)
- (BOOL)_usesMetricsAppearance {
    return NO;
}
endhook
