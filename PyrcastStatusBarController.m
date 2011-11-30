//
//  PyrcastMenuController.m
//  Pyrcast
//
//  Created by Alex Winston on 6/24/10.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import "PyrcastStatusBarController.h"


// Notifications
NSString * const SCNetworkReachabilityConnectedNotification = @"SCNetworkReachabilityConnectedNotification";
NSString * const SCNetworkReachabilityDisconnectedNotification = @"SCNetworkReachabilityDisconnectedNotification";

SCNetworkReachabilityRef networkReachabilityRef;

void networkStatusDidChange(SCNetworkReachabilityRef name, SCNetworkConnectionFlags flags, void * infoDictionary) {
	if (name != NULL) {
		if (flags != kSCNetworkFlagsReachable) {
			NSNotificationCenter *center = [NSNotificationCenter defaultCenter];
			[center postNotificationName:SCNetworkReachabilityDisconnectedNotification object:nil];
		} else {
			NSNotificationCenter *center = [NSNotificationCenter defaultCenter];
			[center postNotificationName:SCNetworkReachabilityConnectedNotification object:nil];
		}
	}
}

@implementation PyrcastStatusBarController

static int numberOfShakes = 4;
static float durationOfShake = 0.1f;
static float vigourOfShake = 0.02f;

static int kRatingDislike = 0;
static int kRatingLike = 1;

- (PyrcastStatusBarController *)init {
	if (!(self = [super init]))
		return nil;

	// Initialize the Pandora service
	_pandora = [[[Pandora alloc] init] retain];
	
	return self;
}

-(void)awakeFromNib {
	/* Start the network reachability callback
	networkReachabilityRef = SCNetworkReachabilityCreateWithName(kCFAllocatorDefault, [@"www.pandora.com" cStringUsingEncoding:NSUTF8StringEncoding]);
	
	if (SCNetworkReachabilitySetCallback(networkReachabilityRef, networkStatusDidChange, NULL) &&
		SCNetworkReachabilityScheduleWithRunLoop(networkReachabilityRef, CFRunLoopGetCurrent(), kCFRunLoopDefaultMode)) {
		NSLog(@"SCNetworkReachabilitySetCallback successful");
	}
	*/
	
	// Register the SCNetworkReachability observer callbacks
	NSNotificationCenter *notify = [NSNotificationCenter defaultCenter];
	[notify addObserver:self selector:@selector(networkConnected:) 
				   name:SCNetworkReachabilityConnectedNotification object:nil];
	[notify addObserver:self selector:@selector(networkDisconnected:) 
				   name:SCNetworkReachabilityDisconnectedNotification object:nil];
	
	// Register the HMediaKeys observer callbacks
	[notify addObserver:self selector:@selector(playPause:) 
				   name:MediaKeyPlayPauseUpNotification object:nil];
	[notify addObserver:self selector:@selector(skip:) 
				   name:MediaKeyNextUpNotification object:nil];
	[notify addObserver:self selector:@selector(restart:)
				   name:MediaKeyPreviousUpNotification object:nil];
	
	// Set the Growl application bridge delegate
	[GrowlApplicationBridge setGrowlDelegate:self];
	
	// Center the window or load the autosaved frame
	[_pyrcastWindow center];
	[_pyrcastWindow setFrameAutosaveName:@"PCPyrcastFrameAutosave"];
	//[_pyrcastWindow setDelegate:self];
	
	NSRect loginFrame = [_loginView frame];
	loginFrame.origin.y = 250;
	[_loginView setFrame:loginFrame];
	
	NSRect frame = _pyrcastWindow.frame;
	frame.size.height = 125;
	[_pyrcastWindow setFrame:frame display:YES];
	[_pyrcastView setWantsLayer:YES];
	[_pyrcastView addSubview:_loginView];
	[_playerView setHidden:YES];
	
	// Set the stations button highlight mask
	[[_stationsButton cell] setHighlightsBy:NSNoCellMask]; //NSPushInCellMask];
	
	// Set volume and progress slider delegates
	[_volumeSlider setDelegate:self];
	[_volumeSlider setSliderDownSelector:@selector(volumeSliderDown:)];
	[_volumeSlider setSliderDraggedSelector:@selector(volumeSliderDragged:)];
	[_volumeSlider setSliderUpSelector:@selector(volumeSliderUp:)];
	
	[_progressSlider setDelegate:self];
	[_progressSlider setSliderDownSelector:@selector(progressSliderDown:)];
	[_progressSlider setSliderDraggedSelector:@selector(progressSliderDragged:)];
	
	// Disable the sliders until a QTMovie is created
	[_progressSlider setEnabled:NO];
	[_statusBarDetailsSlider setEnabled:NO];
	
	// Configure the stations search controller
	[_stationsController setDelegate:self];
	[_stationsController setPandoraController:_pandora];

	// Get the user defaults
	NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
	
	// Set the login and password
	if ([userDefaults objectForKey:@"PCPandoraUsername"])
		[_loginUsername setStringValue:[userDefaults objectForKey:@"PCPandoraUsername"]];
	if ([userDefaults dataForKey:@"PCPandoraPassword"])
		[_loginPassword setStringValue:[NSString stringWithUTF8String:[[userDefaults dataForKey:@"PCPandoraPassword"] bytes]]];
	
	// Set the volume slider
	if (![userDefaults objectForKey:@"PCAudioVolume"])
		[userDefaults setObject:[NSString stringWithFormat:@"%f",0.5] forKey:@"PCAudioVolume"];
	[_volumeSlider setFloatValue:[[userDefaults objectForKey:@"PCAudioVolume"] floatValue]];
	
	// Set the menu bar
	[self setMenuBarDisabled:[userDefaults boolForKey:@"PCMenuBarDisabled"]];
}

- (void)dealloc {
	[_pandora release];
	[_pandoraStations release];
	[self destroyStreamer];
	if (_progressUpdateTimer) {
		[_progressUpdateTimer invalidate];
		_progressUpdateTimer = nil;
	}
	if (_statusBar)
		[_statusBar release];
	[super dealloc];
}

#pragma mark -
#pragma mark SCNetworkReachability notification methods

- (void)networkConnected:(id)sender {
	NSLog(@"networkConnected:");
	[self play];
}

- (void)networkDisconnected:(id)sender {
	NSLog(@"networkDisconnected:");
	[self pause];
}

#pragma mark -
#pragma mark NSWindowDelegate methods

- (NSRect)window:(NSWindow *)window willPositionSheet:(NSWindow *)sheet usingRect:(NSRect)rect {
	//NSLog(@"window:willPositionSheet:");
	
	NSRect fieldRect = [_stationsButton frame];
    fieldRect.size.height = 0;
    return fieldRect;
}

#pragma mark -
#pragma mark PyrcastStatusBarController methods

- (void)setMenuBarDisabled:(BOOL)disable {
	//NSLog(@"setMenuBarDisabled:");
	
	if (disable) {
		if (_statusBar) {
			[[NSStatusBar systemStatusBar] removeStatusItem:_statusBar];
			
			[_statusBar release];
			_statusBar = nil;
			
			[_stationsPopUpButton release];
			_stationsPopUpButton = nil;
		}
	} else {
		if (!_statusBar) {
			// Set the menubar items
			NSMenu *menu = [[NSMenu allocWithZone:[NSMenu menuZone]] init];
			[menu setDelegate:self];
			[menu setAutoenablesItems:NO];
			
			// Separator
			[menu addItem:[NSMenuItem separatorItem]];
			
			// Stations
			_stationsMenuItem = [menu addItemWithTitle:@"Stations"
												action:nil
										 keyEquivalent:@""];
			
			_stationsPopUpButton = [[[NSPopUpButton alloc] init] retain];
			[_stationsPopUpButton sizeToFit];
			[_stationsPopUpButton setPullsDown:NO];
			[_stationsPopUpButton setTarget:self];
			[_stationsPopUpButton setAction:@selector(stationItemSelected:)];
			[_stationsMenuItem setSubmenu:[_stationsPopUpButton menu]];
			[_stationsMenuItem setEnabled:NO];
			
			// Separator
			[menu addItem:[NSMenuItem separatorItem]];
			
			// Play/Pause
			_playPauseMenuItem = [menu addItemWithTitle:@"Play/Pause"
												 action:@selector(playPause:)
										  keyEquivalent:@""];
			[_playPauseMenuItem setTarget:self];
			[_playPauseMenuItem setEnabled:NO];
			
			// Skip
			_skipMenuItem = [menu addItemWithTitle:@"Skip"
											action:@selector(skip:)
									 keyEquivalent:@""];
			[_skipMenuItem setTarget:self];
			[_skipMenuItem setEnabled:NO];
			
			// Separator
			[menu addItem:[NSMenuItem separatorItem]];
			
			// Ratings
			_rateUpMenuItem = [menu addItemWithTitle:@"Rate Up"
											  action:@selector(rateUp:)
									   keyEquivalent:@""];
			[_rateUpMenuItem setTarget:self];
			[_rateUpMenuItem setEnabled:NO];
			
			_rateDownMenuItem = [menu addItemWithTitle:@"Rate Down"
												action:@selector(rateDown:)
										 keyEquivalent:@""];
			[_rateDownMenuItem setTarget:self];
			[_rateDownMenuItem setEnabled:NO];
			
			// Separator
			[menu addItem:[NSMenuItem separatorItem]];
			
			// Show
			NSMenuItem *showMenuItem = [menu addItemWithTitle:@"Show Pyrcast"
													   action:@selector(showWindow:)
												keyEquivalent:@""];
			[showMenuItem setTarget:self];
			
			// Separator
			[menu addItem:[NSMenuItem separatorItem]];
			
			// Quit
			NSMenuItem *quitMenuItem = [menu addItemWithTitle:@"Quit Pyrcast"
																 action:@selector(quit:)
														  keyEquivalent:@"q"];
			[quitMenuItem setKeyEquivalentModifierMask:NSCommandKeyMask];
			[quitMenuItem setTarget:self];
			
			// Add NSMenu to StatusItem
			_statusBar = [[[NSStatusBar systemStatusBar] statusItemWithLength:NSVariableStatusItemLength] retain];
			[_statusBar setHighlightMode:YES];
			[_statusBar setImage:[NSImage imageNamed:@"PCMenuBar"]];
			[_statusBar setAlternateImage:[NSImage imageNamed:@"PCMenuBarAlt"]];
			[_statusBar setMenu:menu];
			
			NSMenuItem *statusBarDetailsMenuItem = [[_statusBar menu] insertItemWithTitle:@"" action:nil keyEquivalent:@"" atIndex:0];
			[statusBarDetailsMenuItem setView:_statusBarDetailsView];
			
			[menu release];
			
			// Enable the menu items if authenticated
			if ([_pandora authenticated]) {
				[_stationsMenuItem setEnabled:YES];
				for (NSDictionary *station in _pandoraStations)
					[_stationsPopUpButton addItemWithTitle: [station valueForKey:@"stationName"]];
				[_stationsPopUpButton selectItemAtIndex:_selectedStation];
				
				if (_currentSong) {
					[_playPauseMenuItem setEnabled:YES];
					[_skipMenuItem setEnabled:YES];
					[_rateUpMenuItem setEnabled:YES];
					[_rateDownMenuItem setEnabled:YES];
				}
			}
		}
	}
}

- (void)showWindow:(id)sender {
	[NSApp activateIgnoringOtherApps:YES];
	[_pyrcastWindow makeKeyAndOrderFront:self];
}

- (IBAction)loginButtonClicked:(id)sender {
	[_loginProgressIndicator startAnimation:self];
	
	// Authenticate the user with the Pandora username and password
	[_pandora authenticate:[_loginUsername stringValue] password:[_loginPassword stringValue]];
	
	if ([_pandora authenticated]) {
		// Set the username and password as user defaults
		NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
		[userDefaults setObject:_loginUsername.stringValue forKey:@"PCPandoraUsername"];
		[userDefaults setObject:[_loginPassword.stringValue dataUsingEncoding:NSUTF8StringEncoding] forKey:@"PCPandoraPassword"];
		
		// Load the users Pandora stations
		[self loadStations];
		
		// Install the media keys listener
		if (_mediaKeys == NULL) {
			_mediaKeys = [[[HMediaKeys alloc] init] retain];
			[_mediaKeys listenForKeyEvents:self];
		}

		// Hide login view
		[[_loginView animator] setHidden:YES];
				
		// Resize the window
		NSRect frame = _pyrcastWindow.frame;
		frame.size.height = 367;
		[_pyrcastWindow setFrame:frame display:YES animate:YES];
		[_pyrcastWindow setTitle:@"Pyrcast"];

		// Show player view
		[[_playerView animator] setHidden:NO];
	} else {
		// Shake window if the login failed
		[self loginFailed:_pyrcastWindow];
	}
	
	[_loginProgressIndicator stopAnimation:self];
}

- (void)loginFailed:(NSWindow *)window {
	NSRect frame = [window frame];
	CAKeyframeAnimation *animation = [CAKeyframeAnimation animationWithKeyPath:@"frame"];
	
	NSRect rect1 = NSMakeRect(NSMinX(frame) - frame.size.width * vigourOfShake, NSMinY(frame), frame.size.width, frame.size.height);
	NSRect rect2 = NSMakeRect(NSMinX(frame) + frame.size.width * vigourOfShake, NSMinY(frame), frame.size.width, frame.size.height);
	NSArray *arr = [NSArray arrayWithObjects:[NSValue valueWithRect:rect1], [NSValue valueWithRect:rect2], nil];
	[animation setValues:arr];
	
	[animation setDuration:durationOfShake];
	[animation setRepeatCount:numberOfShakes];
	
	[window setAnimations:[NSDictionary dictionaryWithObject:animation forKey:@"frame"]];
	[[window animator] setFrame:frame display:NO];
}

#pragma mark -
#pragma mark PyrcastStationsController delegate methods

- (void)stationAdded:(NSDictionary *)station {
	//NSLog(@"stationAdded:");
	[_pandoraStations insertObject:station atIndex:0];
	[_stationsTableView reloadData];
	
	if (_statusBar)
		[_stationsPopUpButton insertItemWithTitle:[station valueForKey:@"stationName"] atIndex:0];
	
	_selectedStation = -1;
	[_stationsTableView selectRowIndexes:[NSIndexSet indexSetWithIndex:0]
					byExtendingSelection:NO];
	
	// Start playing the new station
	[self loadStation:0];
}

- (void)stationDeleted:(id)sender {
	//NSLog(@"stationDeleted:");
	if ([_pandoraStations objectAtIndex:_selectedStation]) {
		if ([_pandora deleteStation:[[_pandoraStations objectAtIndex:_selectedStation] valueForKey:@"stationToken"]]) {
			[_pandoraStations removeObjectAtIndex:_selectedStation];
			[_stationsTableView reloadData];
			
			if (_statusBar)
				[_stationsPopUpButton removeItemAtIndex:_selectedStation];
			
			// Unselect the current station
			_selectedStation = -1;
			[_stationsTableView deselectAll:self];
			
			if (_statusBar)
				[_stationsPopUpButton selectItemAtIndex:_selectedStation];
			
			// Add the current song to the history table
			if (_currentSong) {
				// Add the current song to the history view
				[_historyTableController addSong:_currentSong];
				
				// Release the current song
				[_currentSong release];
				_currentSong = nil;
			}
			
			// Reset the player controls
			[self _resetView];
			[self destroyStreamer];
		}
	}
}

#pragma mark -
#pragma mark NSTableView stations delegate methods

- (IBAction)stationsButtonClicked:(id)sender {
	if ([_stationsScrollView isHidden]) {
		[[_stationsScrollView animator] setHidden:NO];
		[[_stationsTableView animator] setHidden:NO];
		[_stationsTableView setEnabled:YES];
	} else {
		[[_stationsScrollView animator] setHidden:YES];
		[[_stationsTableView animator] setHidden:YES];
		[_stationsTableView setEnabled:NO];
	}

}

- (int)numberOfRowsInTableView:(NSTableView *)tableView {
    return [_pandoraStations count];
}

- (id)tableView:(NSTableView *)tableView objectValueForTableColumn:(NSTableColumn *)tableColumn
			row:(int)row
{
    return [[_pandoraStations objectAtIndex:row] valueForKey:@"stationName"];
}

- (BOOL)tableView:(NSTableView *)aTableView shouldEditTableColumn:(NSTableColumn *)aTableColumn
			  row:(int)rowIndex
{
	return NO;
}

- (IBAction)stationTableSelected:(id)sender {
    [self loadStation:[sender selectedRow]];	
}


#pragma mark -
#pragma mark NSButton ratings delegate methods

- (IBAction)rateUpButtonClicked:(id)sender {
	[self rateUp:self];
}

- (void)rateUp:(id)sender {
	if (_currentSong && !_currentSong.hasRating) {
		// Disable the rating controls
		if (_statusBar) {
			[_rateUpMenuItem setEnabled:NO];
			[_rateDownMenuItem setEnabled:NO];
		}
		
		[_rateUpButton setEnabled:NO];
		[_rateDownButton setEnabled:NO];
		[[_rateDownButton animator] setAlphaValue:0.35];
		
		[_pandora feedback:YES forSong:_currentSong.token];
	
		_currentSong.hasRating = YES;
		_currentSong.rating = kRatingLike;
		
		// Send the Growl notification
		NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
		
		if ([userDefaults boolForKey:@"PCGrowlEnabled"])
			[GrowlApplicationBridge notifyWithTitle:[@"Liked - " stringByAppendingString:_currentSong.title]
										description:[_currentSong.artist stringByAppendingFormat:@"\n%@", _currentSong.album]
								   notificationName:@"DefaultNotifications"
										   iconData:[_currentSong.albumCoverImage TIFFRepresentation]
										   priority:0
										   isSticky:NO
									   clickContext:_currentSong.iTunesUrl];
	}
}

- (IBAction)rateDownButtonClicked:(id)sender {
	[self rateDown:self];
}

- (void)rateDown:(id)sender {
	if (_currentSong && !_currentSong.hasRating) {
		// Disable the rating controls
		if (_statusBar) {
			[_rateUpMenuItem setEnabled:NO];
			[_rateDownMenuItem setEnabled:NO];
		}
		
		[_rateDownButton setEnabled:NO];
		[_rateUpButton setEnabled:NO];
		[[_rateUpButton animator] setAlphaValue:0.35];
		
		[_pandora feedback:NO forSong:_currentSong.token];
	
		_currentSong.hasRating = YES;
		_currentSong.rating = kRatingDislike;
		
		// Send the Growl notification
		NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
		
		if ([userDefaults boolForKey:@"PCGrowlEnabled"])
			[GrowlApplicationBridge notifyWithTitle:[@"Disliked - " stringByAppendingString:_currentSong.title]
										description:[_currentSong.artist stringByAppendingFormat:@"\n%@", _currentSong.album]
								   notificationName:@"DefaultNotifications"
										   iconData:[_currentSong.albumCoverImage TIFFRepresentation]
										   priority:0
										   isSticky:NO
									   clickContext:_currentSong.iTunesUrl];
	}
}

#pragma mark -
#pragma mark QTMovie lifecycle methods

- (void)createStreamer:(NSString *)songUrl {
	if (streamer) {
		return;
	}
	
	NSError *error = nil;
	streamer = [[QTMovie movieWithURL:[NSURL URLWithString:songUrl] error:&error] retain];
	if (error) {
		NSLog(@"createStreamer:%@ %@", songUrl, [error description]);
		
		[streamer release];
		streamer = nil;
		
		return;
	}
	[streamer setVolume:[_volumeSlider getFloatValue]];
	
	// Enable the sliders after the song was loaded
	[_progressSlider setEnabled:YES];
	[_statusBarDetailsSlider setEnabled:YES];

	// Reset the progress text fields
	[self _setProgressTextFields:streamer];
	
	_progressUpdateTimer = [NSTimer timerWithTimeInterval:1.0
												   target:self
												 selector:@selector(updateProgress:)
												 userInfo:nil
												  repeats:YES];
	[[NSRunLoop mainRunLoop] addTimer:_progressUpdateTimer forMode:NSRunLoopCommonModes];
}

- (void)destroyStreamer {
	if (streamer) {
		[_progressUpdateTimer invalidate];
		_progressUpdateTimer = nil;
		
		// Disable the sliders when the streamer is destroyed
		[_progressSlider setEnabled:NO];
		[_statusBarDetailsSlider setEnabled:NO];
		
		[streamer stop];
		[streamer release];
		streamer = nil;
	}
}

- (void)updateProgress:(NSTimer *)updatedTimer {
	if (streamer) {
		[self _setProgressTextFields:streamer];
		
		float progress = [streamer currentTime].timeValue;
		float duration = [streamer duration].timeValue;
		
		// Set the progress sliders float value
		[_progressSlider setFloatValue:progress / duration];
		[_statusBarDetailsSlider setFloatValue:100.0 * progress / duration];
		
		// Skip to the next song after the current song ends
		if (progress == duration) {
			[streamer stop];
			[streamer gotoBeginning];
			[self _skip];
		}
	}
}
	 
#pragma mark -
#pragma mark AWSlider delegate methods

- (IBAction)statusBarDetailsSliderChanged:(id)sender {
	if (streamer) {
		QTTime time = [streamer currentTime];
		time.timeValue = [streamer duration].timeValue * _statusBarDetailsSlider.floatValue / 100.0;
		[streamer setCurrentTime:time];
		
		float progress = [streamer currentTime].timeValue;
		float duration = [streamer duration].timeValue;
		
		// Set the progress sliders float value
		[_progressSlider setFloatValue:progress / duration];
		
		[self _setProgressTextFields:streamer];
	}
}

- (void)stationItemSelected:(id)sender {
	[self loadStation:[_stationsPopUpButton indexOfSelectedItem]];
}

- (void)volumeSlideDown:(NSEvent *)event {
	[streamer setVolume:[_volumeSlider getFloatValue]];
}

- (void)progressSliderDown:(NSEvent *)event {
	if (streamer) {
		QTTime time = [streamer currentTime];
		time.timeValue = [streamer duration].timeValue * [_progressSlider getFloatValue];
		[streamer setCurrentTime:time];
		
		[self _setProgressTextFields:streamer];
	}
}

- (void)volumeSliderDragged:(NSEvent *)event {
	[streamer setVolume:[_volumeSlider getFloatValue]];
}

- (void)progressSliderDragged:(NSEvent *)event {
	if (streamer) {
		QTTime time = [streamer currentTime];
		time.timeValue = [streamer duration].timeValue * [_progressSlider getFloatValue];
		[streamer setCurrentTime:time];
		
		[self _setProgressTextFields:streamer];
	}
}

- (void)volumeSliderUp:(NSEvent *)event {
	// Synchronize the volume in the user defaults
	NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
	[userDefaults setObject:[NSString stringWithFormat:@"%f",[_volumeSlider getFloatValue]] forKey:@"PCAudioVolume"];
	[userDefaults synchronize];
}

- (void)loadStations {
	if (_pandoraStations) {
		[_pandoraStations release];
		_pandoraStations = nil;
	}
	_pandoraStations = [[[_pandora stations] mutableCopy] retain];
	
	// Reload the table after the Pandora stations have been loaded
	[_stationsTableView reloadData];
	
	if (_statusBar) {
		for (NSDictionary *station in _pandoraStations)
			[_stationsPopUpButton addItemWithTitle: [station valueForKey:@"stationName"]];
		
		// Enable the stations menu item
		[_stationsMenuItem setEnabled:YES];
	}
}

- (void)loadStation:(int)stationIndex {
	[_stationsButton setState:NSOffState];
	[_stationsTableView setEnabled:NO];
	
	BOOL stationsViewIsHidden = [_stationsScrollView isHidden];
	if (!stationsViewIsHidden) {
		[[_stationsScrollView animator] setHidden:YES];
		[[_stationsTableView animator] setHidden:YES];
	}
	
	if (stationIndex != -1 && _selectedStation != stationIndex) {
		_selectedStation = stationIndex;
		
		[NSAnimationContext beginGrouping];
		if (!stationsViewIsHidden)
			[_stationLoadingIndicator startAnimation:self];
		
		NSString *stationName = [[_pandoraStations objectAtIndex:_selectedStation] valueForKey:@"stationName"];
		
		// Set the menubar tooltip and select station
		if (_statusBar) {
			[_statusBar setToolTip:stationName];
			[_stationsPopUpButton selectItemAtIndex:_selectedStation];
		}
		[_stationsTableView selectRowIndexes:[NSIndexSet indexSetWithIndex:_selectedStation] byExtendingSelection:NO];
		
		// Set the station text field to the station name
		[self _setStationsTextFieldStringValue:stationName];
		[[_stationsTextField animator] setHidden:NO];
		[[_stationDeleteButton animator] setHidden:NO];
		
		// Play a new song
		[self _skip];
		
		if (!stationsViewIsHidden)
			[_stationLoadingIndicator stopAnimation:self];
		[NSAnimationContext endGrouping];
	}
}

- (BOOL)isPlaying {
	return (streamer != nil) && ([streamer rate] != 0);
}

- (IBAction)playButtonClicked:(id)sender {
	[self play];
}

- (void)play {
	[_playButton setHidden:YES];
	[_pauseButton setEnabled:YES];
	[_pauseButton setHidden:NO];
	
	// Play song
	if (streamer) {
		[streamer autoplay];
	}
}

- (IBAction)pauseButtonClicked:(id)sender {
	[self pause];
}

- (void)pause {
	[_playButton setHidden:NO];
	[_playButton setEnabled:YES];
	[_pauseButton setHidden:YES];
	
	// Pause song
	if (streamer) {
		[streamer stop];
		[self updateProgress:nil];
	}
}

- (void)playPause:(id)sender {
	if (streamer) {
		if ([self isPlaying]) {
			[self pause];
		} else {
			[self play];
		}
	}
}

- (IBAction)restartButtonClicked:(id)sender {
	[self restart:self];
}

- (void)restart:(id)sender {
	if (streamer) {
		QTTime time = [streamer currentTime];
		time.timeValue = 0.0;
		[streamer setCurrentTime:time];
		
		[self _setProgressTextFields:streamer];
		
		// Reset the slider values
		[_progressSlider setFloatValue:0.0];
		[_statusBarDetailsSlider setFloatValue:0.0];
	}
}

- (IBAction)skipButtonClicked:(id)sender {
	[self skip:sender];
}

- (void)skip:(id)sender {
	if (_currentSong)
		[self _skip];
}

- (IBAction)infoButtonClicked:(id)sender {
	if (_currentSong)
		[[NSWorkspace sharedWorkspace] openURL:[NSURL URLWithString:_currentSong.iTunesUrl]];
}

- (IBAction)quitMenuItemSelected:(id)sender {
	[self quit:sender];
}

- (void)quit:(id)sender {
	[NSApp terminate:sender];
}

#pragma mark -
#pragma mark GrowlApplicationBridgeDelegate delegate methods

- (void) growlNotificationWasClicked:(id)clickContext {
	if (clickContext)
		[[NSWorkspace sharedWorkspace] openURL:[NSURL URLWithString:clickContext]];
}

#pragma mark -
#pragma mark PyrcastStatusBarController private methods

- (void)_skip {
	// Disable the menubar controls
	if (_statusBar) {
		[_playPauseMenuItem setEnabled:NO];
		[_skipMenuItem setEnabled:NO];
		[_rateUpMenuItem setEnabled:NO];
		[_rateDownMenuItem setEnabled:NO];
	}
	
	// Disable the audio and rating controls
	[_pauseButton setHidden:YES];
	[_playButton setHidden:NO];
	[_playButton setEnabled:NO];
	[_restartButton setEnabled:NO];
	[_skipButton setEnabled:NO];
	[_rateUpButton setEnabled:NO];
	[_rateDownButton setEnabled:NO];
	
	// Hide the history table
	[_historyTableController setHidden:NO];
	
	[self _fadeOutSongDetails];
	
	if (_currentSong) {
		// Add the current song to the history view
		[_historyTableController addSong:_currentSong];
		
		// Release the current song
		[_currentSong release];
		_currentSong = nil;
	}

	// Get the current Pandora station
	NSDictionary *stationDictionary = [_pandoraStations objectAtIndex:_selectedStation];
	
	// Get the next song from the Pandora playlist
	_currentSong = [[_pandora song:stationDictionary] retain];
	if (!_currentSong.token) {
		if (_currentSong) {
			// Release the current song
			[_currentSong release];
			_currentSong = nil;
		}
		
		NSLog(@"skip: reauthenticate");
		
		// Reauthenticate if a song wasn't loaded
		[NSThread sleepForTimeInterval:1.0];
		[_pandora authenticate:[_loginUsername stringValue] password:[_loginPassword stringValue]];
		[self _skip];
		
		return;
	}
	
	// Set the current Pandora station
	[_pandora setCurrentStation:[stationDictionary valueForKey:@"stationToken"]];
	
	// Load the album cover image and create a thumbnail
	NSImage *albumCoverImage = [[NSImage alloc] initWithContentsOfURL:[NSURL URLWithString:_currentSong.albumCoverUrl]];
	[_currentSong setAlbumCoverThumbnailImage:albumCoverImage];
	
	// Set the track details
	[self _setSongTextFieldStringValue:_currentSong.title];
	[self _setArtistTextFieldStringValue:_currentSong.artist];
	[self _setAlbumTextFieldStringValue:_currentSong.album];
	[self _setAlbumCoverImage:albumCoverImage];
	[albumCoverImage release];
	
	[_statusBarDetailsSongTextField setStringValue:_currentSong.title];
	[_statusBarDetailsArtistTextField setStringValue:_currentSong.artist];
	[_statusBarDetailsAlbumTextField setStringValue:_currentSong.album];
	
	[self _fadeInSongDetails];
	
	[self destroyStreamer];
	[self createStreamer:_currentSong.url];
	// NOTE Occassionally the url is invalid, could probably handle this better
	if (!streamer) {
		if (_currentSong) {
			// Release the current song
			[_currentSong release];
			_currentSong = nil;
		}
		
		[self _skip];
		return;
	}
	[streamer autoplay];
	
	// Enable the menubar controls
	if (_statusBar) {
		[_playPauseMenuItem setEnabled:YES];
		[_skipMenuItem setEnabled:YES];
		[_rateUpMenuItem setEnabled:YES];
		[_rateDownMenuItem setEnabled:YES];
	}
	
	// Enable the audio controls
	[_playButton setHidden:YES];
	[_pauseButton setHidden:NO];
	[_pauseButton setEnabled:YES];
	[_restartButton setEnabled:YES];
	[_skipButton setEnabled:YES];
	
	// Enable the info button
	[_infoButton setHidden:NO];
	
	// Enable the ratings
	[_rateUpButton setState:NSOffState];
	[_rateUpButton setAlphaValue:1.0];
	[_rateUpButton setEnabled:YES];
	[_rateDownButton setState:NSOffState];
	[_rateDownButton setAlphaValue:1.0];
	[_rateDownButton setEnabled:YES];
	
	// Enable the progress sliders
	[_progressSlider setHidden:NO];
	[_progressSlider setFloatValue:0.0];
	[_statusBarDetailsSlider setEnabled:YES];
	[_statusBarDetailsSlider setFloatValue:0.0];
	
	// Send the Growl notification
	NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
	
	if ([userDefaults boolForKey:@"PCGrowlEnabled"])
		[GrowlApplicationBridge notifyWithTitle:_currentSong.title
									description:[_currentSong.artist stringByAppendingFormat:@"\n%@", _currentSong.album]
							   notificationName:@"DefaultNotifications"
									   iconData:[_currentSong.albumCoverImage TIFFRepresentation]
									   priority:0
									   isSticky:NO
								   clickContext:_currentSong.iTunesUrl];
}

- (void)_resetView {
	[NSAnimationContext beginGrouping];
	
	// Reset the menu bar items
	if (_statusBar) {
		[_statusBar setToolTip:@""];
		[_statusBarDetailsSongTextField setStringValue:@""];
		[_statusBarDetailsAlbumTextField setStringValue:@""];
		[_statusBarDetailsArtistTextField setStringValue:@""];
		[_statusBarDetailsCurrentTextField setStringValue:@"00:00"];
		[_statusBarDetailsDurationTextField setStringValue:@"00:00"];
		[_statusBarDetailsSlider setEnabled:NO];
		[_statusBarDetailsSlider setFloatValue:0.0];
		
		[_playPauseMenuItem setEnabled:NO];
		[_skipMenuItem setEnabled:NO];
		[_rateUpMenuItem setEnabled:NO];
		[_rateDownMenuItem setEnabled:NO];
	}
	
	// Disable the audio controls
	[_playButton setHidden:NO];
	[_playButton setEnabled:NO];
	[_pauseButton setHidden:YES];
	[_restartButton setEnabled:NO];
	[_skipButton setEnabled:NO];
	[_rateUpButton setEnabled:NO];
	[_rateDownButton setEnabled:NO];
	
	// Reset and disable the rating controls
	[_rateUpButton setState:NSOffState];
	[_rateUpButton setAlphaValue:1.0];
	[_rateUpButton setEnabled:NO];
	[_rateDownButton setState:NSOffState];
	[_rateDownButton setAlphaValue:1.0];
	[_rateDownButton setEnabled:NO];
	
	// Reset and disable the station controls
	[[_stationsTextField animator] setStringValue:@""];
	[[_stationDeleteButton animator] setHidden:YES];
	
	[self _fadeOutSongDetails];
	
	// Reset the progress slider
	[_progressSlider setEnabled:NO];
	[_progressSlider setFloatValue:0.0];
	[_statusBarDetailsSlider setEnabled:NO];
	[_statusBarDetailsSlider setFloatValue:0.0];
	
	[NSAnimationContext endGrouping];
}

- (void)_fadeInSongDetails {
	[[_songTextField animator] setHidden:NO];
	[[_artistTextField animator] setHidden:NO];
	[[_albumTextField animator] setHidden:NO];
	[[_albumCoverImage animator] setHidden:NO];
	[[_infoButton animator] setHidden:NO];
	[[_progressCurrentTextField animator] setHidden:NO];
	[[_progressDurationTextField animator] setHidden:NO];
}

- (void)_fadeOutSongDetails {	
	[[_songTextField animator] setHidden:YES];
	[[_artistTextField animator] setHidden:YES];
	[[_albumTextField animator] setHidden:YES];
	[[_albumCoverImage animator] setHidden:YES];
	[[_infoButton animator] setHidden:YES];
	[[_progressCurrentTextField animator] setHidden:YES];
	[[_progressDurationTextField animator] setHidden:YES];
}


- (void)_setProgressTextFields:(QTMovie *)movie {
	NSArray *currentTimeTokenized = [QTStringFromTime([movie currentTime]) componentsSeparatedByString:@":"];
	NSArray *durationTimeTokenized = [QTStringFromTime([movie duration]) componentsSeparatedByString:@":"];
	
	NSString *currentString = [NSString stringWithFormat:@"%@:%@", [currentTimeTokenized objectAtIndex:2], [[currentTimeTokenized objectAtIndex:3] substringToIndex:2]];
	NSString *durationString = [NSString stringWithFormat:@"%@:%@", [durationTimeTokenized objectAtIndex:2], [[durationTimeTokenized objectAtIndex:3] substringToIndex:2]];
	
	// Set the progress text fields
	[_progressCurrentTextField setStringValue:currentString];
	[_progressDurationTextField setStringValue:durationString];
	
	[_statusBarDetailsCurrentTextField setStringValue:currentString];
	[_statusBarDetailsDurationTextField setStringValue:durationString];
	
	
}

- (void)_setAlbumCoverImage:(NSImage *)image {
	NSImage *thumbnailImage = [[NSImage alloc] initWithSize:NSMakeSize(76, 76)];
	NSRect imageRect = NSMakeRect(0.0, 0.0, [image size].width, [image size].height);
	NSRect thumbnailRect = NSMakeRect(0.0, 0.0, 76, 76);
	
	[thumbnailImage lockFocus];
	[image drawInRect:thumbnailRect fromRect:imageRect operation:NSCompositeCopy fraction:1.0];
	[thumbnailImage unlockFocus];
	[_albumCoverImage setImage:thumbnailImage];
	[thumbnailImage release];
}

- (void)_setStationsTextFieldStringValue:(NSString *)string {
	NSShadow *shadow = [[[NSShadow alloc] init] autorelease];
	[shadow setShadowColor:[NSColor whiteColor]];
	[shadow setShadowOffset:NSMakeSize(0.0, -1.0)];
	[shadow setShadowBlurRadius:1];
	
	[self _setAttributedStringValue:string
					  withTextField:_stationsTextField
							   font:[NSFont boldSystemFontOfSize:11.0]
							 shadow:shadow];
}

- (void)_setSongTextFieldStringValue:(NSString *)string {
	NSShadow *shadow = [[[NSShadow alloc] init] autorelease];
	[shadow setShadowColor:[NSColor blackColor]];
	[shadow setShadowOffset:NSMakeSize(0.0, -1.0)];
	[shadow setShadowBlurRadius:3];
	
	[self _setAttributedStringValue:string
					  withTextField:_songTextField
							   font:[NSFont systemFontOfSize:20.0]
							 shadow:shadow];
}

- (void)_setArtistTextFieldStringValue:(NSString *)string {
	NSShadow *shadow = [[[NSShadow alloc] init] autorelease];
	[shadow setShadowColor:[NSColor blackColor]];
	[shadow setShadowOffset:NSMakeSize(0.0, -1.0)];
	[shadow setShadowBlurRadius:3];
	
	[self _setAttributedStringValue:string
					  withTextField:_artistTextField
							   font:[NSFont systemFontOfSize:14.0]
							 shadow:shadow];
}

- (void)_setAlbumTextFieldStringValue:(NSString *)string {
	NSShadow *shadow = [[[NSShadow alloc] init] autorelease];
	[shadow setShadowColor:[NSColor blackColor]];
	[shadow setShadowOffset:NSMakeSize(0.0, -1.0)];
	[shadow setShadowBlurRadius:3];
	
	[self _setAttributedStringValue:string
					  withTextField:_albumTextField
							   font:[NSFont systemFontOfSize:14.0]
							 shadow:shadow];
}

- (void)_setAttributedStringValue:(NSString *)string withTextField:(NSTextField *)textField font:(NSFont *)font shadow:(NSShadow *)shadow {
	// Set the paragraph style attribute to truncate the tail.
	NSMutableParagraphStyle* style = [[[NSParagraphStyle defaultParagraphStyle] mutableCopy] autorelease];
	[style setLineBreakMode:NSLineBreakByTruncatingTail];
	
	// Create the attributes dictionary
	NSMutableDictionary *stringAttributes = [[[NSMutableDictionary alloc] initWithObjectsAndKeys:
												  font, NSFontAttributeName,
												  shadow, NSShadowAttributeName,
												  style, NSParagraphStyleAttributeName,
												  nil] autorelease];

	// Create a new attributed string with your attributes dictionary attached
	NSAttributedString *attributedString = [[[NSAttributedString alloc] initWithString:string
																			attributes:stringAttributes] autorelease];
	// Set the string value
	[textField setAttributedStringValue:attributedString];
}

@end
