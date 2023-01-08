//
//  CircleCell.h
//  Annual leave
//
//  Created by Patrick Fial on 21.10.11.
//  Copyright (c) 2011 Patrick Fial. All rights reserved.
//

#import <UIKit/UIKit.h>

@class CircleView;

@interface CircleCell : UITableViewCell
{
   IBOutlet UILabel* mainText;
   IBOutlet UILabel* detailText;   // R: 82 G: 102 B: 145
   IBOutlet CircleView* circleView;
}

@property (nonatomic, retain) IBOutlet CircleView* circleView;
@property (nonatomic, retain) UILabel* mainText;
@property (nonatomic, retain) UILabel* detailText;

@end
