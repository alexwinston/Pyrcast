//
//  Song.m
//  Pyrcast
//
//  Created by Alex Winston on 1/21/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "Song.h"


@implementation Song

@synthesize token;
@synthesize title;
@synthesize artist;
@synthesize album;
@synthesize albumCoverUrl;
@synthesize albumCoverImage;
@synthesize url;
@synthesize iTunesUrl;
@synthesize hasRating;
@synthesize rating;

- (Song *)init {
	if (!(self = [super init]))
		return nil;
	
	// Initialization
	hasRating = NO;
	
	return self;
}

-(id) copyWithZone:(NSZone *)zone {
	Song *songCopy = [[Song allocWithZone: zone] init];
	songCopy.token = token;
	songCopy.title = title;
	songCopy.artist = artist;
	songCopy.album = album;
	songCopy.albumCoverUrl = albumCoverUrl;
	songCopy.url = url;
	songCopy.iTunesUrl = iTunesUrl;
	
	return songCopy;
}

- (void) dealloc {
	[token release];
    [title release];
    [artist release];
	[album release];
	[albumCoverUrl release];
	[albumCoverImage release];
	[url release];
	[iTunesUrl release];
    [super dealloc];
}

- (void)setAlbumCoverThumbnailImage:(NSImage *)image {
	NSImage *thumbnailImage = [[NSImage alloc] initWithSize:NSMakeSize(64, 64)];
	NSRect imageRect = NSMakeRect(0.0, 0.0, [image size].width, [image size].height);
	NSRect thumbnailRect = NSMakeRect(0.0, 0.0, 64, 64);
	
	[thumbnailImage lockFocus];
	[image drawInRect:thumbnailRect fromRect:imageRect operation:NSCompositeCopy fraction:1.0];
	[thumbnailImage unlockFocus];
	[self setAlbumCoverImage:thumbnailImage];
	[thumbnailImage release];
}

@end
