//
//  AWImageSlider.h
//  AWSlider
//
//  Created by Alex Winston on 2/17/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "AWSlider.h"


@interface AWImageSlider : AWSlider {
	NSImageView *_knobImageView;
	NSImage *_knobImage;
	NSImage *_knobDownImage;
}
@end
