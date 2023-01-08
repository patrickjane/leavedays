//
//  CircleView.m
//  Annual leave
//
//  Created by Patrick Fial on 16.10.11.
//  Copyright 2011 Patrick Fial. All rights reserved.
//

#import "CircleView.h"

@implementation CircleView
@synthesize color;

// ************************************************************
// initWithFrame
// ************************************************************

- (id)initWithFrame:(CGRect)frame
{
   self = [super initWithFrame:frame];
   
   if (self) 
   {
      // Initialization code
      
      self.color= nil;
   }
   
   return self;
}

// ************************************************************
// drawRect
// ************************************************************

- (void)drawRect:(CGRect)rect
{
   // Only override drawRect: if you perform custom drawing.
   // An empty implementation adversely affects performance during animation.
   
   CGContextRef context= UIGraphicsGetCurrentContext();
   
   CGContextSetFillColorWithColor(context, self.color);
   CGContextSetAlpha(context, 0.5);
   CGContextFillEllipseInRect(context, CGRectMake(10.0, 10.0, 10.0, 10.0));
   
   CGContextSetStrokeColorWithColor(context, self.color);
   CGContextStrokeEllipseInRect(context, CGRectMake(10.0, 10.0, 10.0, 10.0));
}


@end
