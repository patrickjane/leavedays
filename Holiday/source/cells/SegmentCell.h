//************************************************************
// SegmentCell.h
// Holiday
//************************************************************
// Created by Patrick Fial on 05.01.2012
// Copyright 2012-2015 Patrick Fial. All rights reserved.
//************************************************************

//************************************************************
// includes
//************************************************************

#import <UIKit/UIKit.h>

//************************************************************
// class SegmentCell
//************************************************************

@interface SegmentCell : UITableViewCell

@property (nonatomic, retain) IBOutlet UILabel* label;
@property (nonatomic, retain) IBOutlet UISegmentedControl* segment;
@property (copy) void(^valueChanged)(int);

-(IBAction)onValueChanged:(id)sender;

@end
