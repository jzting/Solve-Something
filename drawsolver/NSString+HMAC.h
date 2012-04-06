//
//  NSString+HMAC.h
//  Solve Something
//
//  Created by Jason Ting on 4/1/12.
//  Copyright (c) 2012 jzlabs. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface NSString(HMAC)

- (NSString*) HMACWithSecret:(NSString*) secret;

@end