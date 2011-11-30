//
//  PyrcastPreferencesController.m
//  Pyrcast
//
//  Created by Alex Winston on 2/23/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "PyrcastPreferencesController.h"


@implementation PyrcastPreferencesController

#pragma mark -
#pragma mark PyrcastPreferencesController lifecycle methods

- (PyrcastPreferencesController *)init {
	if (!(self = [super init]))
		return nil;
	
	return self;
}

- (void)dealloc {
	[super dealloc];
}

- (void)awakeFromNib {
	NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
	if ([userDefaults boolForKey:@"PCGrowlEnabled"])
		[growlButton setState:NSOnState];
	if ([userDefaults boolForKey:@"PCMenuBarDisabled"])
		[hideMenuBarButton setState:NSOnState];
	if ([userDefaults boolForKey:@"PCDockDisabled"]) {
		[hideDockButton setState:NSOnState];
		[hideMenuBarButton setEnabled:NO];
	}
}

- (void)growlButtonClicked:(id)sender {
	NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
	
	if (growlButton.state == NSOnState) {
		[userDefaults setBool:YES forKey:@"PCGrowlEnabled"];
	} else if (growlButton.state == NSOffState) {
		[userDefaults setBool:NO forKey:@"PCGrowlEnabled"];
	}
}

- (void)hideMenuBarButtonClicked:(id)sender {
	NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
	
	if (hideMenuBarButton.state == NSOnState) {
		[userDefaults setBool:YES forKey:@"PCMenuBarDisabled"];
		[pyrcastController setMenuBarDisabled:YES];
	} else if (hideMenuBarButton.state == NSOffState) {
		[userDefaults setBool:NO forKey:@"PCMenuBarDisabled"];
		[pyrcastController setMenuBarDisabled:NO];
	}
}

- (void)hideDockButtonClicked:(id)sender {
	NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
	
	if (hideDockButton.state == NSOnState) {
		[userDefaults setBool:YES forKey:@"PCDockDisabled"];
		
		hideMenuBarButton.state = NSOffState;
		[hideMenuBarButton setEnabled:NO];
		[userDefaults setBool:NO forKey:@"PCMenuBarDisabled"];
		[pyrcastController setMenuBarDisabled:NO];
	} else if (hideDockButton.state == NSOffState) {
		[userDefaults setBool:NO forKey:@"PCDockDisabled"];
		[hideMenuBarButton setEnabled:YES];
	}
}

- (void)shortcutRecorder:(SRRecorderControl *)shortcutRecorder keyComboDidChange:(KeyCombo)newKeyCombo {
	if (shortcutRecorder == playPauseShortcutRecorder) {
		if (playPauseHotKey != nil) {
			[[PTHotKeyCenter sharedCenter] unregisterHotKey:playPauseHotKey];
			[playPauseHotKey release];
			playPauseHotKey = nil;
		}

		// Register play/pause global hotkey
		playPauseHotKey = [[[PTHotKey alloc] initWithIdentifier:@"PCShortcutPlayPause"
													  keyCombo:[PTKeyCombo keyComboWithKeyCode:newKeyCombo.code
																					 modifiers:[shortcutRecorder cocoaToCarbonFlags: newKeyCombo.flags]]] retain];
		[playPauseHotKey setTarget: self];
		[playPauseHotKey setAction: @selector(playPauseHotKey:)];
		
		[[PTHotKeyCenter sharedCenter] registerHotKey:playPauseHotKey];
	} else if (shortcutRecorder == restartShortcutRecorder) {
		if (restartHotKey != nil) {
			[[PTHotKeyCenter sharedCenter] unregisterHotKey:restartHotKey];
			[restartHotKey release];
			restartHotKey = nil;
		}
		
		// Register play/pause global hotkey
		restartHotKey = [[[PTHotKey alloc] initWithIdentifier:@"PCShortcutRestart"
													keyCombo:[PTKeyCombo keyComboWithKeyCode:newKeyCombo.code
																					modifiers:[shortcutRecorder cocoaToCarbonFlags: newKeyCombo.flags]]] retain];
		[restartHotKey setTarget: self];
		[restartHotKey setAction: @selector(restartHotKey:)];
		
		[[PTHotKeyCenter sharedCenter] registerHotKey:restartHotKey];
	} else if (shortcutRecorder == skipShortcutRecorder) {
		if (skipHotKey != nil) {
			[[PTHotKeyCenter sharedCenter] unregisterHotKey:skipHotKey];
			[skipHotKey release];
			skipHotKey = nil;
		}
		
		// Register global skip hotkey
		skipHotKey = [[[PTHotKey alloc] initWithIdentifier:@"PCShortcutSkip"
													   keyCombo:[PTKeyCombo keyComboWithKeyCode:newKeyCombo.code
																					  modifiers:[shortcutRecorder cocoaToCarbonFlags: newKeyCombo.flags]]] retain];
		[skipHotKey setTarget: self];
		[skipHotKey setAction: @selector(skipHotKey:)];
		
		[[PTHotKeyCenter sharedCenter] registerHotKey:skipHotKey];
	} else if (shortcutRecorder == rateUpShortcutRecorder) {
		if (rateUpHotKey != nil) {
			[[PTHotKeyCenter sharedCenter] unregisterHotKey:rateUpHotKey];
			[rateUpHotKey release];
			rateUpHotKey = nil;
		}
		
		// Register global rate up hotkey
		rateUpHotKey = [[[PTHotKey alloc] initWithIdentifier:@"PCShortcutRateUp"
													keyCombo:[PTKeyCombo keyComboWithKeyCode:newKeyCombo.code
																				   modifiers:[shortcutRecorder cocoaToCarbonFlags: newKeyCombo.flags]]] retain];
		[rateUpHotKey setTarget: self];
		[rateUpHotKey setAction: @selector(rateUpHotKey:)];
		
		[[PTHotKeyCenter sharedCenter] registerHotKey:rateUpHotKey];
	} else if (shortcutRecorder == rateDownShortcutRecorder) {
		if (rateDownHotKey != nil) {
			[[PTHotKeyCenter sharedCenter] unregisterHotKey:rateDownHotKey];
			[rateDownHotKey release];
			rateDownHotKey = nil;
		}
		
		// Register global rate down hotkey
		rateDownHotKey = [[[PTHotKey alloc] initWithIdentifier:@"PCShortcutRateDown"
													  keyCombo:[PTKeyCombo keyComboWithKeyCode:newKeyCombo.code
																					 modifiers:[shortcutRecorder cocoaToCarbonFlags: newKeyCombo.flags]]] retain];
		[rateDownHotKey setTarget: self];
		[rateDownHotKey setAction: @selector(rateDownHotKey:)];
		
		[[PTHotKeyCenter sharedCenter] registerHotKey:rateDownHotKey];
	}
}

- (void)playPauseHotKey:(PTHotKey *)hotKey {
	//NSLog(@"%@", [hotKey identifier]);
	[pyrcastController playPause:self];
}

- (void)restartHotKey:(PTHotKey *)hotKey {
	//NSLog(@"%@", [hotKey identifier]);
	[pyrcastController restart:self];
}

- (void)skipHotKey:(PTHotKey *)hotKey {
	//NSLog(@"%@", [hotKey identifier]);
	[pyrcastController skip:self];
}

- (void)rateUpHotKey:(PTHotKey *)hotKey {
	//NSLog(@"%@", [hotKey identifier]);
	[pyrcastController rateUp:self];
}

- (void)rateDownHotKey:(PTHotKey *)hotKey {
	//NSLog(@"%@", [hotKey identifier]);
	[pyrcastController rateDown:self];
}

@end
