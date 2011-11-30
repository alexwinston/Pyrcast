//
//  PyrcastPreferencesController.h
//  Pyrcast
//
//  Created by Alex Winston on 2/23/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>

#import "PTHotKey.h"
#import "PTHotKeyCenter.h"
#import "PyrcastStatusBarController.h"
#import "SRCommon.h"
#import "SRRecorderControl.h"


@interface PyrcastPreferencesController : NSObject {
	IBOutlet PyrcastStatusBarController *pyrcastController;
	
	IBOutlet SRRecorderControl *playPauseShortcutRecorder;
	IBOutlet SRRecorderControl *restartShortcutRecorder;
	IBOutlet SRRecorderControl *skipShortcutRecorder;
	
	IBOutlet SRRecorderControl *rateUpShortcutRecorder;
	IBOutlet SRRecorderControl *rateDownShortcutRecorder;
	
	IBOutlet NSButton *growlButton;
	
	IBOutlet NSButton *hideMenuBarButton;
	IBOutlet NSButton *hideDockButton;
	
	PTHotKey *playPauseHotKey;
	PTHotKey *restartHotKey;
	PTHotKey *skipHotKey;
	
	PTHotKey *rateUpHotKey;
	PTHotKey *rateDownHotKey;
}
- (void)growlButtonClicked:(id)sender;
- (void)hideMenuBarButtonClicked:(id)sender;
- (void)hideDockButtonClicked:(id)sender;
@end
