//************************************************************
// OverviewCell.h
// Holiday
//************************************************************
// Created by Patrick Fial on 08.06.2010
// Copyright 2010-2015 Patrick Fial. All rights reserved.
//************************************************************

//************************************************************
// includes
//************************************************************

#import <UIKit/UIKit.h>

@class LeaveInfo;

//************************************************************
// class OverviewCell
//************************************************************

@interface OverviewCell : UITableViewCell

@property (nonatomic, retain) IBOutlet UILabel* dateText;
@property (nonatomic, retain) IBOutlet UILabel* titleText;
@property (nonatomic, retain) IBOutlet UILabel* categoryText;
@property (nonatomic, retain) IBOutlet UILabel* ownerLabel;

- (void) fill:(LeaveInfo *)info;

@end
