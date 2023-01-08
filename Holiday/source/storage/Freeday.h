//************************************************************
// Freeday.m
// Holliday
//************************************************************
// Created by Patrick Fial on 28.11.20.
// Copyright 2020-2020 Patrick Fial. All rights reserved.
//************************************************************

//************************************************************
// includes
//************************************************************

#import <Foundation/Foundation.h>

@interface Freeday : NSObject<NSCoding>
@property (nonatomic, retain) NSNumber* day;
@property (nonatomic, retain) NSNumber* month;
@property (nonatomic, retain) NSString* title;
@property (nonatomic, retain) NSString* uuid;
@property (nonatomic, retain) NSString* userid;
@property (nonatomic, retain) NSString* userInfo;
@end
