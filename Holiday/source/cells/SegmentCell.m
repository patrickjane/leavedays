//************************************************************
// SegmentCell.m
// Holiday
//************************************************************
// Created by Patrick Fial on 05.01.2012
// Copyright 2012-2015 Patrick Fial. All rights reserved.
//************************************************************

//************************************************************
// includes
//************************************************************

#import "SegmentCell.h"

//************************************************************
// class SegmentCell
//************************************************************

@implementation SegmentCell

@synthesize label;
@synthesize segment;

-(IBAction)onValueChanged:(id)sender
{
   UISegmentedControl* aSegment= sender;
   
   if (self.valueChanged)
      self.valueChanged((int)aSegment.selectedSegmentIndex);
}

@end
