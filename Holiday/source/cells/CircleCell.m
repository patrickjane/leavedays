//
//  CircleCell.m
//  Annual leave
//
//  Created by Patrick Fial on 21.10.11.
//  Copyright (c) 2011 Patrick Fial. All rights reserved.
//

#import "CircleCell.h"

@implementation CircleCell

@synthesize circleView;
@synthesize detailText;
@synthesize mainText;

- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier
{
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self) {
        // Initialization code
    }
    return self;
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated
{
    [super setSelected:selected animated:animated];

    // Configure the view for the selected state
}

@end
