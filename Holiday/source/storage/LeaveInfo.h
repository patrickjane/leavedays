//************************************************************
// LeaveInfo.h
// Holliday
//************************************************************
// Created by Patrick Fial on 06.01.12.
// Copyright 2012-2013 Patrick Fial. All rights reserved.
//************************************************************

//************************************************************
// includes
//************************************************************

@class EventAnnotation;
@class EKEventStore;

@interface LeaveInfo : NSObject<NSCoding>

@property (nonatomic, assign) int __version;
@property (nonatomic, retain) NSNumber * affectsCalculation;
@property (nonatomic, retain) NSDate * begin;
@property (nonatomic, retain) NSNumber * begin_half_day;
@property (nonatomic, retain) NSNumber * calculateDuration;
@property (nonatomic, retain) NSString * category;
@property (nonatomic, retain) NSString * comment;
@property (nonatomic, retain) NSNumber * duration;
@property (nonatomic, retain) NSDate * end;
@property (nonatomic, retain) NSNumber * end_half_day;
@property (nonatomic, retain) NSNumber * isUnknownDate;
@property (nonatomic, retain) NSString * monthNameOfBegin;
@property (nonatomic, retain) NSNumber * savedAsHours;
@property (nonatomic, retain) NSNumber * status;
@property (nonatomic, retain) NSNumber * sumMonthly;
@property (nonatomic, retain) NSString * timeTable;
@property (nonatomic, retain) NSString * title;
@property (nonatomic, retain) NSString * userid;
@property (nonatomic, retain) NSNumber * year;
@property (nonatomic, retain) NSNumber * month;
@property (nonatomic, retain) NSDictionary * location;
@property (nonatomic, retain) NSString * userInfo;
@property (nonatomic, retain) NSString * uuid;
@property (nonatomic, retain) NSData * options;
@property (nonatomic, retain) NSNumber * mode;

@property (nonatomic, assign) EventAnnotation* annotation;

- (NSString *)monthNameOfBegin;

- (bool) saveInCalendar:(NSArray*)calendars store:(EKEventStore*)store;
- (bool) deleteFromCalendar:(NSArray*)calendars store:(EKEventStore*)store;

@end
