//************************************************************
// DonutView.m
// Holiday
//************************************************************
// Created by Patrick Fial on 28.12.2014
// Copyright 2014-2014 Patrick Fial. All rights reserved.
//************************************************************

//************************************************************
// includes
//************************************************************

#import "DonutView.h"
#import "UIColor-Expanded.h"
#import "Service.h"

#define SCALE ([[UIScreen mainScreen] bounds].size.width/320)
#define DONUTWIDTH 30.0 * (SCALE)
//#define DONUTPADDING 13.0
#define ROTATION 270.0

enum DonutSelection
{
   dsSpent,
   dsRemain,
   dsOverspent,
   dsLastYear
};

//************************************************************
// class DonutView (private)
//************************************************************

@interface DonutView()
{
   double percentDone;
   double percentLastYear;
   double daysTotal;
   double daysUsed;
   double daysLastYear;
   
   enum DonutSelection selection;
   
   int highlightArea;
}

-(void)drawArc:(double)radius withCenterX:(double)centerX andCenterY:(double)centerY andStartAngle:(int)startAngle andEndAngle:(int)endAngle andColor:(UIColor*)color doHighlight:(int)highlight lineWidth:(double)lineWidth;

@end

//************************************************************
// class DonutView
//************************************************************

@implementation DonutView

@synthesize colorOverspent, colorRemain, colorResidual, colorSpent, colorUnused;

//************************************************************
// initWithCoder
//************************************************************

-(id)initWithCoder:(NSCoder *)aDecoder
{
   self= [super initWithCoder:aDecoder];
   
   if (self)
   {
      daysTotal= 26;
      daysUsed= 6;
      daysLastYear= 7;
      percentDone= 0.0;
      percentLastYear= 0.0;

      selection= percentDone < 1.0 ? dsRemain : (percentDone < 2.0 ? dsSpent : dsOverspent);
     
      highlightArea= NO;
   }
   
   return self;
}

//************************************************************
// update
//************************************************************

-(void)update:(double)days withUsed:(double)used andRemain:(double)remain
{
   daysTotal= days;
   daysUsed= used;
   daysLastYear= remain;
   
   [self setNeedsDisplay];
}

//************************************************************
// drawRect
//************************************************************

- (void)drawRect:(CGRect)rect
{
   // Drawing code
   
   double centerX= rect.size.width / 2;
   double centerY= rect.size.height / 2;
   double radius= centerX - (DONUTWIDTH/2);
   
   percentDone= daysTotal ? daysUsed / daysTotal : 0.0;
   percentLastYear= daysLastYear ? daysLastYear / daysTotal : 0.0;
   
   int angleLastYearEnd= 360*percentLastYear;
   int angleUsedEnd= 360*percentDone;
   
   // draw 'used'-arc

   if (angleUsedEnd)
      [self drawArc:radius withCenterX:centerX andCenterY:centerY andStartAngle:0 + ROTATION andEndAngle:angleUsedEnd + ROTATION andColor:colorSpent doHighlight:highlightArea && selection == dsSpent lineWidth:DONUTWIDTH];
   
   if (angleUsedEnd > 360)
   {
      // draw 'remain'-arc
      
      angleUsedEnd= angleUsedEnd % 360;

      [self drawArc:radius withCenterX:centerX andCenterY:centerY andStartAngle:0 + ROTATION andEndAngle:angleUsedEnd + ROTATION andColor:colorOverspent doHighlight:highlightArea && selection == dsOverspent lineWidth:DONUTWIDTH];
      
      // draw 'overused'-arc
      
      [self drawArc:radius withCenterX:centerX andCenterY:centerY andStartAngle:angleUsedEnd + ROTATION andEndAngle:360 + ROTATION andColor:colorSpent doHighlight:highlightArea && selection == dsSpent lineWidth:DONUTWIDTH];
   }
   else if (!daysTotal && !angleUsedEnd)
   {
      [self drawArc:radius withCenterX:centerX andCenterY:centerY andStartAngle:0 + ROTATION andEndAngle:360 + ROTATION andColor:colorUnused doHighlight:highlightArea lineWidth:DONUTWIDTH];
   }
   else if (360-angleUsedEnd)
   {
      // draw 'used'-arc
      
      [self drawArc:radius withCenterX:centerX andCenterY:centerY andStartAngle:angleUsedEnd + ROTATION andEndAngle:360 + ROTATION andColor:colorRemain doHighlight:highlightArea && selection == dsRemain lineWidth:DONUTWIDTH];
   }
   
   if (angleLastYearEnd)
      [self drawArc:radius-7.5 withCenterX:centerX andCenterY:centerY andStartAngle:angleUsedEnd + ROTATION andEndAngle:angleUsedEnd + angleLastYearEnd + ROTATION andColor:colorResidual doHighlight:highlightArea && selection == dsLastYear lineWidth:DONUTWIDTH/2];
   
   // draw inner text
   
   float donutPadding = (radius - DONUTWIDTH) * (0.2*SCALE);

   CGRect innerRect= CGRectMake((centerX - rect.size.width/4 * 0.8),
                                (centerY - rect.size.height/4 * 0.8),
                                rect.size.width/2 * 0.8,
                                rect.size.height/2 * 0.8);
   
   UIFont* font= [UIFont systemFontOfSize:24.0];
   UIFont* smallFont= [UIFont systemFontOfSize:10.0];

   NSMutableParagraphStyle* paragraphStyle = [[NSParagraphStyle defaultParagraphStyle] mutableCopy];
   paragraphStyle.lineBreakMode = NSLineBreakByWordWrapping;
   paragraphStyle.alignment= NSTextAlignmentCenter;
   
   NSString* label= nil;
   double amount= 0.0;
   
   switch (selection)
   {
      case dsRemain:    amount= daysTotal-daysUsed; label= NSLocalizedString(@"Remain", nil);    break;
      case dsSpent:     amount= daysUsed;           label= NSLocalizedString(@"Spent", nil);     break;
      case dsOverspent: amount= daysTotal-daysUsed; label= NSLocalizedString(@"Overrun", nil);   break;
      case dsLastYear:  amount= daysLastYear;       label= NSLocalizedString(@"Residual", nil);  break;
   }
   
   double yOffset= 7.5;

   CGRect bigLabelRect=   CGRectMake(innerRect.origin.x, innerRect.origin.y + yOffset, innerRect.size.width, innerRect.size.height - 2*donutPadding);
   double lowerRectHeight= innerRect.size.height - bigLabelRect.size.height - 2*donutPadding;
   
   CGRect titleRect=       CGRectMake(innerRect.origin.x, bigLabelRect.origin.y + bigLabelRect.size.height, innerRect.size.width, lowerRectHeight);
   
   [self drawString:[NSString stringWithFormat:@"%@", [[Service numberFormatter] stringFromNumber:[NSNumber numberWithDouble:amount]]]
           withFont:font
           andColor:[UIColor colorNamed:@"cellSubText"]
       andAlignment:NSTextAlignmentCenter
             inRect:bigLabelRect];

   [self drawString:label withFont:smallFont andColor:[UIColor colorNamed:@"cellSubText"] andAlignment:NSTextAlignmentCenter inRect:titleRect];
}

//************************************************************
// drawArc
//************************************************************

-(void)drawArc:(double)radius withCenterX:(double)centerX andCenterY:(double)centerY andStartAngle:(int)startAngle andEndAngle:(int)endAngle andColor:(UIColor*)color doHighlight:(int)highlight lineWidth:(double)lineWidth
{
   CGContextRef context= UIGraphicsGetCurrentContext();
   
   UIColor* theColor= highlight ? [color colorByMultiplyingByRed:1 green:1 blue:1 alpha:0.5] : color;
   
   CGContextSetStrokeColorWithColor(context, theColor.CGColor);
   
   CGMutablePathRef path= CGPathCreateMutable();
   
   CGContextSetLineWidth(context, lineWidth);
   
   CGPathAddArc(path, NULL, centerX, centerY, radius, startAngle*3.142/180, endAngle*3.142/180, 0);
   
   CGContextAddPath(context, path);
   CGContextStrokePath(context);
   
   CGPathRelease(path);
}

//************************************************************
// draw String
//************************************************************

-(void)drawString:(NSString*)s withFont:(UIFont*)font andColor:(UIColor*)color andAlignment:(NSTextAlignment)align inRect:(CGRect)contextRect
{
   static NSMutableParagraphStyle* paragraphStyle= nil;
   
   if (!paragraphStyle)
   {
      paragraphStyle= [[NSParagraphStyle defaultParagraphStyle] mutableCopy];
      paragraphStyle.lineBreakMode= NSLineBreakByTruncatingTail;
      paragraphStyle.alignment= align;
   }
   
   NSDictionary* attributes = @{ NSFontAttributeName: font,
                                 NSForegroundColorAttributeName: color,
                                 NSParagraphStyleAttributeName: paragraphStyle
                                 };
   
   if (align == NSTextAlignmentCenter)
   {
      CGSize size= [s sizeWithAttributes:attributes];
      CGRect textRect = CGRectMake(contextRect.origin.x + ((contextRect.size.width - size.width) / 2),
                                   contextRect.origin.y + ((contextRect.size.height - size.height) / 2),
                                   size.width,
                                   size.height);
      
      [s drawInRect:textRect withAttributes:attributes];
   }
   else
   {
      [s drawInRect:contextRect withAttributes:attributes];
   }
}

#pragma mark - Touch detection

//************************************************************
// touchesBegan
//************************************************************

-(void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event
{
   UITouch* touch = [touches anyObject];
   CGPoint touchPoint = [touch locationInView:self];
   CGPoint circleCenter = CGPointMake(self.bounds.size.width/2, self.bounds.size.height/2);
   float dx = circleCenter.x - touchPoint.x;
   float dy = circleCenter.y - touchPoint.y;
   float t = atan2f(dy, dx) + M_PI;
   double radius= self.bounds.size.width / 2 - 15.0;
   double angle= t * 180.0/M_PI - ROTATION;
   
   if (angle < 0)
      angle+= 360;
   
   percentDone= daysTotal ? daysUsed / daysTotal : 0.0;
   percentLastYear= daysLastYear ? daysLastYear / daysTotal : 0.0;
   
   int angleUsedEnd= 360*percentDone;
   int angleLastYearEnd= 360*percentLastYear;
   
   if (angleLastYearEnd)
      angleLastYearEnd+= angleUsedEnd;

   float dist = sqrtf(dx * dx + dy * dy);
   
   if ((dist >= radius - DONUTWIDTH / 2) && (dist <= radius + DONUTWIDTH / 2))
   {
      highlightArea= YES;
      
      if (angleUsedEnd <= 360)
      {
         if (angle >= 0 && angle <= angleUsedEnd)
            selection= dsSpent;
         else
            selection= dsRemain;
      }
      else
      {
         angleUsedEnd= angleUsedEnd % 360;
         
         if (angle >= 0 && angle <= angleUsedEnd)
            selection= dsOverspent;
         else
            selection= dsSpent;
      }
      
      if (angleLastYearEnd && angle > angleUsedEnd && angle <= angleLastYearEnd)
      {
         if (dist < 60.0) // && selection != dsSpent)
            selection= dsLastYear;
      }
      
      [self setNeedsDisplay];
   }

   [super touchesBegan:touches withEvent:event];
}

//************************************************************
// touchesCancelled
//************************************************************

-(void)touchesCancelled:(NSSet *)touches withEvent:(UIEvent *)event
{
   if (highlightArea)
      [self performSelector:@selector(clearHighlight) withObject:nil afterDelay:0.1];
   
   [super touchesCancelled:touches withEvent:event];
}

//************************************************************
// touchesEnded
//************************************************************

-(void)touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event
{
   if (highlightArea)
      [self performSelector:@selector(clearHighlight) withObject:nil afterDelay:0.1];
   
   [super touchesEnded:touches withEvent:event];
}

//************************************************************
// //************************************************************
// touchesMoved
//************************************************************

//************************************************************

-(void)clearHighlight
{
   int hadHighlight= highlightArea;
   
   highlightArea= NO;
   
   if (hadHighlight)
      [self setNeedsDisplay];
}

//************************************************************
// touchesMoved
//************************************************************

-(void)touchesMoved:(NSSet *)touches withEvent:(UIEvent *)event
{
   [super touchesMoved:touches withEvent:event];
}

@end
