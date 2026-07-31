//
//  shared.m
//  BackToCatalina
//
//  Created by ittrgrey on 28/07/2026.
//

#include "shared.h"

NSString* GetDockOrientation(void) {
    return [[[NSUserDefaults standardUserDefaults] persistentDomainForName:@"com.apple.dock"] valueForKey:@"orientation"];
}
