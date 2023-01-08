//
//  DateCell.m
//  Holiday
//
//  Created by Winston Churchill on 26.11.20.
//  Copyright © 2020 Patrick Fial. All rights reserved.
//

#import "DateCell.h"

@implementation DateCell

@synthesize label;
@synthesize picker;
@synthesize button;


- (IBAction) onValueChanged:(id)sender
{
   if (self.valueChanged)
      self.valueChanged(self.picker.date);
}

- (void)awakeFromNib {
   self.button.layer.cornerRadius = 5;
   self.button.layer.masksToBounds=YES;

    [super awakeFromNib];
    // Initialization code
}

-(IBAction)onButtonPressed:(id)sender
{
   if (self.halfDayValueChanged)
      self.halfDayValueChanged();
}

@end
