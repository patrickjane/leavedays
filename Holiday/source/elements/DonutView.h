//************************************************************
// DonutView.h
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
// class DonutView
//************************************************************

@interface DonutView : UIView

-(void)update:(double)days withUsed:(double)used andRemain:(double)remain;

@property (nonatomic, retain) UIColor* colorSpent;
@property (nonatomic, retain) UIColor* colorRemain;
@property (nonatomic, retain) UIColor* colorResidual;
@property (nonatomic, retain) UIColor* colorOverspent;
@property (nonatomic, retain) UIColor* colorUnused;

@end
