//************************************************************
// InsetField.m
// Holiday
//************************************************************
// Created by Patrick Fial on 03.10.2015
// Copyright 2015-2015 Patrick Fial. All rights reserved.
//************************************************************

//************************************************************
// includes
//************************************************************

#import "InsetField.h"

//************************************************************
// class InsetField
//************************************************************

@implementation InsetField

//************************************************************
// drawRect
//************************************************************

- (void)drawRect:(CGRect)rect
{
    // Drawing code
   
   CGContextRef context = UIGraphicsGetCurrentContext();
   
   // draw separator line
   
   CGContextSetFillColorWithColor(context, SECONDDETAILCOLOR.CGColor);
   CGContextFillRect(context, CGRectMake(0.0, 0.0, 3.0, rect.size.height));
}

//************************************************************
// textRectForBounds
//************************************************************

- (CGRect)textRectForBounds:(CGRect)bounds
{
   // placeholder position
   
   return CGRectInset(bounds, 5, 0);
}

//************************************************************
// editingRectForBounds
//************************************************************

- (CGRect)editingRectForBounds:(CGRect)bounds
{
   // text position
   
   return CGRectInset(bounds, 5, 0);
}

@end
