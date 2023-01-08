//************************************************************
// Pool.h
// Holliday
//************************************************************
// Created by Patrick Fial on 06.01.12.
// Copyright 2012-2014 Patrick Fial. All rights reserved.
//************************************************************

//************************************************************
// includes
//************************************************************

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class YearSummary;

//************************************************************
// class Pool
//************************************************************

@interface Pool : NSObject<NSCoding>

@property (nonatomic, assign) int __version;
@property (nonatomic, retain) NSString * category;
@property (nonatomic, retain) NSNumber * expired;
@property (nonatomic, retain) NSString * internalName;
@property (nonatomic, retain) NSNumber * pool;
@property (nonatomic, retain) NSNumber * remain;
@property (nonatomic, retain) NSNumber * spent;
@property (nonatomic, retain) NSNumber * earned;
@property (nonatomic, retain) NSNumber * year;
@property (nonatomic, retain) NSString * yearId;
@property (nonatomic, retain) NSString * uuid;
@property (nonatomic, retain) NSString * userid;

// functions

-(BOOL)checkExpiration;

@end
