//************************************************************
// CategoryEdit.h
// Annual Leave iPad
//************************************************************
// Created by Patrick Fial on 29.03.11.
// Copyright 2011-2014 Patrick Fial. All rights reserved.
//************************************************************

//************************************************************
// includes
//************************************************************

#import <UIKit/UIKit.h>
#import "SwitchCell.h"
#import "TextCell.h"
#import "SegmentCell.h"
#import <CoreData/CoreData.h>
#import "Service.h"

#import "ColorPickerController.h"

@class CategoryOverviewController;
@class YearSummary;
@class CategoryRef;
@class LeaveInfo;

//************************************************************
// class CategoryEdit
//************************************************************

@interface CategoryEdit : UITableViewController<HRColorPickerViewControllerDelegate,UITextFieldDelegate, TextInputCellDelegate>
{
   bool deletable;
   bool affectCalculation;
   bool sumMonthly;
   bool savedAsHours;
   bool honorFreeDays;

   bool alertForSave;
}

@property (nonatomic, retain) CategoryOverviewController* parent;
@property (nonatomic, retain) NSString* categoryName;
@property (nonatomic, retain) CategoryRef* info;
@property (nonatomic, retain) YearSummary* yearSummary;
@property (nonatomic, retain) UIColor* color;

-(void)fill:(CategoryRef*)category;
-(void)save;
-(void)save:(bool)delete;

@end
