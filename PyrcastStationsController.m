//
//  PyrcastStationsController.m
//  Pyrcast
//
//  Created by Alex Winston on 2/22/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "PyrcastStationsController.h"


@implementation PyrcastStationsController

#pragma mark -
#pragma mark PyrcastStationsController lifecycle methods

- (PyrcastStationsController *)init {
	if (!(self = [super init]))
		return nil;
	
	_stationsSearchDatasource = [[NSArray array] retain];

	return self;
}

-(void)awakeFromNib {
}

- (void)dealloc {
	[_delegate release];
	[_pandora release];
	[super dealloc];
}

#pragma mark -
#pragma mark PyrcastStationsController property methods

- (void)setDelegate:(id)delegate {
	_delegate = [delegate retain];
}

- (void)setPandoraController:(Pandora *)pandora {
	_pandora = [pandora retain];
}

#pragma mark -
#pragma mark NSWindow station add delegate methods

- (IBAction)searchStations:(id)sender {
	NSMutableString *searchText = [NSMutableString stringWithString:[_stationsSearchField stringValue]];
	
	if (_stationsSearchDatasource)
		[_stationsSearchDatasource release];
	_stationsSearchDatasource = [[_pandora searchStations:searchText] retain];
	
	[_stationsSearchTableView reloadData];
}

- (int)numberOfRowsInTableView:(NSTableView *)tableView {
	return [_stationsSearchDatasource count];
}

- (id)tableView:(NSTableView *)tableView objectValueForTableColumn:(NSTableColumn *)tableColumn
			row:(int)row
{
	Station *station = [_stationsSearchDatasource objectAtIndex:row];
    return station.name;
}

- (BOOL)tableView:(NSTableView *)aTableView shouldEditTableColumn:(NSTableColumn *)aTableColumn
			  row:(int)rowIndex
{
	return NO;
}

- (IBAction)stationsTableSelected:(id)sender {
	[_stationsSelectProgressIndicators startAnimation:self];
	
	int selectedStationRow = [sender selectedRow];
	if (selectedStationRow != -1) {
		if ([_stationsSearchDatasource objectAtIndex:selectedStationRow]) {
			Station *selectedStation = [_stationsSearchDatasource objectAtIndex:selectedStationRow];
			
			NSDictionary *stationDictionary = [_pandora addStation:selectedStation.token];
			if(_delegate && [_delegate respondsToSelector:@selector(stationAdded:)])
				[_delegate performSelector:@selector(stationAdded:) withObject:stationDictionary];
		}
	}
	[_stationsSelectProgressIndicators stopAnimation:self];
	
	[_stationsSheetController closeSheet:self];
	[_stationsSearchField setStringValue:@""];
	[_stationsSearchDatasource removeAllObjects];
	[_stationsSearchTableView reloadData];
}

#pragma mark -
#pragma mark NSWindow station delete delegate methods

- (IBAction)stationDeleteClicked:(id)sender {
	[_stationDeleteProgressIndicators startAnimation:self];
	// TODO Delete the station
	[NSThread sleepForTimeInterval:1.0];
	
	if(_delegate && [_delegate respondsToSelector:@selector(stationDeleted:)])
		[_delegate performSelector:@selector(stationDeleted:) withObject:self];
	
	[_stationDeleteProgressIndicators stopAnimation:self];
	
	[_stationDeleteSheetController closeSheet:self];
}

@end
