#import <Cocoa/Cocoa.h>
#import "ZKSwizzle.h"

hook(NSTableView)
- (NSInteger)_resolvedSidebarType {
    return 2;
}
endhook
