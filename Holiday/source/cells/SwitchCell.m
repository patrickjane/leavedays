//************************************************************
// SwitchCell.m
// Holiday
//************************************************************
// Created by Patrick Fial on 05.01.2012
// Copyright 2012-2015 Patrick Fial. All rights reserved.
//************************************************************

//************************************************************
// includes
//************************************************************

#import "SwitchCell.h"

//************************************************************
// class SwitchCell
//************************************************************

@implementation SwitchCell

@synthesize vSwitch;
@synthesize label;

//************************************************************
// initWithStyle
//************************************************************

- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier
{
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
   
    if (self)
    {
    }
    return self;
}

//************************************************************
// onValueChanged
//************************************************************

- (IBAction) onValueChanged:(id)sender
{
   if (self.valueChanged)
      self.valueChanged(self.vSwitch.on);
}


@end
