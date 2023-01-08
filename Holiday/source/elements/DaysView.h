//************************************************************
// DaysView.h
// Holiday
//************************************************************
// Created by Patrick Fial on 24.07.2018
// Copyright 2018-2018 Patrick Fial. All rights reserved.
//************************************************************

//************************************************************
// includes
//************************************************************

#import <Foundation/Foundation.h>

//************************************************************
// class YearChart
//************************************************************

@interface DaysView : UIView

@property (nonatomic, retain) NSString* maxLengthAmount;
@property (nonatomic, retain) NSString* maxLengthSpent;
@property (nonatomic, retain) NSString* maxLengthRemain;
@property (nonatomic, retain) NSString* maxLengthEarned;

@property (nonatomic, assign) BOOL modeShort;

-(void)setValues:(double)amount and:(double)spent and:(double)remain and:(double)earned;
@end
