//************************************************************
// TimeTableSelection.h
// Holiday
//************************************************************
// Created by Patrick Fial on 23.10.2011
// Copyright 2011-2015 Patrick Fial. All rights reserved.
//************************************************************

//************************************************************
// includes
//************************************************************

#import <UIKit/UIKit.h>
#import "TimeTableList.h"

//************************************************************
// class TimeTableSelection
//************************************************************

@interface TimeTableSelection : UITableViewController

@property (nonatomic, retain) NSMutableArray* timeTables;
@property (nonatomic, retain) NSIndexPath* editedIndex;

-(void) addRecord;
-(void)showTimeTableSheet:(void (^)(UIAlertController* actionSheet, Timetable* tt))processor;

@end
