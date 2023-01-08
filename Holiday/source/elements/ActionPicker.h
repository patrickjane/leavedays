//************************************************************
// ActionPicker.h
// Holiday
//************************************************************
// Created by Patrick Fial on 19.05.2017
// Copyright 2017-2017 Patrick Fial. All rights reserved.
//************************************************************

//************************************************************
// includes
//************************************************************

#import <UIKit/UIKit.h>

//************************************************************
// class ActionPicker
//************************************************************

@interface ActionPicker : UIView<UIPickerViewDelegate, UIPickerViewDataSource>

@property (nonatomic, retain) NSString* currentSelection;
@property (nonatomic, assign) BOOL saveOnDismiss;
@property (nonatomic, retain) NSArray* items;
@property (nonatomic, retain) UIView* pickerContainer;
@property (copy) void(^valueChanged)(NSString*);


-(id)initWithValues:(NSArray*)values andSelection:(id)selection;
-(void)show;
-(void)dismiss;


@end
