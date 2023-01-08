//************************************************************
// LeaveDialog.h
// Annual Leave iPad
//************************************************************
// Created by Patrick Fial on 12.01.2012
// Copyright 2012-2012 Patrick Fial. All rights reserved.
//************************************************************

//************************************************************
// includes
//************************************************************

#import <UIKit/UIKit.h>
#import <MessageUI/MessageUI.h>
#import <MessageUI/MFMailComposeViewController.h>

#import "Service.h"
#import "SwitchCell.h"
#import "CategoryOverviewController.h"
#import "LocationController.h"

//************************************************************
// enums
//************************************************************

enum ActionSheetIndex
{
   aisOptions       = 0,
   aisTimetable     = 1,
   aisLeaveYear     = 2,
   aisCategory      = 4,
   aisOwner         = 8
};

enum RowDefs
{
   rowTitle,                // 0
   rowBegin,                // 1
   rowEnd,                  // 2
   nSectFirst= rowEnd,      // 2

   rowDuration,             // 3
   rowEarnSpend,            // 4
   nSectSec= rowEarnSpend,  // 4
   
   nOptFirst,               // 5
   rowCategory = nOptFirst, // 5
   rowTimetable,            // 6
   rowYear,                 // 7
   rowLocation,             // 8
   rowState,                // 9
   rowComment,              // 10
   rowMail,                 // 11
   rowUnknown,              // 12
   rowCalc,                 // 13
//   rowOwner,                // 14
   
   cntRows,
   
   addOption
};

@class RootViewController;
@class Timetable;
@class YearSummary;
@class LeaveInfo;

//************************************************************
// class AddPage
//************************************************************

@interface LeaveDialog : UITableViewController <LocationControllerDelegate,UIPopoverControllerDelegate,CategoryOverviewControllerDelegate,TextInputCellDelegate, UITextFieldDelegate, UITextViewDelegate, UIAlertViewDelegate, MFMailComposeViewControllerDelegate>
{
   double duration;
   bool beginHalfDay;
   bool endHalfDay;
   bool editBegin;
   bool sendMail;
   bool initial;
   bool needsHourInput;
   bool isUnknownDate;
   bool calculateDuration;
   bool durationChanged;
   int status;
   int leaveYear;
   LeaveInfo* leaveInfo;
   UITextField* activeTextField;
   UITextView* activeTextView;
   
   int enabledOptions[cntRows];
}

@property (nonatomic, retain) NSMutableArray* timeTables;
@property (nonatomic, retain) RootViewController* rootViewController;
@property (nonatomic, retain) NSDate* beginDate;
@property (nonatomic, retain) NSDate* endDate;
@property (nonatomic, retain) LeaveInfo* leaveInfo;
@property (nonatomic, retain) NSString* leaveTitle;
@property (nonatomic, retain) NSString* comment;
@property (nonatomic, retain) NSArray* availableYears;
@property (nonatomic, retain) NSString* categoryName;
@property (nonatomic, retain) NSIndexPath* editedIndex;
@property (nonatomic, retain) NSString* owner;
@property (nonatomic, retain) NSDictionary* location;
@property (nonatomic, assign) int leaveYear;
@property (nonatomic, assign) int leaveMode;
@property (nonatomic, copy) void (^completionHandler)(void);

-(void) fill;
-(bool) loadRecord;

-(void) cancel;
-(void) saveRecord;
-(void) deleteRecord:(void (^)(BOOL success))completionHandler;
-(void) setValues;

-(void)closeDialog;

-(void) recalculate;
-(void) sendMailWithInfo:(LeaveInfo*)info;

- (int) typeForIndex:(NSIndexPath*)idx;

-(NSString*)cityName;

-(int)nOptions;
-(int)optionIndex:(NSIndexPath*)index;
-(int)optionIndexForRow:(int)row enabled:(BOOL)enabled;
-(NSIndexPath*)indexPathForOption:(int)index;
-(void)removeDataForOption:(int)option;

-(void)migrateEntry:(LeaveInfo*)info;
-(void)leaveModeChanged:(id)sender;

@end
