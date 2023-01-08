//************************************************************
// YearInfoList.h
// Holiday
//************************************************************
// Created by Patrick Fial on 28.12.2014
// Copyright 2014-2014 Patrick Fial. All rights reserved.
//************************************************************

//************************************************************
// includes
//************************************************************

#import <UIKit/UIKit.h>

//************************************************************
// class YearInfoList
//************************************************************

@interface YearInfoList : UIView
{
   int tappedRow;
   int tappedCol;
   int highlightCell;
   
   int displayDays;
}

-(void)clearDayDisplay;

@end
