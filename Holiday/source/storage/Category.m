//************************************************************
// Category.m
// Holliday
//************************************************************
// Created by Patrick Fial on 06.01.12.
// Copyright 2012-2013 Patrick Fial. All rights reserved.
//************************************************************

//************************************************************
// includes
//************************************************************

#import "Category.h"

//************************************************************
// class Category
//************************************************************

@implementation CategoryRef

@synthesize affectCalculation;
@synthesize color;
@synthesize deletable;
@synthesize inssp;
@synthesize internalName;
@synthesize name;
@synthesize savedAsHours;
@synthesize sumMonthly;
@synthesize userInfo;
@synthesize userid;
@synthesize __version;

#pragma mark - NSCoding

//************************************************************
// contentsForType
//************************************************************

- (void)encodeWithCoder:(NSCoder *)coder
{
   [coder encodeInt:2 forKey:@"VERSION"];
   
   [coder encodeObject:self.affectCalculation forKey:@"affectCalculation"];
   [coder encodeObject:self.color forKey:@"color"];
   [coder encodeObject:self.deletable forKey:@"deletable"];
   [coder encodeObject:self.inssp forKey:@"inssp"];
   [coder encodeObject:self.internalName forKey:@"internalName"];
   [coder encodeObject:self.name forKey:@"name"];
   [coder encodeObject:self.savedAsHours forKey:@"savedAsHours"];
   [coder encodeObject:self.sumMonthly forKey:@"sumMonthly"];
   [coder encodeObject:self.userInfo forKey:@"userInfo"];
   [coder encodeObject:self.userid forKey:@"userid"];
   [coder encodeObject:self.honorFreeDays forKey:@"honorFreeDays"];
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
      self.__version= [coder decodeIntForKey:@"VERSION"];
      
      if (self.__version >= 1)
      {
         self.affectCalculation= [coder decodeObjectForKey:@"affectCalculation"];
         self.color= [coder decodeObjectForKey:@"color"];
         self.deletable= [coder decodeObjectForKey:@"deletable"];
         self.inssp= [coder decodeObjectForKey:@"inssp"];
         self.internalName= [coder decodeObjectForKey:@"internalName"];
         self.name= [coder decodeObjectForKey:@"name"];
         self.savedAsHours= [coder decodeObjectForKey:@"savedAsHours"];
         self.sumMonthly= [coder decodeObjectForKey:@"sumMonthly"];
         self.userInfo= [coder decodeObjectForKey:@"userInfo"];
         self.userid= [coder decodeObjectForKey:@"userid"];
         self.honorFreeDays= self.affectCalculation;
      }
      
      if (self.__version >= 2)
      {
         self.honorFreeDays= [coder decodeObjectForKey:@"honorFreeDays"];
      }
   }
   
   return self;
}


@end
