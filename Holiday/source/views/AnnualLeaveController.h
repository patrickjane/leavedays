//************************************************************
// AnnualLeaveController.h
// Annual Leave iPad
//************************************************************
// Created by Patrick Fial on 14.08.11.
// Copyright 2011-2014 Patrick Fial. All rights reserved.
//************************************************************

//************************************************************
// includes
//************************************************************

#import <UIKit/UIKit.h>
#import "Service.h"
#import "CategoryOverviewController.h"

@class YearSummary;
@class CategoryRef;

//************************************************************
// class AnnualLeaveController
//************************************************************

@interface AnnualLeaveController : UIViewController <UITableViewDataSource, UITableViewDelegate, UITextFieldDelegate, TextInputCellDelegate, CategoryOverviewControllerDelegate>
{
   int noChanges;
}

@property (nonatomic, retain) UITableView* tableView;
@property (nonatomic, retain) UIToolbar* toolBar;
@property (nonatomic, retain) NSIndexPath* editedIndex;
@property (nonatomic, retain) YearSummary* myYear;
@property (nonatomic, assign) int wizardMode;

- (id)init;
- (void)loadView;

- (BOOL)addPool;

-(void)setNewCategory:(CategoryRef*)newString;
-(int)typeForIndex:(NSIndexPath *)idx;

@end
