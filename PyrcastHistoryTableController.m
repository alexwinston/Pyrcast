//
//  PyrcastHistoryTableController.m
//  Pyrcast
//
//  Created by Alex Winston on 2/20/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "PyrcastHistoryTableController.h"
#import "HistoryTextFieldCell.h"
#import "Song.h"


@implementation PyrcastHistoryTableController

#pragma mark -
#pragma mark PyrcastHistoryTableController lifecycle methods

- (PyrcastHistoryTableController *)init {
	if (!(self = [super init]))
		return nil;
	
	_historyDatasource = [[NSMutableArray array] retain];
	
	_rateUpImage = [[NSImage imageNamed:@"PCHistoryLike.png"] retain];
	_rateDownImage = [[NSImage imageNamed:@"PCHistoryDislike.png"] retain];
	
	return self;
}

- (void)dealloc {
	[_historyDatasource release];
	[_rateUpImage release];
	[_rateDownImage release];
	[super dealloc];
}

-(void)awakeFromNib {
	// Set the custom history cell
	NSTableColumn* column = [[_historyTableView tableColumns] objectAtIndex:0];
	
	HistoryTextFieldCell *cell = [[[HistoryTextFieldCell alloc] init] autorelease];	
	[column setDataCell:cell];		
}

#pragma mark -
#pragma mark PyrcastHistoryTableController methods

- (void)setHidden:(BOOL)hidden {
	[_historyScrollView setHidden:hidden];
	[_historyTableView setHidden:hidden];
}

- (void)addSong:(Song *)song {
	//NSLog(@"addSong:%@", song.title);
	if ([_historyDatasource count] == 10)
		[_historyDatasource removeLastObject];
	[_historyDatasource insertObject:song atIndex:0];
	[_historyTableView reloadData];
}

#pragma mark -
#pragma mark NSTableView history delegate methods

- (int)numberOfRowsInTableView:(NSTableView *)tableView {
	//NSLog(@"numberOfRowsInTableView:%d", [_historyDatasource count]);
    return [_historyDatasource count];
}

- (id)tableView:(NSTableView *)tableView objectValueForTableColumn:(NSTableColumn *)tableColumn row:(int)row {
	return nil;
}

- (BOOL)tableView:(NSTableView *)aTableView shouldEditTableColumn:(NSTableColumn *)aTableColumn
			  row:(int)rowIndex
{
	return NO;
}

- (void)tableView:(NSTableView *)tableView willDisplayCell:(HistoryTextFieldCell *)cell forTableColumn:(NSTableColumn *)tableColumn
			  row:(int)rowIndex
{
	if ([_historyDatasource objectAtIndex:rowIndex]) {
		Song* song = [_historyDatasource objectAtIndex:rowIndex];
		
		[cell setDelegate:self];
		[cell setRowIndex:rowIndex];
		if (song.hasRating)
			[cell setRatingImage:song.rating ? _rateUpImage : _rateDownImage];
	}
}

#pragma mark -
#pragma mark HistoryTextFieldCell delegate methods

- (id)objectValueForTableRowIndex:(NSNumber *)rowIndex {
	return [_historyDatasource objectAtIndex:[rowIndex intValue]];
}

@end
