//************************************************************
// PublicHoliday.h
// Holliday
//************************************************************
// Created by Patrick Fial on 14.08.15
// Copyright 2015-2015 Patrick Fial. All rights reserved.
//************************************************************

//************************************************************
// includes
//************************************************************

#import <Foundation/Foundation.h>
#import "PublicHolidayInfo.h"

//************************************************************
// class PublicHoliday
//************************************************************

@interface PublicHoliday : NSObject

@property (nonatomic, retain) NSLock* eventsLock;
@property (nonatomic, retain) NSMutableDictionary* events;
@property (nonatomic, assign) int initialized;

-(BOOL)reloadEntries;
-(void)clearCache;

-(BOOL)isPublicHoliday:(NSDate*)date;
-(NSArray*)getPublicHolidayForMonth:(int)month inYear:(int)year;
-(NSArray*)getPublicHolidayForDay:(int)day inMonth:(int)month inYear:(int)year;

+(PublicHoliday*)instance;

@end
