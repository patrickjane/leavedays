//************************************************************
// Pool.m
// Holliday
//************************************************************
// Created by Patrick Fial on 06.01.12.
// Copyright 2012-2014 Patrick Fial. All rights reserved.
//************************************************************

//************************************************************
// includes
//************************************************************

#import "Pool.h"
#import "Service.h"
#import "Settings.h"

//************************************************************
// class Pool
//************************************************************

@implementation Pool

@synthesize category;
@synthesize expired;
@synthesize internalName;
@synthesize pool;
@synthesize remain;
@synthesize spent;
@synthesize year;
@synthesize yearId;
@synthesize uuid;
@synthesize userid;
@synthesize earned;

#pragma mark - Functions

//************************************************************
// check expiration
//************************************************************

-(BOOL) checkExpiration 
{
   NSDate* expirationDate= [Service getExpirationForYear:[self.year intValue]];
   
   // check if reached or exceeded expiration date
   
   NSComparisonResult res = [[Service trunc:[NSDate date]] compare:[Service trunc:expirationDate]];
   
   bool isExpiredDate= res == NSOrderedDescending || res == NSOrderedSame;
   
   double amoutAvail = [self.pool doubleValue];                                  // 5    5
   double amountSpent = [self.spent doubleValue];                                // 3    0
   double amountRemain = [self.remain doubleValue];                              // 2    5

   // already used all leave days from previous year? -> no expiration
   
   if (self.expired.doubleValue > 0.0 && [Settings userSettingBool:skLeaveExpires])
      return YES;
   
   if (!isExpiredDate || !amoutAvail || ![Settings userSettingBool:skLeaveExpires])
   {
      self.remain= [NSNumber numberWithDouble:amoutAvail - amountSpent];
      self.expired= [NSNumber numberWithDouble:0.0];
      
      return NO;
   }
   
   self.expired= [NSNumber numberWithDouble:amountRemain];
   self.remain= [NSNumber numberWithDouble:0.0];
   
   return YES;
}

#pragma mark - NSCoding

//************************************************************
// encodeWithCoder
//************************************************************

- (void)encodeWithCoder:(NSCoder *)coder
{
   [coder encodeInt:2 forKey:@"VERSION"];

   [coder encodeObject:self.category forKey:@"category"];
   [coder encodeObject:self.expired forKey:@"expired"];
   [coder encodeObject:self.internalName forKey:@"internalName"];
   [coder encodeObject:self.pool forKey:@"pool"];
   [coder encodeObject:self.remain forKey:@"remain"];
   [coder encodeObject:self.spent forKey:@"spent"];
   [coder encodeObject:self.year forKey:@"year"];
   [coder encodeObject:self.yearId forKey:@"yearId"];
   [coder encodeObject:self.uuid forKey:@"uuid"];
   [coder encodeObject:self.earned forKey:@"earned"];
}

//************************************************************
// initWithCoder
//************************************************************

- (id)initWithCoder:(NSCoder *)coder
{
   self= [super init];
   
   if (self)
   {
      self.__version= [coder decodeIntForKey:@"VERSION"];

      if (self.__version >= 0)
      {
         [self setCategory:[coder decodeObjectForKey:@"category"]];
         [self setExpired:[coder decodeObjectForKey:@"expired"]];
         [self setInternalName:[coder decodeObjectForKey:@"internalName"]];
         [self setPool:[coder decodeObjectForKey:@"pool"]];
         [self setRemain:[coder decodeObjectForKey:@"remain"]];
         [self setSpent:[coder decodeObjectForKey:@"spent"]];
         [self setYear:[coder decodeObjectForKey:@"year"]];
         [self setYearId:[coder decodeObjectForKey:@"yearId"]];
         [self setUuid:[coder decodeObjectForKey:@"uuid"]];
      }
      
      if (self.__version >= 2)
      {
         [self setEarned:[coder decodeObjectForKey:@"earned"]];
      }
      else
      {
         [self setEarned:[NSNumber numberWithInt:0]];
      }
   }
   
   return self;
}

@end
