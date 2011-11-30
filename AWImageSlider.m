//
//  AWImageSlider.m
//  AWSlider
//
//  Created by Alex Winston on 2/17/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "AWImageSlider.h"


@implementation AWImageSlider

- (id)initWithFrame:(NSRect)frame {
	self = [super initWithFrame:frame];
    if (self) {
        // Initialization code here.
		_sliderValue = [self bounds].size.width/2;
		
		_knobImage = [[NSImage imageNamed:@"PCPlayerSliderKnobAlt.png"] retain];
		_knobDownImage = [[NSImage imageNamed:@"PCPlayerSliderKnob.png"] retain];
		
        _knobImageView = [[[NSImageView alloc] initWithFrame:NSMakeRect(0, 0, 16, 16)] retain];
        [_knobImageView setImage: _knobImage];
		
		[self addSubview:_knobImageView];
    }
    return self;
}

- (void)drawRect:(NSRect)dirtyRect {
    NSRect frame = [_knobImageView frame];
	frame.origin.x = _sliderValue - 8;
	frame.origin.y = 4;
	
	if (frame.origin.x < 0)
		frame.origin.x = 0;
	if (frame.origin.x > [self bounds].size.width - 16)
		frame.origin.x = [self bounds].size.width - 16;
	
	_knobImageView.frame = frame;
}

- (void)dealloc {
	[_knobImage release];
	[_knobDownImage release];
	[_knobImageView release];
	[super dealloc];
}

@end
