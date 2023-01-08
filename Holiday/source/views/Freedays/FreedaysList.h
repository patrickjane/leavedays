//************************************************************
// FreedaysList.h
// Holiday
//************************************************************
// Created by Patrick Fial on 28.11.202
// Copyright 202-202 Patrick Fial. All rights reserved.
//************************************************************

//************************************************************
// includes
//************************************************************

#import <UIKit/UIKit.h>

@class Freeday;

@interface FreedaysList : UITableViewController

@property (nonatomic, retain) NSArray* items;

-(void)addFreeday;
-(NSString*)dateStringForFreeday:(Freeday*)freeday;

@end
