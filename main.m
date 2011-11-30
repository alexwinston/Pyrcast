//
//  main.m
//  Pyrcast
//
//  Created by Alex Winston on 6/21/10.
//  Copyright 2010 Alex Winston. All rights reserved.
//

#import <Cocoa/Cocoa.h>

int main(int argc, char *argv[])
{
	NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
	
	BOOL applicationIsAgent = [[NSUserDefaults standardUserDefaults] boolForKey:@"PCDockDisabled"];
	if (!applicationIsAgent) {
		ProcessSerialNumber psn = { 0, kCurrentProcess };
		TransformProcessType(&psn, kProcessTransformToForegroundApplication);
		SetFrontProcess(&psn);
	}
	
	[pool release];

    return NSApplicationMain(argc,  (const char **) argv);
}
