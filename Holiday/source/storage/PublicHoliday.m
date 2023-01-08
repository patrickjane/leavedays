//************************************************************
// PublicHoliday.m
// Holliday
//************************************************************
// Created by Patrick Fial on 14.08.15
// Copyright 2015-2015 Patrick Fial. All rights reserved.
//************************************************************

//************************************************************
// includes
//************************************************************

#import "PublicHoliday.h"
#import "Service.h"
#import "EventService.h"
#import "Settings.h"

//************************************************************
// class PublicHoliday
//************************************************************

@implementation PublicHoliday
@synthesize events, initialized;

#pragma mark - Lifecycle

//************************************************************
// statics
//************************************************************

static PublicHoliday* theInstance= nil;

//************************************************************
// instance
//************************************************************

+(PublicHoliday*)instance
{
   return theInstance;
}
//************************************************************
// init
//************************************************************

-(id)init
{
   self= [super init];
   
   if (self)
   {
      self.initialized = NO;
      self.events = [NSMutableDictionary dictionary];
      self.eventsLock= [[[NSLock alloc] init] autorelease];
      
      theInstance= self;
   }
   
   return self;
}

//************************************************************
// dealloc
//************************************************************

-(void)dealloc
{
   self.events= nil;
   self.eventsLock= nil;
   [super dealloc];
}

//************************************************************
// isSameDates
//************************************************************

- (BOOL)isSameDates:(NSDate*)date1 date2:(NSDate*)date2
{
   NSCalendar* calendar = [NSCalendar currentCalendar];
   unsigned unitFlags = NSCalendarUnitYear | NSCalendarUnitMonth |  NSCalendarUnitDay;
   NSDateComponents* comp1 = [calendar components:unitFlags fromDate:date1];
   NSDateComponents* comp2 = [calendar components:unitFlags fromDate:date2];
   
   return [comp1 day] == [comp2 day] && [comp1 month] == [comp2 month] && [comp1 year]  == [comp2 year];
}

#pragma mark - Caching/Loading

//************************************************************
// clearCache
//************************************************************

-(void)clearCache
{
   self.events= [NSMutableDictionary dictionary];
   [[NSNotificationCenter defaultCenter] postNotificationName:kPublicHolidayEntriesLoaded object:self];
}

//************************************************************
// load
//************************************************************

-(BOOL)reloadEntries
{
   if (![EventService haveCalendarAccess] || ![EventService publicHolidayCalendar] || ![Settings userSettingBool:skUsePublicHolidayCalendar])
   {
      [[NSNotificationCenter defaultCenter] postNotificationName:kPublicHolidayEntriesLoaded object:self];

      return NO;
   }
   
   int range= CALENDAR_YEAR_RANGE;
   int todayYear= (int)[[NSCalendar currentCalendar] component:NSCalendarUnitYear fromDate:[NSDate date]];
   dispatch_group_t group= dispatch_group_create();
   
   // clear previous
   
   self.events = [NSMutableDictionary dictionary];
   
   // loop years, doing the eventstore query in background queue

   for (int year= todayYear-range; year < todayYear+range; year++)
   {
      dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0),^
      {
         dispatch_group_enter(group);
         
         NSMutableArray* result= [NSMutableArray array];
         NSDate* tmpStartDate;
         NSDate* tmpEndDate;
         NSDateComponents* comps = [[[NSDateComponents alloc] init] autorelease];
         
         comps.day = 1;
         comps.month = 1;
         comps.year = year;
         tmpStartDate = [[NSCalendar currentCalendar] dateFromComponents:comps];
         
         comps.day = 31;
         comps.month = 12;
         comps.year = year;
         tmpEndDate = [[NSCalendar currentCalendar] dateFromComponents:comps];
         
         NSPredicate* predicate = [[EventService eventStore] predicateForEventsWithStartDate:tmpStartDate
                                                                                   endDate:tmpEndDate
                                                                                 calendars:[NSArray arrayWithObject:[EventService publicHolidayCalendar]]];
         
         NSArray* queryResults = [[EventService eventStore] eventsMatchingPredicate:predicate];
         
         for (EKEvent* evt in queryResults)
         {
            PublicHolidayInfo* ph= [[[PublicHolidayInfo alloc] init] autorelease];
            ph.title= evt.title;
            ph.date= evt.startDate;
            ph.year= [NSNumber numberWithInteger:year];
            
            [result addObject:ph];
         }
         
         [self.eventsLock lock];
         [self.events setObject:result forKey:[NSNumber numberWithInteger:year]];
         [self.eventsLock unlock];
         
         dispatch_group_leave(group);
      });
   }
   
   // wait in background for all operations to finish
   
   dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0),^
   {
      dispatch_group_wait(group, DISPATCH_TIME_FOREVER);
      dispatch_release(group);
                     
      dispatch_async(dispatch_get_main_queue(),^
      {
         self.initialized= YES;
                                       
         [[NSNotificationCenter defaultCenter] postNotificationName:kPublicHolidayEntriesLoaded object:self];
      });
   });

   return TRUE;
}

#pragma mark - Access

//************************************************************
// Is PublicHoliday
//************************************************************

-(BOOL)isPublicHoliday:(NSDate*)date
{
   EKEventStore* store= [EventService eventStore];
   
   if (!store || ![Settings userSettingBool:skUsePublicHolidayCalendar] || ![EventService publicHolidayCalendar])
      return false;
   
   NSDate* tmpStartDate = [Service trunc:date];
   NSDate* tmpEndDate = [tmpStartDate dateByAddingTimeInterval:85999];
   
   NSPredicate* predicate = [store predicateForEventsWithStartDate:tmpStartDate
                                                           endDate:tmpEndDate
                                                         calendars:[NSArray arrayWithObject:[EventService publicHolidayCalendar]]];
   
   NSArray* events = [store eventsMatchingPredicate:predicate];
   
   bool res = [events count] > 0;
   
   return res;
}

//************************************************************
// getPublicHolidayForMonth
//************************************************************

-(NSArray*)getPublicHolidayForMonth:(int)aMonth inYear:(int)aYear
{
   NSArray* entries= [self.events objectForKey:[NSNumber numberWithInteger:aYear]];
   EKEventStore* store= [EventService eventStore];
   
   if (!store || ![Settings userSettingBool:skUsePublicHolidayCalendar] || ![EventService publicHolidayCalendar] || !entries || !entries.count)
      return [NSArray array];
   
   NSDate* tmpStartDate;
   NSDate* tmpEndDate;
   NSDateComponents* comps = [[[NSDateComponents alloc] init] autorelease];
   
   comps.day = 1;
   comps.month = aMonth;
   comps.year = aYear;
   tmpStartDate = [[NSCalendar currentCalendar] dateFromComponents:comps];
   
   NSRange range= [[NSCalendar currentCalendar] rangeOfUnit:NSCalendarUnitDay inUnit:NSCalendarUnitMonth forDate:tmpStartDate];
   
   comps.day = range.length > 0 ? range.length : 28;
   comps.month = aMonth;
   comps.year = aYear;
   tmpEndDate = [[NSCalendar currentCalendar] dateFromComponents:comps];
   
   NSArray* events = [entries filteredArrayUsingPredicate:[NSPredicate predicateWithBlock:^BOOL(id object, NSDictionary *bindings) {
      PublicHolidayInfo* ifo= (PublicHolidayInfo*)object;
      return [Service date:ifo.date isBetweenDate:tmpStartDate andDate:tmpEndDate];
   }]];

   return events;
}

//************************************************************
// getPublicHolidayForDay
//************************************************************

-(NSArray*)getPublicHolidayForDay:(int)aDay inMonth:(int)aMonth inYear:(int)aYear
{
   NSArray* entries= [self.events objectForKey:[NSNumber numberWithInteger:aYear]];
   EKEventStore* store= [EventService eventStore];
   
   if (!store || ![Settings userSettingBool:skUsePublicHolidayCalendar] || ![EventService publicHolidayCalendar] || !entries || !entries.count)
      return [NSArray array];

   NSDate* tmpStartDate, *tmpEndDate;
   NSDateComponents* comps = [[[NSDateComponents alloc] init] autorelease];
   
   comps.day = aDay;
   comps.month = aMonth;
   comps.year = aYear;
   tmpStartDate = [[NSCalendar currentCalendar] dateFromComponents:comps];
   
   comps.hour = 23;
   comps.minute = 59;
   comps.second = 59;
   tmpEndDate = [[NSCalendar currentCalendar] dateFromComponents:comps];
   
   NSArray* events = [entries filteredArrayUsingPredicate:[NSPredicate predicateWithBlock:^BOOL(id object, NSDictionary *bindings) {
      PublicHolidayInfo* ifo= (PublicHolidayInfo*)object;
      return [Service date:ifo.date isBetweenDate:tmpStartDate andDate:tmpEndDate];
   }]];

   return events;
}

//************************************************************
// getPublicHolidayItems
//************************************************************

-(NSArray*)getPublicHolidayItemsInYear:(int)aYear
{
   NSArray* entries= [self.events objectForKey:[NSNumber numberWithInteger:aYear]];

   return entries ? entries : [NSArray array];
}

@end

