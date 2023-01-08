//************************************************************
// Timetable.m
// Holliday
//************************************************************
// Created by Patrick Fial on 06.01.12.
// Copyright 2012-2014 Patrick Fial. All rights reserved.
//************************************************************

//************************************************************
// includes
//************************************************************

#import "Timetable.h"

//************************************************************
// class Timetable
//************************************************************

@implementation Timetable

@synthesize day_0;
@synthesize day_1;
@synthesize day_2;
@synthesize day_3;
@synthesize day_4;
@synthesize day_5;
@synthesize day_6;
@synthesize hours_total;
@synthesize internalname;
@synthesize name;
@synthesize uuid;
@synthesize userid;
@synthesize userInfo;

#pragma mark - NSCoding

//************************************************************
// contentsForType
//************************************************************

- (void)encodeWithCoder:(NSCoder *)coder
{
   [coder encodeInt:1 forKey:@"VERSION"];
   
   [coder encodeObject:self.day_0 forKey:@"day_0"];
   [coder encodeObject:self.day_1 forKey:@"day_1"];
   [coder encodeObject:self.day_2 forKey:@"day_2"];
   [coder encodeObject:self.day_3 forKey:@"day_3"];
   [coder encodeObject:self.day_4 forKey:@"day_4"];
   [coder encodeObject:self.day_5 forKey:@"day_5"];
   [coder encodeObject:self.day_6 forKey:@"day_6"];
   [coder encodeObject:self.hours_total forKey:@"hours_total"];
   [coder encodeObject:self.internalname forKey:@"internalname"];
   [coder encodeObject:self.name forKey:@"name"];
   [coder encodeObject:self.uuid forKey:@"uuid"];
   [coder encodeObject:self.userid forKey:@"userid"];
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
         self.day_0= [coder decodeObjectForKey:@"day_0"];
         self.day_1= [coder decodeObjectForKey:@"day_1"];
         self.day_2= [coder decodeObjectForKey:@"day_2"];
         self.day_3= [coder decodeObjectForKey:@"day_3"];
         self.day_4= [coder decodeObjectForKey:@"day_4"];
         self.day_5= [coder decodeObjectForKey:@"day_5"];
         self.day_6= [coder decodeObjectForKey:@"day_6"];
         self.hours_total= [coder decodeObjectForKey:@"hours_total"];
         self.internalname= [coder decodeObjectForKey:@"internalname"];
         self.name= [coder decodeObjectForKey:@"name"];
         self.uuid= [coder decodeObjectForKey:@"uuid"];
         self.userid= [coder decodeObjectForKey:@"userid"];
         self.userInfo= [coder decodeObjectForKey:@"userInfo"];
      }
   }
   
   return self;
}
@end
