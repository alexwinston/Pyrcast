//
//  NSData+Hex.m
//  Pandora
//
//  Created by Alex Winston on 6/15/10.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import "NSData+Hex.h"


static int asciitable[128] = {
    99,99,99,99, 99,99,99,99, 99,99,99,99, 99,99,99,99,
    99,99,99,99, 99,99,99,99, 99,99,99,99, 99,99,99,99,
    99,99,99,99, 99,99,99,99, 99,99,99,99, 99,99,99,99,
    0, 1, 2, 3,   4, 5, 6, 7,  8, 9,99,99, 99,99,99,99, // 0..9
    99,10,11,12, 13,14,15,99, 99,99,99,99, 99,99,99,99, // A..F
    99,99,99,99, 99,99,99,99, 99,99,99,99, 99,99,99,99,
    99,10,11,12, 13,14,15,99, 99,99,99,99, 99,99,99,99, // a..f
    99,99,99,99, 99,99,99,99, 99,99,99,99, 99,99,99,99
};

@implementation NSData (Hex)

- (NSString*)stringWithHexBytes
{
	static const char hexdigits[] = "0123456789abcdef";
	const size_t numBytes = [self length];
	const unsigned char* bytes = [self bytes];
	char *strbuf = (char *)malloc(numBytes * 2 + 1);
	char *hex = strbuf;
	NSString *hexBytes = nil;
	
	for (int i = 0; i<numBytes; ++i) {
		const unsigned char c = *bytes++;
		*hex++ = hexdigits[(c >> 4) & 0xF];
		*hex++ = hexdigits[(c ) & 0xF];
	}
	*hex = 0;
	hexBytes = [NSString stringWithUTF8String:strbuf];
	free(strbuf);
	return hexBytes;
}

- (NSData *)dataWithHexString {
    // Based on Erik Doernenburg's NSData+MIME.m
    const char *source, *endOfSource;
    NSMutableData *decodedData;
    char *dest;
    
    source = [self bytes];
    endOfSource = source + [self length];
    decodedData = [NSMutableData dataWithLength:[self length]];
    dest = [decodedData mutableBytes];
	
    while (source < endOfSource) {
        if (isxdigit(*source) && isxdigit(*(source+1))) {
            *dest++ = asciitable[(int)*source] * 16 + asciitable[(int)*(source+1)];
            source += 2;     
        } else
            return nil;
    }
    
    [decodedData setLength:(unsigned int)((void *)dest - [decodedData mutableBytes])];
    
    return decodedData;
}

@end
