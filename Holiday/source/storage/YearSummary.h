//************************************************************
// YearSummary.h
// Holliday
//************************************************************
// Created by Patrick Fial on 06.01.12.
// Copyright 2012-2014 Patrick Fial. All rights reserved.
//************************************************************

//************************************************************
// includes
//************************************************************

#import "Storage.h"

//************************************************************
// class YearSummary
//************************************************************

@interface YearSummary : NSObject<NSCoding>

@property (nonatomic, retain) NSNumber * amount_remain;
@property (nonatomic, retain) NSNumber * amount_remain_with_pools;
@property (nonatomic, retain) NSNumber * amount_spent;
@property (nonatomic, retain) NSNumber * amount_spent_with_pools;
@property (nonatomic, retain) NSNumber * amount_with_pools;
@property (nonatomic, retain) NSNumber * days_per_year;
@property (nonatomic, retain) NSNumber * year;
@property (nonatomic, retain) NSDate * remain_expiration;
@property (nonatomic, retain) NSString * userid;
@property (nonatomic, retain) NSString * userInfo;
@property (nonatomic, retain) NSString * uuid;
@property (nonatomic, retain) NSMutableArray * pools;

@end
