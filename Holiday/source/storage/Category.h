//************************************************************
// Category.h
// Holliday
//************************************************************
// Created by Patrick Fial on 06.01.12.
// Copyright 2012-2013 Patrick Fial. All rights reserved.
//************************************************************

//************************************************************
// includes
//************************************************************

#import "Storage.h"

@interface CategoryRef : NSObject<NSCoding>

@property (nonatomic, retain) NSNumber * affectCalculation;
@property (nonatomic, retain) NSString * color;
@property (nonatomic, retain) NSNumber * deletable;
@property (nonatomic, retain) NSDate * inssp;
@property (nonatomic, retain) NSString * internalName;
@property (nonatomic, retain) NSString * name;
@property (nonatomic, retain) NSNumber * savedAsHours;
@property (nonatomic, retain) NSNumber * sumMonthly;
@property (nonatomic, retain) NSNumber * honorFreeDays;
@property (nonatomic, retain) NSString * userInfo;
@property (nonatomic, retain) NSString * userid;
@property (nonatomic, assign) int __version;

@end
