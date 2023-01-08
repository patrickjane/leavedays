//************************************************************
// CsvCreator.h
// Holiday
//************************************************************
// Created by Patrick Fial on 08.03.2019.
// Copyright 2019-2019 Patrick Fial. All rights reserved.
//************************************************************

//************************************************************
// includes
//************************************************************

#import <UIKit/UIKit.h>
#import "Service.h"
#import "TextCell.h"
#import "SwitchCell.h"
#import "CategoryOverviewController.h"

//************************************************************
// class CsvCreator
//************************************************************

@interface CsvCreator : UITableViewController<UITextFieldDelegate, CategoryOverviewControllerDelegate, TextInputCellDelegate>
{
   int options;
   int leaveYear;
}

@property (nonatomic, retain) NSMutableArray* excludedCategories;
@property (nonatomic, retain) NSIndexPath* editedIndex;
@property (nonatomic, retain) NSString* documentTitle;
@property (nonatomic, retain) NSString* fileName;
@property (nonatomic, retain) NSData* csvData;

-(void)startExport;
-(BOOL)createCsv;

@end
