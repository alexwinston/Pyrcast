//
//  Song.h
//  Pyrcast
//
//  Created by Alex Winston on 1/21/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>


@interface Song : NSObject <NSCopying> {
	NSString *token;
	NSString *title;
	NSString *artist;
	NSString *album;
	NSString *albumCoverUrl;
	NSImage *albumCoverImage;
	NSString *url;
	NSString *iTunesUrl;
	BOOL hasRating;
	int rating;
}
@property (retain) NSString *token;
@property (retain) NSString *title;
@property (retain) NSString *artist;
@property (retain) NSString *album;
@property (retain) NSString *albumCoverUrl;
@property (retain) NSImage *albumCoverImage;
@property (retain) NSString *url;
@property (retain) NSString *iTunesUrl;
@property (readwrite,assign) BOOL hasRating;
@property (readwrite,assign) int rating;
- (void)setAlbumCoverThumbnailImage:(NSImage *)image;
@end
