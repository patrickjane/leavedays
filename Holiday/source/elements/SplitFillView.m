//************************************************************
// SplitFillView.m
// Holiday
//************************************************************
// Created by Patrick Fial on 26.01.19
// Copyright 2019-2019 Patrick Fial. All rights reserved.
//************************************************************

//************************************************************
// includes
//************************************************************

#import "SplitFillView.h"

@implementation SpitFillView
@synthesize backgroundColor2;

//************************************************************
// initWithFrame
//************************************************************

-(id)initWithFrame:(CGRect)frame
{
   self= [super initWithFrame:frame];
   
   if (self)
   {
      self.backgroundColor2 = nil;
   }
   
   return self;
}

//************************************************************
// initWithCoder
//************************************************************

-(void)drawRect:(CGRect)rect
{
   if (self.backgroundColor2)
   {
      CGContextRef ctx = UIGraphicsGetCurrentContext();
      
      CGContextSetFillColorWithColor(ctx, self.backgroundColor2.CGColor);
      CGContextMoveToPoint(ctx, rect.origin.x, rect.origin.y);
      CGContextAddLineToPoint(ctx, rect.origin.x, rect.origin.y + rect.size.height);
      CGContextAddLineToPoint(ctx, rect.origin.x + rect.size.width, rect.origin.y);
      CGContextFillPath(ctx);
   }
}

@end
