//************************************************************
// LeavePage.h
// Holiday
//************************************************************
// Created by Patrick Fial on 01.02.15.
// Copyright 2015-2015 Patrick Fial. All rights reserved.
//************************************************************

//************************************************************
// includes
//************************************************************

#import <UIKit/UIKit.h>

#import "BasePage.h"

//************************************************************
// LeavePage
//************************************************************

enum LeaveListDisplayMode
{
   lldmLeave,
   lldmMonthly
};

@interface MonthSummaries : NSObject

@property (nonatomic, retain) NSMutableArray* items;
@property (nonatomic, assign) int year;
@property (nonatomic, assign) int month;

-(id)init;
+(MonthSummaries*)summariesOfYear:(int)year andMonth:(int)month;

@end

@interface MonthSummary : NSObject

@property (nonatomic, retain) NSString* category;
@property (nonatomic, assign) double amount;
@property (nonatomic, assign) double spent;
@property (nonatomic, assign) double earned;
@property (nonatomic, retain) NSString* unitTitle;

@end

@interface LeavePage : BasePage<UITableViewDataSource, UITableViewDelegate>
{
   int displayMode;
}

@property (nonatomic, retain) NSArray* monthItems;
@property (nonatomic, retain) NSDictionary* items;
@property (nonatomic, retain) NSMutableArray* keys;
@property (nonatomic, retain) IBOutlet UITableView* tableView;

-(NSString*)pageTitle;

@end
