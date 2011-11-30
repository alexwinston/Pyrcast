//
//  PyrcastHistoryTableController.h
//  Pyrcast
//
//  Created by Alex Winston on 2/20/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>


@interface PyrcastHistoryTableController : NSObject {
	IBOutlet NSScrollView *_historyScrollView;
	IBOutlet NSTableView *_historyTableView;
	NSMutableArray *_historyDatasource;
	
	NSImage *_rateUpImage;
	NSImage *_rateDownImage;
}
- (void)setHidden:(BOOL)hidden;
- (void)addSong:(id)object;
@end
