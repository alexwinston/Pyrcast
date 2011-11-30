//
//  PyrcastMenuController.h
//  Pyrcast
//
//  Created by Alex Winston on 6/24/10.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import <BWToolkitFramework/BWToolkitFramework.h>
#import <Carbon/Carbon.h>
#import <Growl/Growl.h>
#import <QuartzCore/CoreAnimation.h>
#import <QTKit/QTKit.h>
#import <SystemConfiguration/SCNetworkReachability.h>

#import "AWSlider.h"
#import "AWImageSlider.h"
#import "HMediaKeys.h"
#import "Pandora.h"
#import "PyrcastHistoryTableController.h"
#import "PyrcastStationsController.h"


extern NSString * const SCNetworkReachabilityConnectedNotification;
extern NSString * const SCNetworkReachabilityDisconnectedNotification;

@interface PyrcastStatusBarController : NSObject<NSWindowDelegate, NSMenuDelegate, GrowlApplicationBridgeDelegate> {
	IBOutlet NSWindow *_pyrcastWindow;
	IBOutlet NSView *_pyrcastView;
	IBOutlet NSView *_playerView;
	
	IBOutlet NSView *_loginView;
	IBOutlet NSProgressIndicator *_loginProgressIndicator;
	IBOutlet NSTextField *_loginUsername;
	IBOutlet NSTextField *_loginPassword;
	
	IBOutlet PyrcastStationsController *_stationsController;
	IBOutlet NSButton *_stationsButton;
	IBOutlet NSButton *_stationDeleteButton;
	IBOutlet NSTextField *_stationsTextField;
	IBOutlet NSProgressIndicator *_stationLoadingIndicator;
	IBOutlet NSButton *_settingsButton;
	
	IBOutlet BWTransparentScrollView *_stationsScrollView;
	IBOutlet BWTransparentTableView *_stationsTableView;
	IBOutlet PyrcastHistoryTableController *_historyTableController;

	IBOutlet NSButton *_playButton;
	IBOutlet NSButton *_pauseButton;
	IBOutlet NSButton *_restartButton;
	IBOutlet NSButton *_skipButton;
	
	IBOutlet NSButton *_rateUpButton;
	IBOutlet NSButton *_rateDownButton;
	
	IBOutlet NSButton *_infoButton;
	
	IBOutlet NSTextField *_songTextField;
	IBOutlet NSTextField *_artistTextField;
	IBOutlet NSTextField *_albumTextField;
	IBOutlet NSImageView *_albumCoverImage;
	
	IBOutlet AWImageSlider *_volumeSlider;
	IBOutlet AWSlider *_progressSlider;
	IBOutlet NSTextField *_progressCurrentTextField;
	IBOutlet NSTextField *_progressDurationTextField;
	NSTimer *_progressUpdateTimer;
	
	IBOutlet NSStatusItem *_statusBar;
	IBOutlet NSView *_statusBarDetailsView;
	IBOutlet NSTextField *_statusBarDetailsSongTextField;
	IBOutlet NSTextField *_statusBarDetailsArtistTextField;
	IBOutlet NSTextField *_statusBarDetailsAlbumTextField;
	IBOutlet BWTransparentSlider *_statusBarDetailsSlider;
	IBOutlet NSTextField *_statusBarDetailsCurrentTextField;
	IBOutlet NSTextField *_statusBarDetailsDurationTextField;
	
	NSMenuItem *_stationsMenuItem;
	NSPopUpButton *_stationsPopUpButton;
	NSMenuItem *_playPauseMenuItem;
	NSMenuItem *_skipMenuItem;
	NSMenuItem *_rateUpMenuItem;
	NSMenuItem *_rateDownMenuItem;
	
	HMediaKeys *_mediaKeys;
	
	Pandora *_pandora;
	NSMutableArray *_pandoraStations;
	int _selectedStation;
	Song *_currentSong;
	
	QTMovie *streamer;
}
- (IBAction)loginButtonClicked:(id)sender;
- (IBAction)stationsButtonClicked:(id)sender;
- (IBAction)stationTableSelected:(id)sender;
- (IBAction)playButtonClicked:(id)sender;
- (IBAction)pauseButtonClicked:(id)sender;
- (IBAction)restartButtonClicked:(id)sender;
- (IBAction)skipButtonClicked:(id)sender;
- (IBAction)infoButtonClicked:(id)sender;
- (IBAction)rateUpButtonClicked:(id)sender;
- (IBAction)rateDownButtonClicked:(id)sender;
- (IBAction)quitMenuItemSelected:(id)sender;
- (IBAction)statusBarDetailsSliderChanged:(id)sender;

- (void)loginFailed:(NSWindow *)window;
- (void)loadStations;
- (void)loadStation:(int)stationIndex;
- (void)createStreamer:(NSString *)songUrl;
- (void)destroyStreamer;

- (void)setMenuBarDisabled:(BOOL)isDisabled;

- (BOOL)isPlaying;
- (void)play;
- (void)pause;
- (void)playPause:(id)sender;
- (void)restart:(id)sender;
- (void)skip:(id)sender;
- (void)rateUp:(id)sender;
- (void)rateDown:(id)sender;
- (void)quit:(id)sender;

- (void)_skip;
- (void)_resetView;

- (void)_fadeInSongDetails;
- (void)_fadeOutSongDetails;

- (void)_setProgressTextFields:(QTMovie *)movie;

- (void)_setAttributedStringValue:(NSString *)string withTextField:(NSTextField *)textField font:(NSFont *)font shadow:(NSShadow *)shadow;
- (void)_setStationsTextFieldStringValue:(NSString *)string;
- (void)_setSongTextFieldStringValue:(NSString *)string;
- (void)_setArtistTextFieldStringValue:(NSString *)string;
- (void)_setAlbumTextFieldStringValue:(NSString *)string;
- (void)_setAlbumCoverImage:(NSImage *)image;
@end
