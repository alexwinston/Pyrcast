//
//  HistoryTextFieldCell.h
//  Pyrcast
//
//  Created by Alex Winston on 2/21/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>


@interface HistoryTextFieldCell : NSTextFieldCell {
	id _delegate;
	int _rowIndex;
	NSImage *_ratingImage;
}
- (void)setDelegate:(id)delegate;
- (void)setRowIndex:(int)rowIndex;
- (void)setRatingImage:(NSImage *)ratingImage;
@end
