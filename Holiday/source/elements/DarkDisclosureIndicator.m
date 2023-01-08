//
//  DarkDisclosureIndicator.m
//  Holiday
//
//  Created by Winston Churchill on 28.11.20.
//  Copyright © 2020 Patrick Fial. All rights reserved.
//

#import "DarkDisclosureIndicator.h"

#define PADDING 4.f //give the canvas some padding so the ends and joints of the lines can be drawn with a mitered joint
#define ACCESSORY_WIDTH 13.f
#define ACCESSORY_HEIGHT 18.f

@implementation DarkDisclosureIndicator

-(id)initWithFrame:(CGRect)frame
{
   self = [super initWithFrame:frame];
   
   if (self)
   {
      self.color = [UIColor grayColor];
      self.backgroundColor = [UIColor clearColor];
   }
   
   return self;
}

-(id)initWithFrame:(CGRect)frame andColor:(UIColor*)color
{
   self = [super initWithFrame:frame];
   
   if (self)
   {
      self.color = color;
      self.backgroundColor = [UIColor clearColor];
   }
   
   return self;
}

+(DarkDisclosureIndicator*)indicatorWithColor:(UIColor*)color forCell:(UITableViewCell*)cell
{
   CGRect frame = CGRectMake(cell.frame.size.width - ACCESSORY_WIDTH - PADDING, cell.frame.size.height/2 - ACCESSORY_HEIGHT/2, ACCESSORY_WIDTH, ACCESSORY_HEIGHT);
   DarkDisclosureIndicator* res = [[[DarkDisclosureIndicator alloc] initWithFrame:frame] autorelease];
   
   return res;
}

- (void)drawRect:(CGRect)rect
{
    CGContextRef context = UIGraphicsGetCurrentContext();

    CGContextSetStrokeColorWithColor(context, self.color.CGColor);
    CGContextSetLineWidth(context, 3.f);
    CGContextSetLineJoin(context, kCGLineJoinMiter);

    CGContextMoveToPoint(context, PADDING, PADDING);
    CGContextAddLineToPoint(context, self.frame.size.width - PADDING, self.frame.size.height/2);
    CGContextAddLineToPoint(context, PADDING, self.frame.size.height - PADDING);

    CGContextStrokePath(context);
}

@end
