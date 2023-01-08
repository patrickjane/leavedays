//************************************************************
// Calculation.m
// Annual Leave iPad
//************************************************************
// Created by Patrick Fial on 04.01.2012
// Copyright 2011-2012 Patrick Fial. All rights reserved.
//************************************************************

#import "Calculation.h"
#import "YearSummary.h"
#import "Pool.h"
#import "Timetable.h"
#import "Service.h"
#import "Settings.h"
#import "EventService.h"
#import "Category.h"
#import "LeaveInfo.h"
#import "User.h"
#import "PublicHoliday.h"

#import "SessionManager.h"
#import "Storage.h"

@implementation Calculation

// ************************************************************
#pragma mark - implementation
// ************************************************************
// isWorkday
// ************************************************************

+(BOOL) isWorkday:(NSDate*)date freeDays:(int)freeDays 
{
   NSCalendar* cal = [NSCalendar currentCalendar];
   NSDateComponents* weekdayComponents = [cal components:(NSCalendarUnitDay | NSCalendarUnitWeekday) fromDate:date];
   NSInteger weekday = [weekdayComponents weekday];
   
   // need to substract 1 from weekday, because 'freeDays' bitmask starts at 1, not 2
   
   return !(freeDays & (1 << (weekday-1)));
}

// ************************************************************
// hours for day
// ************************************************************

+(double)hoursForDay:(NSDate*)date andTimeTables:(NSMutableArray*)timeTables andWeek:(int)week
{
   if (!date || !timeTables)
      return 8.0;

   NSCalendar* cal = [NSCalendar currentCalendar];
   NSDateComponents* weekdayComponents = [cal components:(NSCalendarUnitDay | NSCalendarUnitWeekday) fromDate:date];
   NSInteger weekday = [weekdayComponents weekday];
   int index= week % timeTables.count;
   Timetable* timeTable= [timeTables objectAtIndex:index];
   
   double res= 0.0;
   
   switch (weekday-1)    // [weekdayComponents weekday] goes from 1-7
   {
      case 0: res= [timeTable.day_0 doubleValue]; break;
      case 1: res= [timeTable.day_1 doubleValue]; break;
      case 2: res= [timeTable.day_2 doubleValue]; break;
      case 3: res= [timeTable.day_3 doubleValue]; break;
      case 4: res= [timeTable.day_4 doubleValue]; break;
      case 5: res= [timeTable.day_5 doubleValue]; break;
      case 6: res= [timeTable.day_6 doubleValue]; break;
         
      default: break;
   }
   
   return res;
}

// *****************************************
// get distinct days
// *****************************************

+(NSArray*) getDistinctDays:(NSDate*)from to:(NSDate*)to inMonth:(int)inMonth andYear:(int)inYear
{
   NSMutableArray* tmpResults= [[NSMutableArray alloc] init];
   NSDateComponents* comps= nil;
   NSDate* tmpStartDate = from;
   NSDate* tmpEndDate = to;
   NSTimeZone* tz= [NSTimeZone localTimeZone];
   int lastUtcOffset= (int)[tz secondsFromGMTForDate:tmpStartDate];
   int utcOffset= 0;
   
   if ([tmpStartDate compare:tmpEndDate] ==  NSOrderedDescending)
   {
      comps= [[NSCalendar currentCalendar] components:NSCalendarUnitMonth fromDate:tmpStartDate];
      
      if (inMonth == na || inMonth == comps.month)
         [tmpResults addObject:tmpStartDate];
   }
   else
   {         
      while ([tmpStartDate compare:tmpEndDate] ==  NSOrderedAscending || [tmpStartDate compare:tmpEndDate] == NSOrderedSame)
      {
         comps= [[NSCalendar currentCalendar] components:NSCalendarUnitMonth|NSCalendarUnitYear fromDate:tmpStartDate];
         
         if ((inMonth == na || inMonth == comps.month) && (inYear == na || inYear == comps.year))
            [tmpResults addObject:tmpStartDate];
         
         tmpStartDate = [tmpStartDate dateByAddingTimeInterval:SECONDS_PER_DAY];
         
         utcOffset= (int)[tz secondsFromGMTForDate:tmpStartDate];
         
         if (lastUtcOffset != utcOffset)
            tmpStartDate = [tmpStartDate dateByAddingTimeInterval:(lastUtcOffset-utcOffset)];
         
         lastUtcOffset= utcOffset;
      }
   }
   
   NSArray* result= [[tmpResults copy] autorelease];
   [tmpResults release];
   
   return result;
}

// *****************************************
// getThisYear
// *****************************************

+(int) getThisYear
{
   int yearBeginMonth = [Settings userSettingInt:skYearBegin];
   NSDateComponents* comps = [[NSCalendar currentCalendar] components:NSCalendarUnitYear|NSCalendarUnitMonth fromDate:[NSDate date]];
   int thisYear= (int)comps.year;
   
   if (yearBeginMonth > 1 && comps.month <= yearBeginMonth)
      thisYear--;
   
   return thisYear;
}

// *****************************************
// recalculate year
// *****************************************

+(void)recalculateYear:(int)year withLastYearRemain:(double)lastYearRemain setRemain:(bool)setLastYearRemain completion:(void (^)(BOOL success))completionHandler
{
   YearSummary* theYear= [[Storage currentStorage] getYear:year];

   if (theYear)
      [Calculation recalculateYearSummary:theYear withLastYearRemain:lastYearRemain setRemain:setLastYearRemain completion:completionHandler];
   else if (completionHandler)
      completionHandler(YES);
   
   return;
}

// *****************************************
// recalculate year summary
// *****************************************

+(void)recalculateYearSummary:(YearSummary*)yearSummary withLastYearRemain:(double)lastYearRemain setRemain:(bool)setLastYearRemain completion:(void (^)(BOOL success))completionHandler
{
   int theYear= [yearSummary.year intValue];
   User* owner= [[Storage currentStorage] userWithUUid:yearSummary.userid];
   
   NSLog(@"Recalculating year %d", yearSummary.year.intValue);
   
   if (!owner)
   {
      NSLog(@"FATAL: Unable to find owner '%@' for year (%d) to recalculate summary",
            yearSummary.userid, yearSummary.year.intValue);
      
      if (completionHandler)
         completionHandler(NO);
      
      return;
   }
   
   NSPredicate* predicate= nil;
   
   if ([Settings userSettingBool:skCalculatePlanned])
      predicate= [NSPredicate predicateWithFormat:@"year == %d and userid == %@", theYear, [SessionManager activeUser].uuid];
   else
      predicate= [NSPredicate predicateWithFormat:@"(year == %d) and (status == 1) and (userid == %@)", theYear, [SessionManager activeUser].uuid];

   NSArray* entries= [owner.leave filteredArrayUsingPredicate:predicate];
   
   entries= [entries sortedArrayUsingDescriptors:[NSArray arrayWithObject:[NSSortDescriptor sortDescriptorWithKey:@"begin" ascending:YES]]];
   
   if (!entries)
   {
      NSLog(@"Year %d does not have entries, skipping calculation & saving", yearSummary.year.intValue);
      
      [[Storage currentStorage] saveYear:yearSummary completion:completionHandler];
      return;
   }
   
   // variables
   
   double yearSpent= 0.0;
   double yearRemain= [[yearSummary days_per_year] doubleValue];
   double yearOldTotalRemain= [[yearSummary amount_remain_with_pools] doubleValue];
   double yearTotalAmount= yearRemain;

   LeaveInfo* ifo= nil;
   CategoryRef* c= nil;
   Pool* pool= nil;
   Pool* residualLeave= [Storage poolOfArray:yearSummary.pools withInternalName:@"residualleave"];
   
   // (2) on the fly create residual leave pool, if necessary
   
   if (!residualLeave)
   {
      c= [Storage categoryForInternalName:@"residualleave" ofUser:owner];
         
      residualLeave= [[[Pool alloc] init] autorelease];
      residualLeave.category= c ? c.name : nil;
         
      residualLeave.pool= [NSNumber numberWithDouble:lastYearRemain];
      residualLeave.spent= [NSNumber numberWithDouble:0.0];
      residualLeave.expired= [NSNumber numberWithDouble:0.0];
      residualLeave.remain= [NSNumber numberWithDouble:0.0];
      residualLeave.earned= [NSNumber numberWithDouble:0.0];
      residualLeave.year= [NSNumber numberWithInt:theYear];
      residualLeave.internalName= @"residualleave";
         
      [yearSummary.pools addObject:residualLeave];
   }
   
   // (3) iterate pools, clear spent counters for ALL pools
   
   if (setLastYearRemain)
      residualLeave.pool= [NSNumber numberWithDouble:lastYearRemain >= 0.0 ? lastYearRemain : 0.0];
   
   [residualLeave checkExpiration];
   
   for (Pool* pool in yearSummary.pools)
   {
      pool.spent= [NSNumber numberWithDouble:0.0];
      pool.earned= [NSNumber numberWithDouble:0.0];
      pool.remain= [NSNumber numberWithDouble:pool.pool.doubleValue - pool.expired.doubleValue];
      
      yearTotalAmount += ([pool.pool doubleValue] - [pool.expired doubleValue]);
   }
   
   // (4) calculation loop - summarize durations + pool values
   
   for (int i = 0; i < [entries count]; i++)
   {
      ifo= (LeaveInfo*)[entries objectAtIndex:i];
      
      c= [Storage categoryForName:ifo.category ofUser:owner];
      
      if (c && ![c.affectCalculation boolValue])
         continue;
      
      pool= [Storage poolOfArray:yearSummary.pools withName:ifo.category];
      
      if (!pool && c)
         pool = [[Storage currentStorage] createPool:yearSummary withCategory:c];
      
      double duration= [ifo.duration doubleValue];
      
      if (pool)
      {
         // save in pool

         if (ifo.mode.intValue == lmSpend)
         {
            // spend mode. duration gets substracted from available amount.
            
            if (pool.remain.doubleValue <= 0.0)
            {
               // none available, also reset category on leave entry
               
               if (pool.expired.doubleValue > 0.0)
                  ifo.category = nil;
               
               yearSpent += duration;
               pool.remain= [NSNumber numberWithDouble:0.0];
            }
            else if (pool.remain.doubleValue < duration)
            {
               // split pool/annual leave
               
               double canSpend = pool.remain.doubleValue;
               pool.spent= [NSNumber numberWithDouble:pool.pool.doubleValue - pool.expired.doubleValue + pool.earned.doubleValue];
               pool.remain= [NSNumber numberWithDouble:0.0];
               yearSpent += (duration - canSpend);
            }
            else
            {
               // all from pool
               
               pool.spent= [NSNumber numberWithDouble:pool.spent.doubleValue + duration];
               pool.remain= [NSNumber numberWithDouble:pool.remain.doubleValue - duration];
            }
         }
         else
         {
            yearTotalAmount += duration;
            pool.earned = [NSNumber numberWithDouble:pool.earned.doubleValue + duration];
            pool.remain= [NSNumber numberWithDouble:pool.remain.doubleValue + duration];
         }
      }
      else
      {
         // save in year
         
        yearSpent += duration;
      }
   }
   
   yearRemain -= yearSpent;
   
   // (5) set new values for given year
   
   yearSummary.amount_spent = [NSNumber numberWithDouble:yearSpent];
   yearSummary.amount_remain = [NSNumber numberWithDouble:yearRemain];
   yearSummary.amount_with_pools = [NSNumber numberWithDouble:yearTotalAmount];
   yearSummary.amount_remain_with_pools = [NSNumber numberWithDouble:yearRemain + [[yearSummary.pools valueForKeyPath:@"@sum.remain"] doubleValue]];
   yearSummary.amount_spent_with_pools= [NSNumber numberWithDouble:yearSpent + [[yearSummary.pools valueForKeyPath:@"@sum.spent"] doubleValue]];
   
   // (6) display year notification

   [[NSNotificationCenter defaultCenter] postNotificationName:kYearChangedNotification object:self userInfo:[NSDictionary dictionaryWithObjectsAndKeys:yearSummary.year, @"year", nil]];

   // (7) trigger recalculation of following year, when values changed
       
   if ([yearSummary.amount_remain_with_pools doubleValue] != yearOldTotalRemain)
   {
      YearSummary* other= [[Storage currentStorage] getYear:theYear+1];

      if (other)
      {
         NSLog(@"Calculating next year after %d", theYear);
         [Calculation recalculateYearSummary:other withLastYearRemain:[yearSummary.amount_remain_with_pools doubleValue] setRemain:true completion:completionHandler];
      }
      else
      {
         NSLog(@"No following year after %d, done calculating", theYear);
         [[Storage currentStorage] saveYear:yearSummary completion:completionHandler];
      }
   }
   else if (completionHandler)
   {
      NSLog(@"Done calculating years");
      [[Storage currentStorage] saveYear:yearSummary completion:completionHandler];
   }

   return;
}

// *****************************************
// recalculate all years
// *****************************************

+(void)recalculateAllYears
{
   NSSortDescriptor* sortDescriptor = [NSSortDescriptor sortDescriptorWithKey:@"year" ascending:YES];
   
   [[SessionManager activeUser].years sortUsingDescriptors:[NSArray arrayWithObject:sortDescriptor]];
   
   for (YearSummary* sum in [SessionManager activeUser].years)
      [Calculation recalculateYearSummary:sum withLastYearRemain:0.0 setRemain:false completion:nil];
   
   return;
}

// *****************************************
// expireResidualLeave
// *****************************************

+(void)expireResidualLeave:(YearSummary*)year completion:(void(^)(BOOL success))completion
{
   Pool* pool = [Storage poolOfArray:year.pools withInternalName:@"residualleave"];
   
   // check if this year has expired residual leave. if true, trigger recalculation of year (leads to adjustment of days + saving)
   
   if (pool)
   {
      double expiredBefore = pool.expired.doubleValue;
      [pool checkExpiration];
      
      if (expiredBefore < pool.expired.doubleValue)
         [Calculation recalculateYearSummary:year withLastYearRemain:0.0 setRemain:false completion:completion];
      else if (completion)
         completion(YES);
   }
   else if (completion)
      completion(YES);
}

// ************************************************************
// calculateLeaveDuration
// ************************************************************

+(double) calculateLeaveDuration:(NSDate*)beginDate
                             _in:(NSDate*)endDate
                             _in:(bool)beginHalfDay 
                             _in:(bool)endHalfDay
                             _in:(bool)needsHourInput
                             _in:(bool)honorFreeDays
                             _in:(NSMutableArray*)timeTables
                             _in:(int)inMonth
                             _in:(int)year
{
   // only calculate duration if unit is days, not hours
   // #2.3 also don't calculate for unknown dates (we dont have start/end there)
   
   double duration= 0.0;
   NSDate* tmpStartDate = beginDate;
   NSDate* tmpEndDate = endDate;
   int freeDays = [Settings userSettingInt:skFreeDays];
   int week= 0;
   NSInteger lastWeekNumber= 0;
   NSCalendar* cal = [NSCalendar currentCalendar];
   
   // count days from beginDate to endDate, skipping all weekends
   
   if ([tmpStartDate compare:tmpEndDate] ==  NSOrderedDescending)
   {
      duration = 0.0;
   }
   else
   {
      if (![Settings userSettingInt:skUnit])
      {
         NSDateComponents* beginComps= [[NSCalendar currentCalendar] components:NSCalendarUnitMonth fromDate:beginDate];
         NSDateComponents* endComps= [[NSCalendar currentCalendar] components:NSCalendarUnitMonth fromDate:beginDate];
         int beginMonth= (int)beginComps.month;
         int endMonth= (int)endComps.month;
         
         // adjust first and last day, if only half days (only for DAY UNIT)
         
         if ((inMonth == na || inMonth == beginMonth)
             && beginHalfDay
             && (!honorFreeDays || ([Calculation isWorkday:beginDate freeDays:freeDays] && ![[PublicHoliday instance] isPublicHoliday:beginDate])))
            duration -= 0.5;
         
         if ((inMonth == na || inMonth == endMonth)
             && endHalfDay
             && (!honorFreeDays || ([Calculation isWorkday:endDate freeDays:freeDays] && ![[PublicHoliday instance] isPublicHoliday:endDate])))
            duration -= 0.5;
      }
      
      NSArray* days= [Calculation getDistinctDays:beginDate to:endDate inMonth:inMonth andYear:year];
      
      for (int i= 0; i < [days count]; i++)
      {
         NSDate* day= [days objectAtIndex:i];
         bool isWorkDay= !honorFreeDays || [Calculation isWorkday:day freeDays:freeDays];
         bool isPublicHoliday= honorFreeDays && [[PublicHoliday instance] isPublicHoliday:day];
         
         NSDateComponents* comps = [cal components:(NSCalendarUnitWeekOfYear|NSCalendarUnitDay|NSCalendarUnitMonth) fromDate:day];
         NSInteger weeknumber = [comps weekOfYear];
         NSString* freedayKey = [NSString stringWithFormat:@"%d%d", (int)comps.day, (int)comps.month];
         
         if (!lastWeekNumber)
            lastWeekNumber= weeknumber;
         
         if (weeknumber > lastWeekNumber)
         {
            week++;
            lastWeekNumber= weeknumber;
         }
         
         if (isWorkDay && !isPublicHoliday && ![[Storage freedaysList] objectForKey:freedayKey])
         {
            if (!needsHourInput)
               duration += 1.0;
            else
               duration += [Calculation hoursForDay:day andTimeTables:timeTables andWeek:week];
         }
      }
   }
   
   return duration;
}

@end
