//************************************************************
// ActionDate.h
// Holiday
//************************************************************
// Created by Patrick Fial on 31.12.2014
// Copyright 2014-2014 Patrick Fial. All rights reserved.
//************************************************************

//************************************************************
// includes
//************************************************************

#import <UIKit/UIKit.h>

//************************************************************
// class ActionPicker
//************************************************************

@interface ActionDate : UIView<UITableViewDelegate, UITableViewDataSource>
{
   double totalHeight;
}

@property (nonatomic, retain) UIView* pickerContainer;
@property (nonatomic, retain) UIDatePicker* datePicker;
@property (copy) void(^valueChanged)(NSDate*, bool);
@property (nonatomic, assign) int isHalfDay;
@property (nonatomic, retain) NSDate* date;


-(id)initWithDate:(NSDate*)date;
-(id)initWithDate:(NSDate*)date andHalfDay:(int)halfDay;
-(void)show;
-(void)dismiss;


@end
