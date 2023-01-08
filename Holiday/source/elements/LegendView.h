//************************************************************
// LegendView.h
// Holiday
//************************************************************
// Created by Patrick Fial on 10.03.2019
// Copyright 2019-2019 Patrick Fial. All rights reserved.
//************************************************************

//************************************************************
// includes
//************************************************************

#import <UIKit/UIKit.h>

//************************************************************
// class LegendView
//************************************************************

@interface LegendView : UIView
@property (nonatomic, assign) double legendHeight;

-(double)addLegendItem:(NSString*)title color:(UIColor*)color offset:(double)offset otherColor:(UIColor*)color2 skipSpacing:(BOOL)skipSpacing;
@end
