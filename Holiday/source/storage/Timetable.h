//************************************************************
// Timetable.h
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
// class Timetable
//************************************************************

@interface Timetable : NSObject<NSCoding>

@property (nonatomic, retain) NSNumber * day_0;
@property (nonatomic, retain) NSNumber * day_1;
@property (nonatomic, retain) NSNumber * day_2;
@property (nonatomic, retain) NSNumber * day_3;
@property (nonatomic, retain) NSNumber * day_4;
@property (nonatomic, retain) NSNumber * day_5;
@property (nonatomic, retain) NSNumber * day_6;
@property (nonatomic, retain) NSNumber * hours_total;
@property (nonatomic, retain) NSString * internalname;
@property (nonatomic, retain) NSString * name;
@property (nonatomic, retain) NSString * uuid;
@property (nonatomic, retain) NSString * userid;
@property (nonatomic, retain) NSString * userInfo;

@end
