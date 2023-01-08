//************************************************************
// AnnualLeaveListController.h
// Annual Leave iPad
//************************************************************
// Created by Patrick Fial on 14.08.11.
// Copyright 2011-2014 Patrick Fial. All rights reserved.
//************************************************************

//************************************************************
// includes
//************************************************************

#import <UIKit/UIKit.h>

//************************************************************
// class AnnualLeaveListController
//************************************************************

@interface AnnualLeaveListController : UITableViewController

@property (nonatomic, retain) NSArray* items;
@property (nonatomic, retain) NSArray* yearList;
@property (nonatomic, retain) NSString* selectedString;

@property (nonatomic, assign) int isModal;

-(id)initWithStyle:(UITableViewStyle)style andYears:(NSArray*)years;
-(void)addYear:(id)sender;
-(void)dismiss:(id)sender;

@end
