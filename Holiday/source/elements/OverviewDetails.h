//************************************************************
// OverviewDetails.h
// Holiday
//************************************************************
// Created by Patrick Fial on 24.07.2018
// Copyright 2018-2018 Patrick Fial. All rights reserved.
//************************************************************

//************************************************************
// includes
//************************************************************

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import "LegendView.h"

//************************************************************
// class YearChart
//************************************************************

@interface OverviewDetails : UIView<UITableViewDataSource, UITableViewDelegate>

@property (nonatomic, retain) UITableView* tableView;
@property (nonatomic, retain) NSMutableArray* tableData;
@property (nonatomic, retain) LegendView* legendView;
@property (nonatomic, retain) UIView* legendSpacer;

@property (nonatomic, retain) NSString* maxLengthAmount;
@property (nonatomic, retain) NSString* maxLengthSpent;
@property (nonatomic, retain) NSString* maxLengthRemain;
@property (nonatomic, retain) NSString* maxLengthEarned;

-(void)reload;

@end
