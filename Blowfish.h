//
//  Blowfish.h
//  Pandora
//
//  Created by Alex Winston on 6/15/10.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>


#define kBlockSize 8
#define kPboxEntriesLength 18
#define kSboxEntriesLength 256


@interface Blowfish : NSObject {
	int pbox[kPboxEntriesLength];
	int sbox1[kSboxEntriesLength];
	int sbox2[kSboxEntriesLength];
	int sbox3[kSboxEntriesLength];
	int sbox4[kSboxEntriesLength];
	int blockBuf[kBlockSize];
}
- (Blowfish *)initWithKey:(NSData *)key offset:(int)offset length:(int)length;
- (NSString *)encrypt:(NSString *)string;
- (NSString *)decrypt:(NSString *)encryptedHexString;
- (int)encrypt:(Byte[])inbuf inpos:(int)inpos outbuf:(Byte[])outbuf outpos:(int)outpos len:(int)len;
- (int)decrypt:(Byte[])inbuf inpos:(int)inpos outbuf:(Byte[])outbuf outpos:(int)outpos len:(int)len;
@end
