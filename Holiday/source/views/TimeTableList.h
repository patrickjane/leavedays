//************************************************************
// TimeTableList.h
// Holiday
//************************************************************
// Created by Patrick Fial on 30.08.2011
// Copyright 2011-2015 Patrick Fial. All rights reserved.
//************************************************************

//************************************************************
// includes
//************************************************************

#import <UIKit/UIKit.h>
#import <CoreData/CoreData.h>

@class Timetable;

//************************************************************
// TimeTableList
//************************************************************

@interface TimeTableList : UITableViewController 

@property (nonatomic, retain) Timetable* selection;
@property (nonatomic, retain) NSArray* menuItems;

-(void) addTimeTable;

@end
