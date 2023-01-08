//************************************************************
// SwitchCell.h
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
// class SwitchCell
//************************************************************

@interface SwitchCell : UITableViewCell

@property (nonatomic, retain) IBOutlet UILabel* label;
@property (nonatomic, retain) IBOutlet UISwitch* vSwitch;
@property (copy) void(^valueChanged)(BOOL);

-(IBAction)onValueChanged:(id)sender;

@end
