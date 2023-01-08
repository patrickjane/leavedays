//************************************************************
// YearSummary.m
// Holliday
//************************************************************
// Created by Patrick Fial on 06.01.12.
// Copyright 2012-2014 Patrick Fial. All rights reserved.
//************************************************************

//************************************************************
// includes
//************************************************************

#import "YearSummary.h"

//************************************************************
// class YearSummary
//************************************************************

@implementation YearSummary

@synthesize amount_remain, amount_remain_with_pools, amount_spent;
@synthesize amount_spent_with_pools, amount_with_pools,days_per_year;
@synthesize remain_expiration, userid, year, userInfo;
@synthesize pools, uuid;

#pragma mark - NSCoding

//************************************************************
// contentsForType
//************************************************************

- (void)encodeWithCoder:(NSCoder *)coder
{
   [coder encodeInt:1 forKey:@"VERSION"];
   
   [coder encodeObject:self.amount_remain forKey:@"amount_remain"];
   [coder encodeObject:self.amount_remain_with_pools forKey:@"amount_remain_with_pools"];
   [coder encodeObject:self.amount_spent forKey:@"amount_spent"];
   [coder encodeObject:self.amount_spent_with_pools forKey:@"amount_spent_with_pools"];
   [coder encodeObject:self.amount_with_pools forKey:@"amount_with_pools"];
   [coder encodeObject:self.days_per_year forKey:@"days_per_year"];
   [coder encodeObject:self.year forKey:@"year"];
   [coder encodeObject:self.remain_expiration forKey:@"remain_expiration"];
   [coder encodeObject:self.userid forKey:@"userid"];
   [coder encodeObject:self.userInfo forKey:@"userInfo"];
   [coder encodeObject:self.pools forKey:@"pools"];
   [coder encodeObject:self.uuid forKey:@"uuid"];
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
         self.amount_remain= [coder decodeObjectForKey:@"amount_remain"];
         self.amount_remain_with_pools= [coder decodeObjectForKey:@"amount_remain_with_pools"];
         self.amount_spent= [coder decodeObjectForKey:@"amount_spent"];
         self.amount_spent_with_pools= [coder decodeObjectForKey:@"amount_spent_with_pools"];
         self.amount_with_pools= [coder decodeObjectForKey:@"amount_with_pools"];
         self.days_per_year= [coder decodeObjectForKey:@"days_per_year"];
         self.year= [coder decodeObjectForKey:@"year"];
         self.remain_expiration= [coder decodeObjectForKey:@"remain_expiration"];
         self.userid= [coder decodeObjectForKey:@"userid"];
         self.userInfo= [coder decodeObjectForKey:@"userInfo"];
         self.pools= [[[coder decodeObjectForKey:@"pools"] mutableCopy] autorelease];
         self.uuid= [coder decodeObjectForKey:@"uuid"];
      }
   }
   
   return self;
}

@end
