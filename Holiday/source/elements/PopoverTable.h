//************************************************************
// PopoverTable.h
// Holiday
//************************************************************
// Created by Patrick Fial on 01.07.2015
// Copyright 2015-2015 Patrick Fial. All rights reserved.
//************************************************************

//************************************************************
// includes
//************************************************************

#import <UIKit/UIKit.h>

//************************************************************
// definitions
//************************************************************

enum Directions
{
   dirLeft,
   dirRight,
   dirTop,
   dirBottom
};

//************************************************************
// class PopoverTable
//************************************************************

@interface PopoverTable : UIView<UITableViewDataSource, UITableViewDelegate>

-(id)initWithValues:(NSArray*)aValues atPoint:(CGPoint)point inFrame:(CGRect)frame;
-(void)showInView:(UIView*)aView;
-(void)dismiss;

@property (copy) void(^itemSelected)(int index);

@end
