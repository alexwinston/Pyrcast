//
//  PyrcastAppDelegate.m
//  Pyrcast
//
//  Created by Alex Winston on 6/21/10.
//  Copyright 2010 Alex Winston. All rights reserved.
//

#import "PyrcastAppDelegate.h"


@implementation PyrcastAppDelegate

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification {
	[NSApp activateIgnoringOtherApps:YES];
	
	// Disable the NSURLCache
	[[NSURLCache sharedURLCache] setMemoryCapacity:0];
	[[NSURLCache sharedURLCache] setDiskCapacity:0]; 
}

- (BOOL)applicationShouldHandleReopen:(NSApplication *)theApplication hasVisibleWindows:(BOOL)flag {
	[_pyrcastWindow makeKeyAndOrderFront:self];

	return YES;
}

@end
