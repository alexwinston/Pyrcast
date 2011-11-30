//
//  PandoraRadio.h
//  Pandora
//
//  Created by Alex Winston on 6/17/10.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import "Blowfish.h"
#import "Song.h"


@interface Pandora : NSObject {
	Blowfish *blowfishRequest;
	Blowfish *blowfishResponse;
	long startTime;
	long syncTime;
	NSString *partnerId;
	NSString *partnerAuthToken;
	NSString *userId;
	NSString *userAuthToken;
	BOOL userAuthenticated;
	
	NSString *currentStation;
	NSMutableArray *currentPlaylist;
}
@property (retain) NSString *currentStation;
- (BOOL)authenticated;
- (void)authenticate:(NSString *)username password:(NSString *)password;
- (NSArray *)searchStations:(NSString *)artist;
- (NSDictionary *)addStation:(NSString *)musicToken;
- (BOOL)deleteStation:(NSString *)stationToken;
- (NSArray *)stations;
- (Song *)song:(NSDictionary *)station;
- (BOOL)feedback:(BOOL)positive forSong:(NSString *)songId;
@end
