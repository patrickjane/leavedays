//************************************************************
// Calculation.h
// Annual Leave iPad
//************************************************************
// Created by Patrick Fial on 04.01.2012
// Copyright 2011-2012 Patrick Fial. All rights reserved.
//************************************************************

//************************************************************
// includes
//************************************************************

#import <Foundation/Foundation.h>

@class YearSummary;
@class Pool;
@class EKEventStore;
@class LeaveInfo;

//************************************************************
// class Calculation
//************************************************************

@interface Calculation : NSObject

+(BOOL) isWorkday:(NSDate*)date freeDays:(int)freeDays;
+(double) hoursForDay:(NSDate*)tmpStartDate andTimeTables:(NSMutableArray*)timeTables andWeek:(int)week;

+(NSArray*) getDistinctDays:(NSDate*)from to:(NSDate*)to inMonth:(int)inMonth andYear:(int)inYear;

+(int) getThisYear;

+(void)recalculateYear:(int)year withLastYearRemain:(double)lastYearRemain  setRemain:(bool)setLastYearRemain completion:(void (^)(BOOL success))completionHandler;
+(void)recalculateYearSummary:(YearSummary*)yearSummary withLastYearRemain:(double)lastYearRemain setRemain:(bool)setLastYearRemain completion:(void (^)(BOOL success))completionHandler;
+(void)recalculateAllYears;

+(void)expireResidualLeave:(YearSummary*)year completion:(void(^)(BOOL success))completion;

+(double) calculateLeaveDuration:(NSDate*)beginDate
                             _in:(NSDate*)endDate
                             _in:(bool)beginHalfDay 
                             _in:(bool)endHalfDay
                             _in:(bool)needsHourInput
                             _in:(bool)affectsCalc
                             _in:(NSMutableArray*)timeTables
                             _in:(int)inMonth
                             _in:(int)inYear;

@end
