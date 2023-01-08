//************************************************************
// FreedayEdit.h
// Holiday
//************************************************************
// Created by Patrick Fial on 28.11.202
// Copyright 202-202 Patrick Fial. All rights reserved.
//************************************************************

//************************************************************
// includes
//************************************************************

#import <UIKit/UIKit.h>
#import "Service.h"

@class Freeday;

@interface FreedayEdit : UITableViewController <UIAlertViewDelegate,TextInputCellDelegate, UITextFieldDelegate>

@property (nonatomic, retain) Freeday* day;
@property (nonatomic, retain) NSIndexPath* editedIndex;

-(NSString*)dateStringForFreeday:(Freeday*)freeday;

@end

