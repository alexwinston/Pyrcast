//
//  NSData+Hex.h
//  Pandora
//
//  Created by Alex Winston on 6/15/10.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>


@interface NSData (Hex)
- (NSString *)stringWithHexBytes;
- (NSData *)dataWithHexString;
@end
