//************************************************************
// ActionPicker.h
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
// class CheckButton
//************************************************************

@interface CheckButton : UIButton

@property (nonatomic, retain) UIImageView* checkmark;

-(void)setChecked:(BOOL)checked;
@end

//************************************************************
// class ActionPicker
//************************************************************

@interface ActionTable : UIView

@property (copy) void(^selectionChanged)(bitarray*);

-(id)initWithValues:(NSArray*)values andSelection:(bitarray*)selection;

-(void)show;
-(void)dismiss;

@end
