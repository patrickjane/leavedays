//************************************************************
// EventService.h
// Annual Leave iPad
//************************************************************
// Created by Patrick Fial on 04.01.2012
// Copyright 2011-2012 Patrick Fial. All rights reserved.
//************************************************************

#import <Foundation/Foundation.h>
#import <EventKit/EventKit.h>

@interface CalendarInfo : NSObject 
{
   EKCalendar* calendar;
   NSString* sourceTitle;
   NSString* sourceIdentifier;
   NSArray* calendarArray;
}

@property (nonatomic, retain) NSArray* calendarArray;
@property (nonatomic, retain) EKCalendar* calendar;
@property (nonatomic, retain) NSString* sourceTitle;
@property (nonatomic, retain) NSString* sourceIdentifier;

@end 

@interface EventService : NSObject

// calendar specific

+(void)setHaveCalendarAccess:(BOOL)to;
+(BOOL)haveCalendarAccess;
+(EKCalendar*)storageCalendar;
+(EKCalendar*)publicHolidayCalendar;
+(void) setStorageCalendar:(EKCalendar*)cal;
+(void) setPublicHolidayCalendar:(EKCalendar*)cal;
+(void)setEventStore:(EKEventStore*)store;
+(EKEventStore*)eventStore;

+(void) initializeCalendarsWithEventStore:(EKEventStore*) eventStore;

@end
