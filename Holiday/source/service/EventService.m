//************************************************************
// EventService.m
// Annual Leave iPad
//************************************************************
// Created by Patrick Fial on 04.01.2012
// Copyright 2011-2012 Patrick Fial. All rights reserved.
//************************************************************

#import "EventService.h"
#import "Settings.h"
#import "Service.h"
#import "AppDelegate.h"

// *****************************************
#pragma mark - Class CalendarInfo
// *****************************************

@implementation CalendarInfo

@synthesize calendar;
@synthesize calendarArray;
@synthesize sourceTitle;
@synthesize sourceIdentifier;

@end

// *****************************************
// EventService
// *****************************************

@implementation EventService

// *****************************************
#pragma mark - statics
// *****************************************

static EKEventStore* eventStore= nil;
static EKCalendar* storageCalendar= nil;
static EKCalendar* publicHolidayCalendar= nil;
static BOOL haveAccess = NO;

// *****************************************
#pragma mark - implementation
// *****************************************

// ************************************************************
// have calendar access
// ************************************************************

+(void)setHaveCalendarAccess:(BOOL)to
{
   haveAccess= to;
}

+(BOOL)haveCalendarAccess
{
   return haveAccess;
}

// ************************************************************
// storageCalendar
// ************************************************************

+(EKCalendar*)storageCalendar
{
   return storageCalendar;
}

// ************************************************************
// publicHolidayCalendar
// ************************************************************

+(EKCalendar*)publicHolidayCalendar
{
   return publicHolidayCalendar;
}

// ************************************************************
// setStorageCalendar
// ************************************************************

+(void) setStorageCalendar:(EKCalendar*)cal
{
   if (storageCalendar)
      [storageCalendar release];
   
   storageCalendar= [cal retain];
}

// ************************************************************
// setPublicHolidayCalendar
// ************************************************************

+(void) setPublicHolidayCalendar:(EKCalendar*)cal
{
   if (publicHolidayCalendar)
      [publicHolidayCalendar release];
   
   publicHolidayCalendar= [cal retain];
}

// ************************************************************
// setPublicHolidayCalendar
// ************************************************************

+(void)setEventStore:(EKEventStore*)store
{
   if (eventStore)
      [eventStore release];
   
   eventStore= [store retain];
}

+(EKEventStore*)eventStore
{
   return eventStore;
}

// *****************************************
// initializeCalendars
// *****************************************

+(void) initializeCalendarsWithEventStore:(EKEventStore*) eventStore 
{
   if (!eventStore)
      return;
   
   AppDelegate* del= (AppDelegate*)[UIApplication sharedApplication].delegate;
   UIViewController* theController = del.window.rootViewController;
   
   publicHolidayCalendar= [[eventStore calendarWithIdentifier:[Settings userSettingObject:skPublicHolidayIndentifier]] retain];
   storageCalendar= [[eventStore calendarWithIdentifier:[Settings userSettingObject:skStorageIdentifier]] retain];
   
   // public holiday calendar
   
   if ([Settings userSettingBool:skStoreInCalendar] && !storageCalendar)
   {
      [Service message:NSLocalizedString(@"Calendar not found", nil) withText:NSLocalizedString(@"Selected calendar for leave storage not found. Storing leave in calendar has been disabled.", nil) forController:theController completion:nil];
      [Settings setUserSetting:skStoreInCalendar withBool:NO];
      [Settings setUserSetting:skStorageSource withObject:nil];
      [Settings setUserSetting:skStorageIdentifier withObject:nil];
   }
   
   // public holiday calendar
   
   if ([Settings userSettingBool:skUsePublicHolidayCalendar] && !publicHolidayCalendar)
   {
      [Service message:NSLocalizedString(@"Calendar not found", nil) withText:NSLocalizedString(@"Selected public holiday calendar not found. Public holiday calendar has been disabled.", nil) forController:theController completion:nil];
      [Settings setUserSetting:skUsePublicHolidayCalendar withBool:NO];
      [Settings setUserSetting:skPublicHolidayIndentifier withObject:nil];
      [Settings setUserSetting:skPublicHolidaySource withObject:nil];
   }
}

@end
