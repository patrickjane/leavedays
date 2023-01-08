//************************************************************
// YearChart.h
// Holiday
//************************************************************
// Created by Patrick Fial on 18.01.2015
// Copyright 2015-2015 Patrick Fial. All rights reserved.
//************************************************************

//************************************************************
// includes
//************************************************************

#import <Foundation/Foundation.h>

//************************************************************
// class YearChart
//************************************************************

@interface YearChart : UIView
{
   yeararray days;
   double yearSpent;
}

-(void)setDays:(yeararray*)aDays andYearUserd:(double)yearSpent;

@property (nonatomic, retain) UIColor* barColor;
@property (nonatomic, assign) int thisYear;

@end
