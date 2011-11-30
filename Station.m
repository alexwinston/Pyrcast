//
//  Station.m
//  Pyrcast
//
//  Created by Alex Winston on 2/22/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "Station.h"


@implementation Station

@synthesize token;
@synthesize name;

- (void)dealloc {
	[token release];
	[name release];
	[super dealloc];
}
@end
