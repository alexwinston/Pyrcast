//
//  Station.h
//  Pyrcast
//
//  Created by Alex Winston on 2/22/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>


@interface Station : NSObject {
	NSString *token;
	NSString *name;
}
@property (retain) NSString *token;
@property (retain) NSString *name;
@end
