//
//  HMediaKeys.m
//  SweetFM
//
//  Created by Q on 31.05.09.
//
//
//  Permission is hereby granted, free of charge, to any person 
//  obtaining a copy of this software and associated documentation
//  files (the "Software"), to deal in the Software without restriction,
//  including without limitation the rights to use, copy, modify, 
//  merge, publish, distribute, sublicense, and/or sell copies of 
//  the Software, and to permit persons to whom the Software is 
//  furnished to do so, subject to the following conditions:
//
//  The above copyright notice and this permission notice shall be 
//  included in all copies or substantial portions of the Software.
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, 
//  EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES 
//  OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.
//  IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR 
//  ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF 
//  CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION
//  WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.

#import "HMediaKeys.h"


// Notifications
NSString * const MediaKeyPlayPauseUpNotification = @"MediaKeyPlayPauseUpNotification";
NSString * const MediaKeyNextUpNotification = @"MediaKeyNextUpNotification";
NSString * const MediaKeyPreviousUpNotification = @"MediaKeyPreviousUpNotification";

CFMachPortRef eventPort;

@implementation HMediaKeys

CGEventRef tapEventCallback(CGEventTapProxy proxy, CGEventType type, CGEventRef event, void *refcon) {
	// On 10.6, the kCGEventTapDisabledByTimeout event seems to come incorrectly. If we get it, reenable the tap.
    // http://lists.apple.com/archives/quartz-dev/2009/Sep/msg00006.html
	// https://kevingessner.kilnhg.com/Repo/Public/Group/FunctionFlip/File/FFHelperApp.m
	if(type == kCGEventTapDisabledByTimeout) {
        //NSLog(@"got kCGEventTapDisabledByTimeout, reenabling tap");
		CGEventTapEnable(eventPort, TRUE);
		return event; // NULL also works
	}
	
	NSEvent* nsEvent = [NSEvent eventWithCGEvent:event];
	NSInteger eventData = 0;
	
	if([nsEvent type] == NSSystemDefined)
		eventData = [nsEvent data1];
			
	NSNotificationCenter *center = [NSNotificationCenter defaultCenter];
	
	if(type==NX_SYSDEFINED && eventData==PlayPauseKeyUp) {
		[center postNotificationName:MediaKeyPlayPauseUpNotification object:(HMediaKeys *)refcon];
		return NULL;
	} else if(type==NX_SYSDEFINED && eventData==NextKeyUp) {
		[center postNotificationName:MediaKeyNextUpNotification object:(HMediaKeys *)refcon];
		return NULL;
	} else if(type==NX_SYSDEFINED && eventData==PreviousKeyUp) {
		[center postNotificationName:MediaKeyPreviousUpNotification object:(HMediaKeys *)refcon];
		return NULL;
	}
	
	if(type==NX_SYSDEFINED && (eventData==PlayPauseKeyDown || eventData==NextKeyDown || eventData==PreviousKeyDown))
		return NULL;
	
	return event;
}

- (void)listenForKeyEvents:(id)sender {
	//NSLog(@"listenForKeyEvents:");
	
	//CFMachPortRef eventPort;
	CFRunLoopSourceRef eventSrc;
	CFRunLoopRef runLoop;
	
	@try {	
		CGEventTapOptions opts = kCGEventTapOptionDefault;
		
		// DEBUG
		//opts = kCGEventTapOptionListenOnly;
		
		eventPort = CGEventTapCreate (kCGSessionEventTap,
									  kCGHeadInsertEventTap,
									  opts,
									  CGEventMaskBit(NX_SYSDEFINED) | CGEventMaskBit(NX_KEYUP),
									  tapEventCallback,
									  self);
		
		if (eventPort == NULL)
			NSLog(@"Event port is null");
		
		// Get the event source from port
		eventSrc = CFMachPortCreateRunLoopSource(kCFAllocatorDefault, eventPort, 0);
		
		if (eventSrc == NULL)
			NSLog(@"No event run loop source found");
		
		// Get the current threads run loop
		runLoop = CFRunLoopGetCurrent();
		
		if (eventSrc == NULL)
			NSLog(@"No event run loop");
		
		// Add the runloop source
		CFRunLoopAddSource(runLoop, eventSrc, kCFRunLoopCommonModes);
	
		// Enable the event tap
		CGEventTapEnable(eventPort, true);
		//while ([[NSRunLoop currentRunLoop] runMode:NSDefaultRunLoopMode beforeDate:[NSDate distantFuture]]);
	} @catch (NSException *e) {
		NSLog(@"Exception caught while attempting to create run loop for hotkey: %@", e);
	}
}

@end
