//
//  HMediaKeys.h
//  SweetFM
//
//  Created by Q on 31.05.09.
//
//
//  Permission is hereby granted, free of charge, to any person 
//  obtaining a copy of this software and associated documentation
//  files (the "Software"), to deal in the Software without restriction,
//  including without limitation the rights to use, copy, modify, 
//  merge, publish, distribute, sublicense, and/or sell copies of 
//  the Software, and to permit persons to whom the Software is 
//  furnished to do so, subject to the following conditions:
//
//  The above copyright notice and this permission notice shall be 
//  included in all copies or substantial portions of the Software.
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, 
//  EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES 
//  OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.
//  IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR 
//  ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF 
//  CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION
//  WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.

#import <Cocoa/Cocoa.h>


//
// Media key constants
//
typedef enum {	
	PlayPauseKeyDown = 0x100A00,		// … 1 0000 0000 1010 0000 0000 
	PlayPauseKeyUp = 0x100B00,			// … 1 0000 0000 1011 0000 0000
	NextKeyDown = 0x130A00,				// … 1 0011 0000 1010 0000 0000
	NextKeyUp =	0x130B00,				// … 1 0011 0000 1011 0000 0000
	PreviousKeyDown =	0x140A00,		// … 1 0100	0000 1010 0000 0000
	PreviousKeyUp =	0x140B00			// … 1 0100 0000 1011 0000 0000
} MediaKeys;

#define MediaKeyPlayPauseMask (PlayPauseKeyDown | PlayPauseKeyUp)
#define MediaKeyNextMask (NextKeyDown | NextKeyUp)
#define MediaKeyPreviousMask (PreviousKeyDown | PreviousKeyUp)
#define MediaKeyMask (MediaKeyPlayPauseMask | MediaKeyNextMask | MediaKeyPreviousMask)

//
// Notifications
//
extern NSString * const MediaKeyPlayPauseUpNotification;
extern NSString * const MediaKeyNextUpNotification;
extern NSString * const MediaKeyPreviousUpNotification;

@interface HMediaKeys : NSObject {
}
- (void)listenForKeyEvents:(id)sender;
@end
