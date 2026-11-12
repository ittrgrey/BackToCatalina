//
//  BTCAppMaps.m
//  BackToCatalina
//
//  Created by ittrgrey on 12/11/2026.
//

#include <AppKit/AppKit.h>
#include "CommonDef.h"
#include "ZKSwizzle.h"

#ifdef APPLY_SYRAH
hook(MKPlaceCollectionViewModel)

- (NSAttributedString*)collectionTitle {
    // Particular issue with certain strings in this dialog causing crashing issues when SF Pro isn't the system font
    return [[NSAttributedString alloc] initWithString:@""];
}

endhook
#endif

