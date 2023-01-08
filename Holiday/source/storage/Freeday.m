//************************************************************
// Freeday.m
// Holliday
//************************************************************
// Created by Patrick Fial on 28.11.20.
// Copyright 2020-2020 Patrick Fial. All rights reserved.
//************************************************************

//************************************************************
// includes
//************************************************************

#import "Freeday.h"

@implementation Freeday
@synthesize userid, uuid, title, month, day, userInfo;

#pragma mark - NSCoding

//************************************************************
// contentsForType
//************************************************************

- (void)encodeWithCoder:(NSCoder *)coder
{
   [coder encodeInt:1 forKey:@"VERSION"];
   
   [coder encodeObject:self.day forKey:@"day"];
   [coder encodeObject:self.month forKey:@"month"];
   [coder encodeObject:self.userid forKey:@"userid"];
   [coder encodeObject:self.uuid forKey:@"uuid"];
   [coder encodeObject:self.title forKey:@"title"];
   [coder encodeObject:self.userInfo forKey:@"userInfo"];
}

#pragma mark - Load

//************************************************************
// loadFromContents
//************************************************************

- (id)initWithCoder:(NSCoder*)coder
{
   self= [super init];
   
   if (self)
   {
      int version= [coder decodeIntForKey:@"VERSION"];
      
      if (version >= 1)
      {
         self.month= [coder decodeObjectForKey:@"month"];
         self.day= [coder decodeObjectForKey:@"day"];
         self.title= [coder decodeObjectForKey:@"title"];
         self.uuid= [coder decodeObjectForKey:@"uuid"];
         self.userid= [coder decodeObjectForKey:@"userid"];
         self.userInfo= [coder decodeObjectForKey:@"userInfo"];
      }
   }
   
   return self;
}
@end
