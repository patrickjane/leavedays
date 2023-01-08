//************************************************************
// Settings.m
// Annual Leave iPad
//************************************************************
// Created by Patrick Fial on 29.05.2010
// Copyright 2010-2012 Patrick Fial. All rights reserved.
//************************************************************

#import "Settings.h"
#import "User.h"

#import "EventService.h"
#import "Service.h"
#import "Storage.h"
#import "NSMutableDictionary-Expanded.h"

//************************************************************
// statics
//************************************************************

static NSDictionary* defaultSettings= nil;
static User* currentUser= nil;
static int transaction= noTact;
static NSUserDefaults* defaults= nil;

//************************************************************
// class Settings
//************************************************************

@implementation Settings

#pragma mark - Settings Interaction

//************************************************************
// init
//************************************************************

+(void)init
{
   // build default settings
   
   defaults= [[NSUserDefaults alloc] initWithSuiteName:@"HolidayApp"];
   
   NSDateComponents* comps = [[NSCalendar currentCalendar] components:(NSCalendarUnitDay | NSCalendarUnitMonth | NSCalendarUnitYear) fromDate:[NSDate date]];
   
   [comps setDay:1];
   [comps setMonth:1];
   
   NSDate* date= [[NSCalendar currentCalendar] dateFromComponents:comps];
   
   int defaultOpts[50];
   memset(defaultOpts, 0, sizeof(defaultOpts));
   
   NSData* data = [NSData dataWithBytes:defaultOpts length:sizeof(defaultOpts)];
   
   defaultSettings= [[NSDictionary alloc] initWithObjectsAndKeys:
                     @"0",   [NSString stringWithFormat:@"%d", skDefaultState],
                     @"1",   [NSString stringWithFormat:@"%d", skShowStateMarker],
                     @"0",   [NSString stringWithFormat:@"%d", skShowBadge],
                     @"0",   [NSString stringWithFormat:@"%d", skLeaveExpires],
                     @"65",  [NSString stringWithFormat:@"%d", skFreeDays],             // sunday (1) | saturday (7)
                     @"0",   [NSString stringWithFormat:@"%d", skStoreInCalendar],
                     @"0",   [NSString stringWithFormat:@"%d", skUsePublicHolidayCalendar],
                     @"1",   [NSString stringWithFormat:@"%d", skYearBegin],
                     @"1.0", [NSString stringWithFormat:@"%d", skLastVersion],
                     date,   [NSString stringWithFormat:@"%d", skResidualExpiration],
                     @"0",   [NSString stringWithFormat:@"%d", skUnit],
                     @"",    [NSString stringWithFormat:@"%d", skLastUser],
                     @"0",   [NSString stringWithFormat:@"%d", skAutoLogin],
                     @"1",   [NSString stringWithFormat:@"%d", skCalculatePlanned],
                     @"2",   [NSString stringWithFormat:@"%d", skLastMapType],
                     @"",    [NSString stringWithFormat:@"%d", skLastDropboxUser],
                     @"0",   [NSString stringWithFormat:@"%d", skUseICloud],
                     @"",    [NSString stringWithFormat:@"%d", skPublicHolidayCountry],
                     @"",    [NSString stringWithFormat:@"%d", skPublicHolidayState],
                     @"1",   [NSString stringWithFormat:@"%d", skSingleUser],
                     @"1",   [NSString stringWithFormat:@"%d", skFirstRun],
                     @"0",   [NSString stringWithFormat:@"%d", skICloudAvailable],
                     @"0",   [NSString stringWithFormat:@"%d", skCalendarColorByCategory],
                     @"1",   [NSString stringWithFormat:@"%d", skYearBeginPorted],
                     data,   [NSString stringWithFormat:@"%d", skLastLeaveOptions],
                     NSLocalizedString(@"Days off from $begin to $end", nil), [NSString stringWithFormat:@"%d", skMailSubject],
                     NSLocalizedString(@"boss@company.org", nil), [NSString stringWithFormat:@"%d", skMailTo],
                     NSLocalizedString(@"Hi,\nI'd like to take $duration days off from $begin to $end.\nRegards\nJohn Appleseed", nil), [NSString stringWithFormat:@"%d", skMailBody],
                     nil];

   [defaults registerDefaults:defaultSettings];
}

//************************************************************
// getDefaultSettings
//************************************************************

+(NSMutableDictionary*)getDefaultSettings
{
   return [defaultSettings mutableCopy];
}

//************************************************************
// load settings for a specific user
//************************************************************

+(void)loadUserSettings:(User*)user
{
   // save previous changes, if needed
   
   currentUser= user;
   
   [EventService initializeCalendarsWithEventStore:[EventService eventStore]];
}

//************************************************************
// synchronize changes to sqlite database
//************************************************************

+(void)synchronize
{
   [Settings synchronize:nil];
}

+(void)synchronize:(void (^)(BOOL success))completion
{
   if (!currentUser || transaction != noTact)
   {
      if (completion)
         completion(success);
      
      return;
   }
   
   [currentUser saveDocument:^(BOOL success)
    {
       if (!success)
          [Service alert:NSLocalizedString(@"Error", nil) withText:NSLocalizedString(@"Failed to save data", nil) andError:nil forController:nil completion:nil];
       
       if (completion)
          completion(success);
    }];
}

//************************************************************
// transaction
//************************************************************

+(void)transaction:(enum Transaction)tact completion:(void (^)(BOOL success))completion
{
   if (transaction != noTact && tact != tactEnd)
      return;
   
   if (tact == tactEnd)
   {
      transaction= noTact;
      [Settings synchronize:completion];
   }
   else
      transaction= tact;
}

#pragma mark - Generic User Settings wrapper functions

//************************************************************
// user settings / bool
//************************************************************

+(BOOL)userSettingBool:(int)key
{
   return [[currentUser.settings valueForKey:[NSString stringWithFormat:@"%d", key]] boolValue];
}

+(void)setUserSetting:(int)key withBool:(BOOL)value
{
   [currentUser.settings setBool:value forKey:[NSString stringWithFormat:@"%d", key]];
   [Settings synchronize];
}

+(void)setUserSettingUnsaved:(int)key withBool:(BOOL)value
{
   [currentUser.settings setBool:value forKey:[NSString stringWithFormat:@"%d", key]];
}

//************************************************************
// user settings / int
//************************************************************

+(int)userSettingInt:(int)key
{
   return (int)[[currentUser.settings valueForKey:[NSString stringWithFormat:@"%d", key]] integerValue];
}

+(void)setUserSetting:(int)key withInt:(int)value
{
   [currentUser.settings setInteger:value forKey:[NSString stringWithFormat:@"%d", key]];
   [Settings synchronize];
}

+(void)setUserSettingUnsaved:(int)key withInt:(int)value
{
   [currentUser.settings setInteger:value forKey:[NSString stringWithFormat:@"%d", key]];
}

//************************************************************
// user settings / object
//************************************************************

+(id)userSettingObject:(int)key
{
   return [currentUser.settings valueForKey:[NSString stringWithFormat:@"%d", key]];
}

+(void)setUserSetting:(int)key withObject:(id)value
{
   if (!value)
      [currentUser.settings removeObjectForKey:[NSString stringWithFormat:@"%d", key]];
   else
      [currentUser.settings setObject:value forKey:[NSString stringWithFormat:@"%d", key]];
   
   [Settings synchronize];
}

+(void)setUserSettingUnsaved:(int)key withObject:(id)value
{
   if (!value)
      [currentUser.settings removeObjectForKey:[NSString stringWithFormat:@"%d", key]];
   else
      [currentUser.settings setObject:value forKey:[NSString stringWithFormat:@"%d", key]];
}

#pragma mark - TEMPORARY USER settings (will not be saved)

//************************************************************
// user settings / bool
//************************************************************

+(BOOL)tempUserSettingBool:(int)key ofUser:(User *)user
{
   return [[user.settings valueForKey:[NSString stringWithFormat:@"%d", key]] boolValue];
}

+(void)setTempUserSetting:(int)key withBool:(BOOL)value ofUser:(User *)user
{
   [user.settings setBool:value forKey:[NSString stringWithFormat:@"%d", key]];
}

//************************************************************
// user settings / int
//************************************************************

+(int)tempUserSettingInt:(int)key ofUser:(User *)user
{
   return (int)[[user.settings valueForKey:[NSString stringWithFormat:@"%d", key]] integerValue];
}

+(void)setTempUserSetting:(int)key withInt:(int)value ofUser:(User *)user
{
   [user.settings setInteger:value forKey:[NSString stringWithFormat:@"%d", key]];
}

//************************************************************
// user settings / object
//************************************************************

+(id)tempUserSettingObject:(int)key ofUser:(User *)user
{
   return [user.settings valueForKey:[NSString stringWithFormat:@"%d", key]];
}

+(void)setTempUserSetting:(int)key withObject:(id)value ofUser:(User *)user
{
   if (!value)
      [user.settings removeObjectForKey:[NSString stringWithFormat:@"%d", key]];
   else
      [user.settings setObject:value forKey:[NSString stringWithFormat:@"%d", key]];
}

#pragma mark - Generic GLOBAL Settings wrapper functions

//************************************************************
// user settings / bool
//************************************************************

+(BOOL)globalSettingBool:(int)key
{
   return [[defaults valueForKey:[NSString stringWithFormat:@"%d", key]] boolValue];
}

+(void)setGlobalSetting:(int)key withBool:(BOOL)value
{
   [defaults setBool:value forKey:[NSString stringWithFormat:@"%d", key]];
   [defaults synchronize];
}

//************************************************************
// user settings / int
//************************************************************

+(int)globalSettingInt:(int)key
{
   return (int)[[defaults valueForKey:[NSString stringWithFormat:@"%d", key]] integerValue];
}

+(void)setGlobalSetting:(int)key withInt:(int)value
{
   [defaults setInteger:value forKey:[NSString stringWithFormat:@"%d", key]];
   [defaults synchronize];
}

//************************************************************
// user settings / object
//************************************************************

+(id)globalSettingObject:(int)key
{
   return [defaults valueForKey:[NSString stringWithFormat:@"%d", key]];
}

+(void)setGlobalSetting:(int)key withObject:(id)value
{
   if (!value)
      [defaults removeObjectForKey:[NSString stringWithFormat:@"%d", key]];
   else
      [defaults setObject:value forKey:[NSString stringWithFormat:@"%d", key]];
   
   [defaults synchronize];
}

//************************************************************
// user settings / string
//************************************************************

+(NSString*)globalSettingString:(int)key
{
   id res= [defaults valueForKey:[NSString stringWithFormat:@"%d", key]];
   
   NSAssert([res isKindOfClass:[NSString class]], @"trying to load key (%d) not of type string", key);
   
   return res;
}

+(void)setGlobalSetting:(int)key withString:(NSString*)value
{
   NSAssert([value isKindOfClass:[NSString class]], @"trying to save key (%d) not of type string", key);
   
   if (!value)
      [defaults removeObjectForKey:[NSString stringWithFormat:@"%d", key]];
   else
      [defaults setObject:value forKey:[NSString stringWithFormat:@"%d", key]];
   
   [defaults synchronize];
}


@end
