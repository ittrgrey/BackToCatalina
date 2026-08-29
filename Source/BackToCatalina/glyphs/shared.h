//
//  shared.h
//  BackToCatalina
//
//  Created by ittrgrey on 29/08/2026.
//

#include "../BackToCatalina.h"
#include "../ZKSwizzle.h"

@interface NSWindow (ToolbarViewRef)
- (id)_toolbarView;
@end

static const NSDictionary* glyphMap = @{
    @"chevron.backward": @"Backarrow.pdf",
    @"chevron.left": @"Backarrow.pdf", // Different glyphs are used... when it's not a toolbar
    @"chevron.forward": @"Forwardarrow.pdf",
    @"chevron.right": @"Forwardarrow.pdf", // Different glyphs are used... when it's not a toolbar
    @"sidebar.left": @"sidebar.pdf",
    @"sidebar.leading": @"sidebar.pdf",
    @"square.and.arrow.up": @"share.pdf",
    @"rectangle.split.3x1": @"ViewSwitcherColumns.pdf",
    @"ellipsis": @"Gear.pdf",
    @"folder.badge.plus": @"newFolder.pdf",
    @"square.and.pencil": @"TB_NewTemplate.pdf",
    @"textformat.size.smaller": @"textSmaller.pdf",
    @"textformat.size.larger": @"textBigger.pdf",
    @"magnifyingglass": @"SearchMagGlass.pdf",
    @"info.circle": @"getInfoOutline.pdf",
    @"plus": @"plus.pdf",
    @"minus": @"minus.pdf",
    @"play.fill": @"Play.pdf",
    @"pause.fill": @"Pause.pdf",
    @"arrow.clockwise": @"RefreshButton.pdf",
    @"squares.below.rectangle": @"ToolbarGalleryView.pdf",
    @"square.grid.2x2": @"ToolbarIconView.pdf",
    @"square.grid.3x2": @"ToolbarIconView.pdf",
    @"square.grid.3x1.below.line.grid.1x2": @"ToolbarArrangeByTemplate.pdf",
    @"square.grid.4x3.fill": @"TopSitesButton.pdf",
    @"list.bullet": @"ViewSwitcherList.pdf",
    @"tag": @"ToolbarTagIcon.pdf",
    @"arrow.down.circle": @"transfer-download.pdf",
    @"arrow.down": @"ToolbarDownloadsArrow.pdf",
    @"square.on.square": @"ToolbarButtonTabOverview.pdf",
    @"star": @"ToolbarBookmarksBar.pdf",
    @"printer": @"print.pdf",
    @"rectangle.and.pencil.and.ellipsis": @"autofill.pdf",
    @"house": @"home.pdf",
    @"gearshape": @"Gear.pdf",
    @"icloud": @"CloudTabs.pdf",
    @"envelope": @"ToolbarEmail.pdf",
    @"clock": @"ToolbarHistory.pdf",
    @"plus.circle": @"plusEnclosed.pdf",
    @"speaker.wave.2.fill": @"SpeakerWithSoundStroke.pdf",
};

NSImage* FindLegacyGlyph(NSString* symbolName);
NSImage* GetToolbarButtonImage(NSView* view, NSImage* symbol);
CGRect CalculateImageFrame(NSView* view, NSImage* image, CGRect frame);
