//************************************************************
// LeaveInfo.m
// Holliday
//************************************************************
// Created by Patrick Fial on 06.01.12.
// Copyright 2012-2013 Patrick Fial. All rights reserved.
//************************************************************

//************************************************************
// includes
//************************************************************

#import <EventKit/EventKit.h>
#import "LeaveInfo.h"
#import "Settings.h"
#import "Service.h"

//************************************************************
// class LeaveInfo
//************************************************************

@implementation LeaveInfo

@synthesize affectsCalculation, begin, begin_half_day, calculateDuration;
@synthesize category, comment, duration, end, end_half_day, isUnknownDate;
@synthesize monthNameOfBegin, savedAsHours, status, sumMonthly, timeTable;
@synthesize title, userid, year, month, location, userInfo, uuid, annotation, options;
@synthesize __version, mode;

#pragma mark - NSCoding

//************************************************************
// contentsForType
//************************************************************

- (void)encodeWithCoder:(NSCoder *)coder
{
   [coder encodeInt:2 forKey:@"VERSION"];
   
   [coder encodeObject:self.affectsCalculation forKey:@"affectsCalculation"];
   [coder encodeObject:self.begin forKey:@"begin"];
   [coder encodeObject:self.begin_half_day forKey:@"begin_half_day"];
   [coder encodeObject:self.calculateDuration forKey:@"calculateDuration"];
   [coder encodeObject:self.category forKey:@"category"];
   [coder encodeObject:self.comment forKey:@"comment"];
   [coder encodeObject:self.duration forKey:@"duration"];
   [coder encodeObject:self.end forKey:@"end"];
   [coder encodeObject:self.end_half_day forKey:@"end_half_day"];
   [coder encodeObject:self.isUnknownDate forKey:@"isUnknownDate"];
   [coder encodeObject:self.monthNameOfBegin forKey:@"monthNameOfBegin"];
   [coder encodeObject:self.savedAsHours forKey:@"savedAsHours"];
   [coder encodeObject:self.status forKey:@"status"];
   [coder encodeObject:self.sumMonthly forKey:@"sumMonthly"];
   [coder encodeObject:self.timeTable forKey:@"timeTable"];
   [coder encodeObject:self.title forKey:@"title"];
   [coder encodeObject:self.userid forKey:@"userid"];
   [coder encodeObject:self.year forKey:@"year"];
   [coder encodeObject:self.month forKey:@"month"];
   [coder encodeObject:self.location forKey:@"location"];
   [coder encodeObject:self.userInfo forKey:@"userInfo"];
   [coder encodeObject:self.uuid forKey:@"uuid"];
   [coder encodeObject:self.options forKey:@"options"];
   [coder encodeObject:self.mode forKey:@"mode"];
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
         self.affectsCalculation= [coder decodeObjectForKey:@"affectsCalculation"];
         self.begin= [coder decodeObjectForKey:@"begin"];
         self.begin_half_day= [coder decodeObjectForKey:@"begin_half_day"];
         self.calculateDuration= [coder decodeObjectForKey:@"calculateDuration"];
         self.category= [coder decodeObjectForKey:@"category"];
         self.comment= [coder decodeObjectForKey:@"comment"];
         self.end= [coder decodeObjectForKey:@"end"];
         self.end_half_day= [coder decodeObjectForKey:@"end_half_day"];
         self.duration= [coder decodeObjectForKey:@"duration"];
         self.isUnknownDate= [coder decodeObjectForKey:@"isUnknownDate"];
         self.monthNameOfBegin= [coder decodeObjectForKey:@"monthNameOfBegin"];
         self.savedAsHours= [coder decodeObjectForKey:@"savedAsHours"];
         self.status= [coder decodeObjectForKey:@"status"];
         self.sumMonthly= [coder decodeObjectForKey:@"sumMonthly"];
         self.timeTable= [coder decodeObjectForKey:@"timeTable"];
         self.title= [coder decodeObjectForKey:@"title"];
         self.userid= [coder decodeObjectForKey:@"userid"];
         self.year= [coder decodeObjectForKey:@"year"];
         self.month= [coder decodeObjectForKey:@"month"];
         self.location= [coder decodeObjectForKey:@"location"];
         self.userInfo= [coder decodeObjectForKey:@"userInfo"];
         self.uuid= [coder decodeObjectForKey:@"uuid"];
         self.options= [coder decodeObjectForKey:@"options"];
      }

      if (self.__version >= 2)
      {
         self.mode= [coder decodeObjectForKey:@"mode"];
      }
      else
      {
         self.mode = [NSNumber numberWithInt:0];
      }
   }

   return self;
}

#pragma mark - Utility

//************************************************************
// monthNameOfBegin
//************************************************************

- (NSString *)monthNameOfBegin 
{
   return @"";
}

//************************************************************
// saveInCalendar
//************************************************************

- (bool) saveInCalendar:(NSArray*)calendars store:(EKEventStore*)store
{
   if (![Settings userSettingBool:skStoreInCalendar] || ![calendars count] || !store)
      return false;
   
   if (!self.begin || !self.end)
      return true;
   
   EKEvent* event= [EKEvent eventWithEventStore:store];
   EKCalendar* cal2= [calendars objectAtIndex:0];

   NSCalendar* gregorian = [NSCalendar currentCalendar];
   NSDateComponents *comps = [[NSDateComponents alloc] init];
   [comps setHour:23];
   [comps setMinute:59];
   [comps setSecond:58];
   NSDate* endDate = [gregorian dateByAddingComponents:comps toDate:self.end options:0];
   [comps release];

   [event setStartDate:self.begin];
   [event setEndDate:endDate];
   [event setTitle:self.title];
   [event setNotes:self.comment];
   event.calendar= cal2;
   [event setAllDay:true];
   
   NSError* err= nil;
   
   if ([store saveEvent:event span:EKSpanThisEvent error:&err] != true)
      [Service alert:NSLocalizedString(@"Error", nil) withText:nil andError:err forController:nil completion:nil];
   
   return true;
}

//************************************************************
// deleteFromCalendar
//************************************************************

- (bool) deleteFromCalendar:(NSArray*)calendars store:(EKEventStore*)store
{
   if (![Settings userSettingBool:skStoreInCalendar])
      return true;
   
   if (!self.begin || !self.end)
      return true;
   
   bool res= true;
   NSCalendar* gregorian = [NSCalendar currentCalendar];
   NSDateComponents *comps = [[NSDateComponents alloc] init];
   [comps setHour:23];
   [comps setMinute:59];
   [comps setSecond:59];
   NSDate* endDate = [gregorian dateByAddingComponents:comps toDate:self.end options:0];
   [comps release];
   
   NSPredicate* predicate = [store predicateForEventsWithStartDate:self.begin
                                                           endDate:endDate
                                                         calendars:calendars];
   
   NSArray* events = [store eventsMatchingPredicate:predicate];
   NSError* err;
   
   for (int i = 0; i < [events count]; i++)
   {
      EKEvent* e= [events objectAtIndex:i];
      
      if (![[e title] isEqualToString:self.title] && !(e.title == nil && self.title == nil)  && !(e.title.length == 0 && self.title.length == 0))
         continue;
      
      if ([store removeEvent:e span:EKSpanThisEvent error:&err] != true)
      {
         [Service alert:NSLocalizedString(@"Error", nil) withText:nil andError:err forController:nil completion:nil];
         
         res= false;
         break;
      }
   }
   
   return res;
}

@end
