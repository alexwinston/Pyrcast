//
//  HistoryTextFieldCell.m
//  Pyrcast
//
//  Created by Alex Winston on 2/21/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "HistoryTextFieldCell.h"
#import "Song.h"


@implementation HistoryTextFieldCell

- (void)dealloc {
	if (_delegate)
		[_delegate release];
	if (_ratingImage)
		[_ratingImage release];
	[super dealloc];
}

- (void)setDelegate:(id)delegate {
	if (_delegate)
		[_delegate release];
	_delegate = [delegate retain];
}

- (void)setRowIndex:(int)rowIndex {
	_rowIndex = rowIndex;
}

- (void)setRatingImage:(id)ratingImage {
	if (_ratingImage)
		[_ratingImage release];
	_ratingImage = [ratingImage retain];
}

- (void)drawWithFrame:(NSRect)cellFrame inView:(NSView *)controlView {
	Song *song = [_delegate performSelector:@selector(objectValueForTableRowIndex:) withObject:[NSNumber numberWithInt:_rowIndex]];
	if (song) {
		cellFrame.size.width += 2;
		
		// Draw alternating background
		if (_rowIndex % 2 == 1) {
			[[NSColor colorWithCalibratedRed:250.0/255.0f green:250.0/255.0f blue:250.0/255.0f alpha:1.0f] set];
			NSRectFill(cellFrame);
			
			// Draw the top cell divider
			NSRect cellDivider = NSMakeRect(cellFrame.origin.x, cellFrame.origin.y - 1, cellFrame.size.width, 1);
			NSRectFill(cellDivider);
		}
		
		// Draw the album background when there isn't an image, 64x64
		[[NSColor blackColor] set];
		NSRectFill(NSMakeRect(cellFrame.origin.x, cellFrame.origin.y - 1, cellFrame.size.height + 1,  cellFrame.size.height + 1));
		
		// Draw the album image
		[song.albumCoverImage compositeToPoint:NSMakePoint(cellFrame.origin.x,cellFrame.origin.y + cellFrame.size.height)
									 operation:NSCompositeSourceOver];
		
		// Draw the album glare
		[[NSImage imageNamed:@"PCHistoryAlbumGlare.png"] compositeToPoint:NSMakePoint(cellFrame.origin.x,cellFrame.origin.y + cellFrame.size.height)
																operation:NSCompositeSourceOver];
		
		// Cropping line break style
		NSMutableParagraphStyle* clippingStyle = [[[NSParagraphStyle defaultParagraphStyle] mutableCopy] autorelease];
		[clippingStyle setLineBreakMode:NSLineBreakByClipping];
		
		// Set the font color to light gray
		NSColor *lightGrayColor = [NSColor colorWithCalibratedRed:240.0f/255.0f green:240.0f/255.0f blue:240.0f/255.0f alpha:1.0f];
		
		NSMutableDictionary *backgroundArtistDictionary = [[[NSMutableDictionary alloc] initWithObjectsAndKeys:
															[NSFont boldSystemFontOfSize:48.0], NSFontAttributeName,
															lightGrayColor, NSForegroundColorAttributeName,
															clippingStyle, NSParagraphStyleAttributeName,
															nil] autorelease];
		[song.artist drawInRect:NSMakeRect(cellFrame.origin.x + 70, cellFrame.origin.y + 3, 280, 60) withAttributes:backgroundArtistDictionary];
		
		// Truncating line break style
		NSMutableParagraphStyle* style = [[[NSParagraphStyle defaultParagraphStyle] mutableCopy] autorelease];
		[style setLineBreakMode:NSLineBreakByTruncatingTail];
		
		// Set the font color to black
		NSColor *darkGrayColor = [NSColor colorWithCalibratedRed:55.0f/255.0f green:55.0f/255.0f blue:55.0f/255.0f alpha:1.0f];

		NSMutableDictionary *songTitleDictionary = [[[NSMutableDictionary alloc] initWithObjectsAndKeys:
													 [NSFont boldSystemFontOfSize:14.0], NSFontAttributeName,
													 darkGrayColor, NSForegroundColorAttributeName,
													 style, NSParagraphStyleAttributeName,
													 nil] autorelease];
		[song.title drawInRect:NSMakeRect(cellFrame.origin.x + 80, cellFrame.origin.y + 3, 240, 18) withAttributes:songTitleDictionary];
		
		NSMutableDictionary *artistNameDictionary = [[[NSMutableDictionary alloc] initWithObjectsAndKeys:
													  [NSFont systemFontOfSize:12.0], NSFontAttributeName,
													  darkGrayColor, NSForegroundColorAttributeName,
													  style, NSParagraphStyleAttributeName,
													  nil] autorelease];
		[song.artist drawInRect:NSMakeRect(cellFrame.origin.x + 80, cellFrame.origin.y + 23, 240, 18) withAttributes:artistNameDictionary];
		
		NSMutableDictionary *albumNameDictionary = [[[NSMutableDictionary alloc] initWithObjectsAndKeys:
													 [NSFont systemFontOfSize:12.0], NSFontAttributeName,
													 darkGrayColor, NSForegroundColorAttributeName,
													 style, NSParagraphStyleAttributeName,
													 nil] autorelease];
		[song.album drawInRect:NSMakeRect(cellFrame.origin.x + 80, cellFrame.origin.y + 41, 240, 18) withAttributes:albumNameDictionary];
		
		// Draw the rating image
		if (song.hasRating)
			[_ratingImage compositeToPoint:NSMakePoint(cellFrame.origin.x + cellFrame.size.width - 20, cellFrame.origin.y + 18)
								operation:NSCompositeSourceOver];
		
		// Draw the bottom cell shadow
		NSRect cellDivider = NSMakeRect(cellFrame.origin.x + 0, cellFrame.origin.y + 60, cellFrame.size.width, 1);
		
		[[NSColor colorWithCalibratedRed:204.0/255.0f green:204.0/255.0f blue:204.0/255.0f alpha:0.05f] set];
		[[NSBezierPath bezierPathWithRect:cellDivider] fill];
		[[NSColor colorWithCalibratedRed:204.0/255.0f green:204.0/255.0f blue:204.0/255.0f alpha:0.25f] set];
		cellDivider.origin.y++;
		[[NSBezierPath bezierPathWithRect:cellDivider] fill];
		[[NSColor colorWithCalibratedRed:204.0/255.0f green:204.0/255.0f blue:204.0/255.0f alpha:0.55f] set];
		cellDivider.origin.y++;
		[[NSBezierPath bezierPathWithRect:cellDivider] fill];
		
		// Draw the bottom cell divider
		[[NSColor colorWithCalibratedRed:170.0/255.0f green:170.0/255.0f blue:170.0/255.0f alpha:1.0f] set];
		cellDivider.origin.y++;
		NSRectFill(cellDivider);
	}
}

@end
