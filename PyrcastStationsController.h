//
//  PyrcastStationsController.h
//  Pyrcast
//
//  Created by Alex Winston on 2/22/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import <BWToolkitFramework/BWToolkitFramework.h>
#import <Cocoa/Cocoa.h>

#import "Pandora.h"
#import "Station.h"


@interface PyrcastStationsController : NSObject {	
	IBOutlet BWSheetController *_stationsSheetController;
	IBOutlet NSSearchField *_stationsSearchField;
	IBOutlet NSTableView *_stationsSearchTableView;
	IBOutlet NSProgressIndicator *_stationsSelectProgressIndicators;
	NSMutableArray *_stationsSearchDatasource;
	
	IBOutlet BWSheetController *_stationDeleteSheetController;
	IBOutlet NSProgressIndicator *_stationDeleteProgressIndicators;
	
	id _delegate;
	
	Pandora *_pandora;
}

- (void)setDelegate:(id)delegate;
- (void)setPandoraController:(Pandora *)pandora;
- (IBAction)searchStations:(id)sender;
- (IBAction)stationsTableSelected:(id)sender;
- (IBAction)stationDeleteClicked:(id)sender;

@end
