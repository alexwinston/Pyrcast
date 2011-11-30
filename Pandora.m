//
//  Pandora.m
//  Pandora
//
//  Created by Alex Winston on 6/17/10.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import "ASIHTTPRequest.h"
#import "Blowfish.h"
#import "CJSONDeserializer.h"
#import "CJSONSerializer.h"
#import "NSString+URLDencoding.h"
#import "Pandora.h"
#import "Station.h"


@interface Pandora (Private)
@end

@implementation Pandora
@synthesize currentStation;

- (Pandora *)init {
	if (!(self = [super init]))
		return nil;
	
	//const Byte requestKeyBytes[] = "721^26xE22776"; // iPhone
	const Byte requestKeyBytes[] = { 0x36, 0x23, 0x32, 0x36, 0x46, 0x52, 0x4c, 0x24, 0x5a, 0x57, 0x44 }; // Android
	NSData *requestKey = [NSData dataWithBytes:requestKeyBytes length:11];
    blowfishRequest = [[[Blowfish alloc] initWithKey:requestKey offset:0 length:11] retain];
	
	//const Byte responseKeyBytes[] = "20zE1E47BE57$51"; // iPhone
	const Byte responseKeyBytes[] = { 0x52, 0x3d, 0x55, 0x21, 0x4c, 0x48, 0x24, 0x4f, 0x32, 0x42, 0x23 }; // Android
	NSData *responseKey = [NSData dataWithBytes:responseKeyBytes length:11];
	blowfishResponse = [[[Blowfish alloc] initWithKey:responseKey offset:0 length:11] retain];
	
    // Cache of the current songs after requesting a new playlist for the current station
	currentPlaylist = [[NSMutableArray array] retain];
	
	return self;
}

- (void)dealloc {
	[blowfishRequest release];
	[blowfishResponse release];
	[partnerId release];
	[partnerAuthToken release];
	[userId release];
	[userAuthToken release];
	[currentStation release];
	[currentPlaylist release];
	[super dealloc];
}

- (void)debug:(NSString *)aKey withMessage:(NSString *)aString {
	//NSLog(@"%@ %@", aKey, aString);
}

- (long)currentSyncTime {
	long elapsedTimeMillis = [NSDate timeIntervalSinceReferenceDate] - startTime;
	long currentSyncTime = syncTime + (elapsedTimeMillis / 1000);
	
	//return [NSString stringWithFormat:@"%ld", currentSyncTime];
	return currentSyncTime;
}

- (NSString *)pad:(NSString *)aString withSpaces:(int)spaces {
	NSMutableString *padding = [NSMutableString string];
	for (int i = 0; i < spaces; i++)
		[padding appendString:@" "];
	
	return [aString stringByAppendingFormat:@"%@", padding];
}

- (NSString *)encrypt:(NSData *)data {
	NSString *aString = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
	
	int padding = 8 - ([aString length] % 8);
	NSString *paddedString = [self pad:aString withSpaces:padding];
	
	[aString release];
	
	NSString *encryptedString = [blowfishRequest encrypt:paddedString];
	return encryptedString;
}

- (BOOL)authenticated {
	return userAuthenticated;
}

- (void)authenticate:(NSString *)username password:(NSString *)password {
	// TODO NSNotificationCenter
	//PCPandoraAuthenticateDidSucceedNotification, PCPandoraAuthenticateDidFailNotification
	
	// Reset user authentication
	userAuthenticated = false;
	
	// Create the partner login request
	ASIHTTPRequest *partnerRequest = [ASIHTTPRequest requestWithURL:[NSURL URLWithString:@"https://tuner.pandora.com/services/json/?method=auth.partnerLogin"]];
	[partnerRequest setValidatesSecureCertificate:NO];
	[partnerRequest setRequestMethod: @"POST"];

	//NSString *partnerRequestString = @"{\"deviceModel\":\"IP01\",\"username\":\"iphone\",\"includeUrls\":true,\"password\":\"P2E4FC0EAD3*878N92B2CDp34I0B1@388137C\",\"version\":\"5\"}";
	NSString *partnerRequestString = @"{\"deviceModel\":\"android-generic\",\"username\":\"android\",\"includeUrls\":true,\"password\":\"AC7IBG09A3DTSYM4R41UJWL07VLN8JI7\",\"version\":\"5\"}";
	NSData *partnerRequestData = [NSData dataWithBytes:[partnerRequestString UTF8String] length:[partnerRequestString length]];
	[partnerRequest appendPostData: partnerRequestData];
	
	[partnerRequest startSynchronous];
	NSError *partnerRequestError = [partnerRequest error];
	if (partnerRequestError) {
		[self debug:@"partnerRequestError: " withMessage:[partnerRequestError description]];
		return;
	}

	// Deserialize the partner login response
	NSData *partnerResponseData = [partnerRequest responseData];
	NSDictionary *partnerResponseJson = [[CJSONDeserializer deserializer] deserializeAsDictionary:partnerResponseData error:nil];
	[self debug:@"partnerResponseJson: " withMessage:[partnerResponseJson description]];
	
	partnerId = [[partnerResponseJson valueForKeyPath:@"result.partnerId"] retain];
	partnerAuthToken = [[partnerResponseJson valueForKeyPath:@"result.partnerAuthToken"] retain];
	startTime = [NSDate timeIntervalSinceReferenceDate];
	NSString *decryptedSyncTime = [blowfishResponse decrypt:[partnerResponseJson valueForKeyPath:@"result.syncTime"]];
	[self debug:@"decryptedSyncTime: " withMessage:decryptedSyncTime];
	if ([[partnerResponseJson valueForKeyPath:@"stat"] isEqual:@"ok"]) {
		if ([decryptedSyncTime length] < 14) {
			NSLog(@"decryptedSyncTime: %@", decryptedSyncTime);
			return;
		}
	}
		
	syncTime = [[decryptedSyncTime substringFromIndex:4] longLongValue];
	
	// Create the user login request
	NSString *loginRequestString = [NSString stringWithFormat:@"https://tuner.pandora.com/services/json/?partner_id=%@&auth_token=%@&method=auth.userLogin", partnerId, [partnerAuthToken stringByURLEncoding]];
	ASIHTTPRequest *loginRequest = [ASIHTTPRequest requestWithURL:[NSURL URLWithString:loginRequestString]];
	[loginRequest setValidatesSecureCertificate:NO];
	[loginRequest setRequestMethod: @"POST"];
	
	NSMutableDictionary *loginDictionary = [NSMutableDictionary dictionary];
	[loginDictionary setObject:username forKey:@"username"];
	[loginDictionary setObject:partnerAuthToken forKey:@"partnerAuthToken"];
	[loginDictionary setObject:[NSNumber numberWithLong:[self currentSyncTime]] forKey:@"syncTime"];
	[loginDictionary setObject:password forKey:@"password"];
	[loginDictionary setObject:@"user" forKey:@"loginType"];
	[loginDictionary setObject:[NSNumber numberWithBool:YES] forKey:@"includePandoraOneInfo"];
	
	NSString *loginRequestBodyString = [self encrypt:[[CJSONSerializer serializer] serializeObject:loginDictionary error:nil]];
	[self debug:@"loginRequestString: " withMessage:loginRequestString];
	[self debug:@"loginRequestBodyString: " withMessage:loginRequestBodyString];
	NSData *loginRequestBodyData = [NSData dataWithBytes:[loginRequestBodyString UTF8String] length:[loginRequestBodyString length]];
	[loginRequest appendPostData: loginRequestBodyData];
	
	[loginRequest startSynchronous];
	NSError *loginRequestError = [loginRequest error];
	if (loginRequestError)
		[self debug:@"loginRequestError: " withMessage:[loginRequestError description]];
	
	// Deserialize the user login response
	NSData *loginResponseData = [loginRequest responseData];
	NSDictionary *loginResponseJson = [[CJSONDeserializer deserializer] deserializeAsDictionary:loginResponseData error:nil];
	[self debug:@"loginResponseJson: " withMessage:[loginResponseJson description]];
	
	if ([[loginResponseJson valueForKeyPath:@"stat"] isEqual:@"ok"]) {
		userId = [[loginResponseJson valueForKeyPath:@"result.userId"] retain];
		userAuthToken = [[loginResponseJson valueForKeyPath:@"result.userAuthToken"] retain];
		
		// User is logged in
		userAuthenticated = true;
	}
}

- (NSArray *)searchStations:(NSString *)artistName {
	if (!userAuthenticated)
		return [NSArray array];
	
	NSMutableArray *stations = [[[NSMutableArray alloc] init] autorelease];
	if ([artistName length] > 0) {
		// Search for stations with the artist name
		NSString *stationsRequestString = [NSString stringWithFormat:@"http://autocomplete.pandora.com/search?query=%@&auth_token=%@", [artistName stringByURLEncoding], [userAuthToken stringByURLEncoding]];
		ASIHTTPRequest *stationsRequest = [ASIHTTPRequest requestWithURL:[NSURL URLWithString:stationsRequestString]];
		[stationsRequest setRequestMethod: @"GET"];
		[stationsRequest startSynchronous];
		
		NSError *stationsRequestError = [stationsRequest error];
		if (stationsRequestError)
			[self debug:@"searchStationsRequestError: " withMessage:[stationsRequestError description]];
		
		// Deserialize the station list response
		NSString *stationsResponseString = [stationsRequest responseString];
		//NSLog(@"%@", stationsResponseString);
		
		NSArray *stationsArray = [stationsResponseString componentsSeparatedByCharactersInSet: [NSCharacterSet newlineCharacterSet]];
		for (int i = 1; i < [stationsArray count] - 1; i++) {
			NSString *stationString = [stationsArray objectAtIndex:i];
			//NSLog(@"%@", stationString);
			NSArray *stationArray = [stationString componentsSeparatedByString:@"\t"];
			
			Station *station = [[Station alloc] init];
			station.token = [stationArray objectAtIndex:0];
			station.name = [stationArray objectAtIndex:1];
			if ([stationArray count] == 3)
				station.name = [station.name stringByAppendingFormat:@" - %@", [stationArray objectAtIndex:2]];
			
			[stations addObject:station];
			[station release];
			//NSLog(@"%@-%@", station.token, station.name);
		}
	}
	
	return stations;
}

- (NSDictionary *)addStation:(NSString *)musicToken {
	if (!userAuthenticated)
		return nil;
	
	// Create the station add request
	NSString *stationsRequestString = [NSString stringWithFormat:@"http://tuner.pandora.com/services/json/?partner_id=%@&user_id=%@&auth_token=%@&method=station.createStation", partnerId, userId, [userAuthToken stringByURLEncoding]];
	ASIHTTPRequest *stationsRequest = [ASIHTTPRequest requestWithURL:[NSURL URLWithString:stationsRequestString]];
	[stationsRequest setRequestMethod: @"POST"];
	
	NSMutableDictionary *stationsDictionary = [NSMutableDictionary dictionary];
	[stationsDictionary setObject:userAuthToken forKey:@"userAuthToken"];
	[stationsDictionary setObject:[NSNumber numberWithLong:[self currentSyncTime]] forKey:@"syncTime"];
	[stationsDictionary setObject:@"W176H220" forKey:@"stationArtSize"];
	[stationsDictionary setObject:[NSNumber numberWithBool:YES] forKey:@"includeStationArtUrl"];
	[stationsDictionary setObject:musicToken forKey:@"musicToken"];
	NSString *stationsRequestBodyString = [self encrypt:[[CJSONSerializer serializer] serializeObject:stationsDictionary error:nil]];
	NSData *stationsRequestBodyData = [NSData dataWithBytes:[stationsRequestBodyString UTF8String] length:[stationsRequestBodyString length]];
	[stationsRequest appendPostData: stationsRequestBodyData];
	
	[stationsRequest startSynchronous];
	NSError *stationsRequestError = [stationsRequest error];
	if (stationsRequestError)
		[self debug:@"createStationRequestError: " withMessage:[stationsRequestError description]];
	
	// Deserialize the station list response
	NSData *stationsResponseData = [stationsRequest responseData];
	NSDictionary *stationsResponseJson = [[CJSONDeserializer deserializer] deserializeAsDictionary:stationsResponseData error:nil];
	[self debug:@"createStationResponseJson: " withMessage:[stationsResponseJson description]];
	
	if ([[stationsResponseJson valueForKeyPath:@"stat"] isEqual:@"ok"]) {
		NSDictionary *station = [stationsResponseJson valueForKeyPath:@"result"];
		return station;
	}
	
	return nil;
}

- (BOOL)deleteStation:(NSString *)stationToken {
	if (!userAuthenticated)
		return NO;
	
	// Create the station add request
	NSString *stationsRequestString = [NSString stringWithFormat:@"http://tuner.pandora.com/services/json/?partner_id=%@&user_id=%@&auth_token=%@&method=station.deleteStation", partnerId, userId, [userAuthToken stringByURLEncoding]];
	ASIHTTPRequest *stationsRequest = [ASIHTTPRequest requestWithURL:[NSURL URLWithString:stationsRequestString]];
	[stationsRequest setRequestMethod: @"POST"];
	
	NSMutableDictionary *stationsDictionary = [NSMutableDictionary dictionary];
	[stationsDictionary setObject:userAuthToken forKey:@"userAuthToken"];
	[stationsDictionary setObject:[NSNumber numberWithLong:[self currentSyncTime]] forKey:@"syncTime"];
	[stationsDictionary setObject:stationToken forKey:@"stationToken"];
	NSString *stationsRequestBodyString = [self encrypt:[[CJSONSerializer serializer] serializeObject:stationsDictionary error:nil]];
	NSData *stationsRequestBodyData = [NSData dataWithBytes:[stationsRequestBodyString UTF8String] length:[stationsRequestBodyString length]];
	[stationsRequest appendPostData: stationsRequestBodyData];
	
	[stationsRequest startSynchronous];
	NSError *stationsRequestError = [stationsRequest error];
	if (stationsRequestError)
		[self debug:@"deleteStationRequestError: " withMessage:[stationsRequestError description]];
	
	// Deserialize the station list response
	NSData *stationsResponseData = [stationsRequest responseData];
	NSDictionary *stationsResponseJson = [[CJSONDeserializer deserializer] deserializeAsDictionary:stationsResponseData error:nil];
	[self debug:@"deleteStationResponseJson: " withMessage:[stationsResponseJson description]];
	
	if ([[stationsResponseJson valueForKeyPath:@"stat"] isEqual:@"ok"]) {
		return YES;
	}
	
	return NO;
}

- (NSArray *)stations {
	if (!userAuthenticated)
		return [NSArray array];
	
	// Create the station list request
	NSString *stationsRequestString = [NSString stringWithFormat:@"http://tuner.pandora.com/services/json/?partner_id=%@&user_id=%@&auth_token=%@&method=user.getStationList", partnerId, userId, [userAuthToken stringByURLEncoding]];
	ASIHTTPRequest *stationsRequest = [ASIHTTPRequest requestWithURL:[NSURL URLWithString:stationsRequestString]];
	[stationsRequest setRequestMethod: @"POST"];
	
	NSMutableDictionary *stationsDictionary = [NSMutableDictionary dictionary];
	[stationsDictionary setObject:userAuthToken forKey:@"userAuthToken"];
	[stationsDictionary setObject:[NSNumber numberWithLong:[self currentSyncTime]] forKey:@"syncTime"];
	[stationsDictionary setObject:@"W176H220" forKey:@"stationArtSize"];
	[stationsDictionary setObject:[NSNumber numberWithBool:YES] forKey:@"includeStationArtUrl"];
	NSString *stationsRequestBodyString = [self encrypt:[[CJSONSerializer serializer] serializeObject:stationsDictionary error:nil]];
	NSData *stationsRequestBodyData = [NSData dataWithBytes:[stationsRequestBodyString UTF8String] length:[stationsRequestBodyString length]];
	[stationsRequest appendPostData: stationsRequestBodyData];
	
	[stationsRequest startSynchronous];
	NSError *stationsRequestError = [stationsRequest error];
	if (stationsRequestError)
		[self debug:@"stationsRequestError: " withMessage:[stationsRequestError description]];
	
	// Deserialize the station list response
	NSData *stationsResponseData = [stationsRequest responseData];
	NSDictionary *stationsResponseJson = [[CJSONDeserializer deserializer] deserializeAsDictionary:stationsResponseData error:nil];
	[self debug:@"stationsResponseJson: " withMessage:[stationsResponseJson description]];
	
	if ([[stationsResponseJson valueForKeyPath:@"stat"] isEqual:@"ok"]) {
		NSArray *stations = [stationsResponseJson valueForKeyPath:@"result.stations"];
		return stations;
	}
	
	return nil;
}

- (Song *)nextSong:(NSMutableArray *)playlist {
	Song *song = [[[playlist lastObject] copy] autorelease];
	[currentPlaylist removeLastObject];
	return song;
}

- (Song *)song:(NSDictionary *)station {
	NSString *stationToken = [station valueForKey:@"stationToken"];
	
	// Get a song from the playlist if it isn't empty and the station hasn't changed
	if (currentStation && [currentStation isEqualToString:stationToken] && [currentPlaylist count] > 0) {
		return [self nextSong:currentPlaylist];
	}
	
	// Clear the existing playlist
	[currentPlaylist removeAllObjects];
	
	// Create the playlist request
	NSString *playlistRequestString = [NSString stringWithFormat:@"https://tuner.pandora.com/services/json/?partner_id=%@&user_id=%@&auth_token=%@&method=station.getPlaylist", partnerId, userId, [userAuthToken stringByURLEncoding]];
	ASIHTTPRequest *playlistRequest = [ASIHTTPRequest requestWithURL:[NSURL URLWithString:playlistRequestString]];
	[playlistRequest setValidatesSecureCertificate:NO];
	[playlistRequest setRequestMethod: @"POST"];
	
	NSMutableDictionary *playlistDictionary = [NSMutableDictionary dictionary];
	[playlistDictionary setObject:userAuthToken forKey:@"userAuthToken"];
	[playlistDictionary setObject:[NSNumber numberWithLong:[self currentSyncTime]] forKey:@"syncTime"];
	[playlistDictionary setObject:stationToken forKey:@"stationToken"];
	NSString *playlistRequestBodyString = [self encrypt:[[CJSONSerializer serializer] serializeObject:playlistDictionary error:nil]];
	NSData *playlistRequestBodyData = [NSData dataWithBytes:[playlistRequestBodyString UTF8String] length:[playlistRequestBodyString length]];
	[playlistRequest appendPostData: playlistRequestBodyData];
	
	[playlistRequest startSynchronous];
	NSError *playlistRequestError = [playlistRequest error];
	if (playlistRequestError)
		[self debug:@"playlistRequestError: " withMessage:[playlistRequest description]];
	
	// Deserialize the playlist response
	NSData *playlistResponseData = [playlistRequest responseData];
	NSDictionary *playlistResponseJson = [[CJSONDeserializer deserializer] deserializeAsDictionary:playlistResponseData error:nil];
	[self debug:@"playlistResponseJson:" withMessage:[playlistResponseJson description]];
	
	if ([[playlistResponseJson valueForKeyPath:@"stat"] isEqual:@"ok"]) {
		NSArray *items = [playlistResponseJson valueForKeyPath:@"result.items"];
		for (NSDictionary *songDictionary in items) {
			//NSLog(@"songDictionary: %@", [songDictionary description]);
			
			if ([songDictionary valueForKeyPath:@"trackToken"]) {
				Song *song = [[Song alloc] init];
				song.token = [songDictionary valueForKeyPath:@"trackToken"];
				song.title = [songDictionary valueForKeyPath:@"songName"];
				song.artist = [songDictionary valueForKeyPath:@"artistName"];
				song.album = [songDictionary valueForKeyPath:@"albumName"];
				song.albumCoverUrl = [songDictionary valueForKeyPath:@"albumArtUrl"];
				song.url = [[songDictionary valueForKeyPath:@"audioUrlMap.mediumQuality"] valueForKey:@"audioUrl"];
				song.iTunesUrl = [songDictionary valueForKeyPath:@"itunesSongUrl"];
			
				[currentPlaylist addObject:song];
				
				[song release];
			}
		}
		
		return [self nextSong:currentPlaylist];
	}
	
	NSLog(@"TODO fail count and alert");
	
	return nil;
}

- (BOOL)feedback:(BOOL)positive forSong:(NSString *)songId {
	// Create the feedback request
	NSString *feedbackRequestString = [NSString stringWithFormat:@"http://tuner.pandora.com/services/json/?partner_id=%@&user_id=%@&auth_token=%@&method=station.addFeedback", partnerId, userId, [userAuthToken stringByURLEncoding]];
	ASIHTTPRequest *feedbackRequest = [ASIHTTPRequest requestWithURL:[NSURL URLWithString:feedbackRequestString]];
	[feedbackRequest setRequestMethod: @"POST"];
	
	NSMutableDictionary *feedbackDictionary = [NSMutableDictionary dictionary];
	[feedbackDictionary setObject:userAuthToken forKey:@"userAuthToken"];
	[feedbackDictionary setObject:[NSNumber numberWithLong:[self currentSyncTime]] forKey:@"syncTime"];
	[feedbackDictionary setObject:[NSNumber numberWithBool:positive] forKey:@"isPositive"];
	[feedbackDictionary setObject:songId forKey:@"trackToken"];
	NSString *feedbackRequestBodyString = [self encrypt:[[CJSONSerializer serializer] serializeObject:feedbackDictionary error:nil]];
	NSData *feedbackRequestBodyData = [NSData dataWithBytes:[feedbackRequestBodyString UTF8String] length:[feedbackRequestBodyString length]];
	[feedbackRequest appendPostData: feedbackRequestBodyData];
	
	[feedbackRequest startSynchronous];
	NSError *feedbackRequestError = [feedbackRequest error];
	if (feedbackRequestError)
		[self debug:@"feedbackRequestError: " withMessage:[feedbackRequestError description]];
	
	// Deserialize the feedback response
	NSData *feedbackResponseData = [feedbackRequest responseData];
	NSDictionary *feedbackResponseJson = [[CJSONDeserializer deserializer] deserializeAsDictionary:feedbackResponseData error:nil];
	[self debug:@"feedbackResponseJson: " withMessage:[feedbackResponseJson description]];
	
	if ([[feedbackResponseJson valueForKeyPath:@"stat"] isEqual:@"ok"])
		return true;
	
	return false;	
}

@end
