//
//  TextCell.h
//  Annual Leave iPad
//
//  Created by Patrick Fial on 05.01.12.
//  Copyright (c) 2012 Informationsdesign AG. All rights reserved.
//

#import <UIKit/UIKit.h>

#import "DaysView.h"

@interface VacationDaysCell : UITableViewCell

@property (nonatomic, retain) IBOutlet UILabel* labelTitle;
@property (nonatomic, retain) IBOutlet DaysView* daysView;

@end
