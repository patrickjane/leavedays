//************************************************************
// TimeTableEdit.h
// Holiday
//************************************************************
// Created by Patrick Fial on 24.10.2011
// Copyright 2011-2015 Patrick Fial. All rights reserved.
//************************************************************

//************************************************************
// includes
//************************************************************

#import <UIKit/UIKit.h>
#import "Service.h"

@class Timetable;

//************************************************************
// class TimeTableEdit
//************************************************************

@interface TimeTableEdit : UITableViewController <UIAlertViewDelegate,TextInputCellDelegate, UITextFieldDelegate>

@property (nonatomic, retain) Timetable* timeTable;
@property (nonatomic, retain) NSArray* days;
@property (nonatomic, retain) NSIndexPath* editedIndex;

-(int)typeForIndex:(NSIndexPath *)idx;

@end
