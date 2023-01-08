//************************************************************
// Settings.h
// Annual Leave iPad
//************************************************************
// Created by Patrick Fial on 29.05.2010
// Copyright 2010-2012 Patrick Fial. All rights reserved.
//************************************************************

//************************************************************
// includes
//************************************************************

#import <Foundation/Foundation.h>

//************************************************************
// defines
//************************************************************

enum SettingsKeys
{
   skDefaultState,               // 0
   skShowStateMarker,            // 1
   skShowBadge,                  // 2
   skLeaveExpires,               // 3
   skUnit,                       // 4
   skCalculatePlanned,           // 5
   skFreeDays,                   // 6
   skStoreInCalendar,            // 7
   skUsePublicHolidayCalendar,   // 8
   skPublicHolidayIndentifier,   // 9
   skPublicHolidaySource,        // 10
   skStorageIdentifier,          // 11
   skStorageSource,              // 12
   skCalendarColoring,           // 13
   skMailBody,                   // 14
   skMailSubject,                // 15
   skMailTo,                     // 16
   skMailCc,                     // 17
   skMailBcc,                    // 18
   skYearBegin,                  // 19
   skResidualExpiration,         // 20
   skLastVersion,                // 21
   skDisplayUserIds,             // 22
   skShownCalendars,             // 23
   skLastMapType,                // 24
   skPublicHolidayCountry,       // 25
   skPublicHolidayState,         // 26
   skSingleUser,                 // 27
   skFirstRun,                   // 28
   skLastUser,                   // 29
   skAutoLogin,                  // 30
   skLastDropboxUser,            // 31
   skUseICloud,                  // 32
   skICloudAvailable,            // 33
   skCalendarColorByCategory,    // 34
   skYearBeginPorted,            // 35
   skLastLeaveOptions            // 36
};

enum Transaction
{
   noTact= -1,
   
   tactBegin,
   tactEnd
};

@class User;

//************************************************************
// class Settings
//************************************************************

@interface Settings : NSObject

// functions

+(void)init;
+(void)loadUserSettings:(User*)user;
+(void)synchronize;
+(void)synchronize:(void (^)(BOOL success))completion;
+(void)transaction:(enum Transaction)tact completion:(void (^)(BOOL success))completion;

+(NSMutableDictionary*)getDefaultSettings;

// global settings API

+(BOOL)globalSettingBool:(int)key;
+(void)setGlobalSetting:(int)key withBool:(BOOL)value;

+(int)globalSettingInt:(int)key;
+(void)setGlobalSetting:(int)key withInt:(int)value;

+(id)globalSettingObject:(int)key;
+(void)setGlobalSetting:(int)key withObject:(id)value;

+(NSString*)globalSettingString:(int)key;
+(void)setGlobalSetting:(int)key withString:(NSString*)value;

// user settings API

+(BOOL)userSettingBool:(int)key;
+(void)setUserSetting:(int)key withBool:(BOOL)value;
+(void)setUserSettingUnsaved:(int)key withBool:(BOOL)value;

+(int)userSettingInt:(int)key;
+(void)setUserSetting:(int)key withInt:(int)value;
+(void)setUserSettingUnsaved:(int)key withInt:(int)value;

+(id)userSettingObject:(int)key;
+(void)setUserSetting:(int)key withObject:(id)value;
+(void)setUserSettingUnsaved:(int)key withObject:(id)value;

// temp user setting (not saved)

+(BOOL)tempUserSettingBool:(int)key ofUser:(User*)user;
+(void)setTempUserSetting:(int)key withBool:(BOOL)value ofUser:(User*)user;

+(int)tempUserSettingInt:(int)key ofUser:(User*)user;
+(void)setTempUserSetting:(int)key withInt:(int)value ofUser:(User*)user;

+(id)tempUserSettingObject:(int)key ofUser:(User*)user;
+(void)setTempUserSetting:(int)key withObject:(id)value ofUser:(User*)user;

@end


