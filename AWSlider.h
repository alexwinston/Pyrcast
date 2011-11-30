//
//  AWSlider.h
//  AWSlider
//
//  Created by Alex Winston on 2/14/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>


@interface AWSlider : NSView {
	BOOL _enabled;
	CGFloat _sliderValue;
	id delegate;
	SEL sliderDownSelector;
	SEL sliderDraggedSelector;
	SEL sliderUpSelector;
}
@property (nonatomic, assign) id delegate;
- (void)setSliderDownSelector:(SEL)selector;
- (void)setSliderDraggedSelector:(SEL)selector;
- (void)setSliderUpSelector:(SEL)selector;
- (BOOL)getEnabled;
- (void)setEnabled:(BOOL)enabled;
- (CGFloat)getFloatValue;
- (void)setFloatValue:(CGFloat)value;
@end
