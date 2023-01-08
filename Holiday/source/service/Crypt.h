//************************************************************
// crypt.h
// Holliday
//************************************************************
// Created by Patrick Fial on 23.12.13.
// Copyright 2013-2013 Patrick Fial. All rights reserved.
//************************************************************

//************************************************************
// includes
//************************************************************

#import <Foundation/Foundation.h>

//************************************************************
// class NSString
//************************************************************

@interface NSString(Hashes)
+ (NSString*)hashedSha2:(NSString*)input;
-(NSString*)hashedSha2;
@end

//************************************************************
// class NSData
//************************************************************

@interface NSData(Base64)
+ (NSData*)dataFromBase64String:(NSString*)aString;
- (NSString*)base64EncodedString;
@end

