//
//  AWSlider.m
//  AWSlider
//
//  Created by Alex Winston on 2/14/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "AWSlider.h"


@implementation AWSlider
@synthesize delegate;

- (id)initWithFrame:(NSRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
		// Initialization
		_enabled = YES;
		_sliderValue = 0.0;
    }
    return self;
}

- (void)_setSliderValue:(CGFloat)sliderValue {
	CGFloat previousSliderValue = _sliderValue;
	
	NSRect bounds = [self bounds];
	if (sliderValue < 0) {
		_sliderValue = 0;
	} else if (sliderValue > bounds.size.width) {
		_sliderValue = bounds.size.width;
	} else if (_sliderValue != sliderValue) {
		_sliderValue = sliderValue;
	}
	
	// Redraw the slider if it has been updated
	if (_sliderValue != previousSliderValue)
		[self setNeedsDisplay:YES];
}

- (void)setSliderDownSelector:(SEL)selector {
	sliderDownSelector = selector;
}

- (void)setSliderDraggedSelector:(SEL)selector {
	sliderDraggedSelector = selector;
}

- (void)setSliderUpSelector:(SEL)selector {
	sliderUpSelector = selector;
}

- (void)drawRect:(NSRect)dirtyRect {
	[NSGraphicsContext saveGraphicsState];
	
	// Create the clip path
	NSRect bounds = [self bounds];
	bounds.origin.y += 1;
	bounds.size.height -= 1;
	
	[[NSColor colorWithCalibratedWhite:1.0 alpha:0.3] set];
	NSRect bottomBevelBounds = bounds;
	bottomBevelBounds.origin.y -= 1; 
	NSBezierPath *bottomBevel = [NSBezierPath bezierPathWithRoundedRect:bottomBevelBounds
																xRadius:bottomBevelBounds.size.height/2
																yRadius:bottomBevelBounds.size.height/2];
	[bottomBevel fill];
	
    NSBezierPath *outlineClipPath = [NSBezierPath bezierPathWithRoundedRect:bounds
																	xRadius:bounds.size.height/2
																	yRadius:bounds.size.height/2];
	// Add the path to the clip shape.
	[outlineClipPath addClip];
	
	// Fill the path that will be clipped
	NSGradient *outlineGradient = [[[NSGradient alloc] initWithStartingColor:[NSColor colorWithCalibratedRed:25.0/255.0 green:25.0/255.0 blue:25.0/255.0 alpha:1.0]
																   endingColor:[NSColor colorWithCalibratedRed:32.0/255.0 green:32.0/255.0 blue:32.0/255.0 alpha:1.0]] autorelease];
    [outlineGradient drawInRect:bounds angle:270];
	
	[NSGraphicsContext restoreGraphicsState];
	
	[NSGraphicsContext saveGraphicsState];
	
	NSRect innerBounds = bounds;
	innerBounds.origin.x += 1;
	innerBounds.origin.y += 1;
	innerBounds.size.width -= 2;
	innerBounds.size.height -= 2;
	
	NSBezierPath *clipPath = [NSBezierPath bezierPathWithRoundedRect:innerBounds
															 xRadius:innerBounds.size.height/2
															 yRadius:innerBounds.size.height/2];
	// Add the path to the clip shape.
	[clipPath addClip];
	
	NSGradient *backgroundGradient = [[[NSGradient alloc] initWithStartingColor:[NSColor colorWithCalibratedRed:70.0/255.0 green:70.0/255.0 blue:70.0/255.0 alpha:1]
																	endingColor:[NSColor colorWithCalibratedRed:90.0/255.0 green:90.0/255.0 blue:90.0/255.0 alpha:1]] autorelease];
	[backgroundGradient drawInRect:innerBounds angle:270];
		
	if (_enabled) {
		NSRect sliderBounds = innerBounds;
		sliderBounds.size.width = _sliderValue;
		NSGradient *sliderGradient = [[[NSGradient alloc] initWithStartingColor:[NSColor colorWithCalibratedRed:45.0/255.0 green:45.0/255.0 blue:45.0/255.0 alpha:1]
																	endingColor:[NSColor colorWithCalibratedRed:60.0/255.0 green:60.0/255.0 blue:60.0/255.0 alpha:1]] autorelease];
		[sliderGradient drawInRect:sliderBounds angle:270];
		
		// Draw the slider shadow
		NSRect shadowBounds = innerBounds;
		shadowBounds.origin.y = innerBounds.size.height;
		shadowBounds.size.height /= 2;
		NSGradient *shadowGradient = [[[NSGradient alloc] initWithStartingColor:[NSColor colorWithCalibratedRed:0.0 green:0.0 blue:0.0 alpha:.3]
																	endingColor:[NSColor colorWithCalibratedRed:0.0 green:0.0 blue:0.0 alpha:.0]] autorelease];
		[shadowGradient drawInRect:shadowBounds angle:270];
	}
	
	[NSGraphicsContext restoreGraphicsState];
}

- (void)mouseDown:(NSEvent *)theEvent {
	[self _setSliderValue:[self convertPoint:[theEvent locationInWindow] fromView:nil].x];
	
	// If we have a delegate, and that delegate indeed does implement our delegate method
	if(delegate && [delegate respondsToSelector:sliderDownSelector])
		[delegate performSelector:sliderDownSelector withObject:theEvent];
}

- (void)mouseDragged:(NSEvent *)theEvent {
	[self _setSliderValue:[self convertPoint:[theEvent locationInWindow] fromView:nil].x];
	
	// If we have a delegate, and that delegate indeed does implement our delegate method
	if(delegate && [delegate respondsToSelector:sliderDraggedSelector])
		[delegate performSelector:sliderDraggedSelector withObject:theEvent];
}

- (void)mouseUp:(NSEvent *)theEvent {
	// If we have a delegate, and that delegate indeed does implement our delegate method
	if(delegate && [delegate respondsToSelector:sliderUpSelector])
		[delegate performSelector:sliderUpSelector withObject:theEvent];
}

- (BOOL)getEnabled {
	return _enabled;
}

- (void)setEnabled:(BOOL)enabled {
	_enabled = enabled;
}

- (CGFloat)getFloatValue {
	return _sliderValue / [self bounds].size.width;
}

- (void)setFloatValue:(CGFloat)value {
	[self _setSliderValue:[self bounds].size.width * value];
}

@end
