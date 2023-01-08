//************************************************************
// YearChart.h
// Holiday
//************************************************************
// Created by Patrick Fial on 18.01.2015
// Copyright 2015-2015 Patrick Fial. All rights reserved.
//************************************************************

//************************************************************
// includes
//************************************************************

#import "YearChart.h"
#import "Service.h"
#import "Settings.h"
#import "UIColor-Expanded.h"
#import "Calculation.h"
#import "EventService.h"

#pragma mark - View Lifecycle

//************************************************************
// class YearChart (private)
//************************************************************

@interface YearChart()
{
   CGRect chartRect;
   CGRect monthRect;
   CGRect detailTextRect;
   
   int highlightedMonth;
}

@end

//************************************************************
// class YearChart
//************************************************************

@implementation YearChart

@synthesize barColor, thisYear;

//************************************************************
// initWithCoder
//************************************************************

-(id)initWithCoder:(NSCoder *)aDecoder
{
   self= [super initWithCoder:aDecoder];
   
   if (self)
   {
      thisYear= 0;
      clearYears(&days);
      
      days[1]= 10.0;
      days[10]= 15.0;
      days[11]= 25.0;
      
      days[4]= 1.0;
      days[1]= 10.0;
      
      highlightedMonth= na;
      
      self.barColor = DETAILCOLOR;
   }
   
   return self;
}

//************************************************************
// setDays
//************************************************************

-(void)setDays:(yeararray*)aDays andYearUserd:(double)aYearSpent
{
   if (!aDays)
      return;
   
   copyYears(aDays, &days);
   yearSpent = aYearSpent;
   
   [self setNeedsDisplay];
}

//************************************************************
// drawRect
//************************************************************

-(void)drawRect:(CGRect)rect
{
   // calculate sizes etc.
   
   double elementSpacing= 20.0;
   double smallSpacing= 2.0;
   double separatorHeight= 0.5;

   double detailHeight= 14.0;
   double monthHeight= 9.5;
   double chartHeight= 120.0;
   double yOffset= 0.0;
   
   chartHeight= rect.size.height - monthHeight - detailHeight - smallSpacing*2 - separatorHeight - elementSpacing/2.0;
   
   double chartWidth= rect.size.width - 2*elementSpacing;
   double barWidth= (chartWidth - 11*smallSpacing) / 12;
   
   chartRect=      CGRectMake(elementSpacing, yOffset,                                                                                            chartWidth,   chartHeight);
   monthRect=      CGRectMake(elementSpacing, yOffset + chartHeight + smallSpacing + separatorHeight,                                             chartWidth,   monthHeight);
   detailTextRect= CGRectMake(elementSpacing, yOffset + chartHeight + 2*smallSpacing + separatorHeight + monthHeight + elementSpacing/2.0 - 2.5,  chartWidth,   detailHeight);
   
   CGContextRef context = UIGraphicsGetCurrentContext();
   
   // draw separator line

   CGContextSetStrokeColorWithColor(context, [UIColor lightGrayColor].CGColor);
   CGContextSetLineWidth(context, separatorHeight);
   CGContextMoveToPoint(context, elementSpacing, yOffset + chartHeight + smallSpacing);
   CGContextAddLineToPoint(context, rect.size.width - elementSpacing, yOffset + chartHeight + smallSpacing);
   CGContextStrokePath(context);
   
   // draw bars + month names
   
   double totalDays= 0;
   int yearBeginMonth = [Settings userSettingInt:skYearBegin]-1;
  
   if (yearBeginMonth < 0 || yearBeginMonth > 11)
      yearBeginMonth= 0;
   
   for (int i= 0; i < 12; i++)
   {
      int month = ((i+yearBeginMonth) % 12);
      
      [self drawBar:i month:month ofYear:thisYear + (month < yearBeginMonth ? 1 : 0) withDays:days[i] inRect:chartRect withWidth:barWidth andSpacing:smallSpacing];
      [self drawMonthName:i month:month inRect:monthRect withWidth:barWidth andSpacing:smallSpacing];
      
      totalDays+= days[i];
   }
   
   // draw detail text

   if (!totalDays)
   {
      [self drawDetailText:NSLocalizedString(@"No leave stored yet", nil) inRect:detailTextRect];
   }
   else if (highlightedMonth != na)
   {
      int month = ((highlightedMonth+yearBeginMonth) % 12);

      NSString* text= [[Service dateFormatter].monthSymbols objectAtIndex:month];
      [self drawDetailText:[NSString stringWithFormat:@"%@: %@", text, [Service niceDuration:days[highlightedMonth]]] inRect:detailTextRect];
   }
   else
      [self drawDetailText:[NSString stringWithFormat:@"%@: %@", NSLocalizedString(@"Spent", nil), [[Service numberFormatter] stringFromNumber:[NSNumber numberWithDouble:yearSpent]]] inRect:detailTextRect];
}

//************************************************************
// drawBar
//************************************************************

-(void)drawBar:(int)index month:(int)month ofYear:(int)year withDays:(int)aDays inRect:(CGRect)rect withWidth:(double)width andSpacing:(double)spacing
{
   CGContextRef context = UIGraphicsGetCurrentContext();
   int daysInMonth;
   double height = 0.0;
   
   if (aDays > 0)
   {
      NSDateComponents* comps= [[NSCalendar currentCalendar] components:NSCalendarUnitDay|NSCalendarUnitMonth|NSCalendarUnitYear fromDate:[NSDate date]];
      comps.day= 1;
      comps.month= month+1;
      comps.year = year;
            
      daysInMonth= (int)[[NSCalendar currentCalendar] rangeOfUnit:NSCalendarUnitDay inUnit:NSCalendarUnitMonth forDate:[[NSCalendar currentCalendar] dateFromComponents:comps]].length;

      // use days in month -4xweekend as approximation. calculating real workdays per month HERE is TOO performance heavy.
      
      height= (double)aDays / (double)(daysInMonth-8);
      height *= rect.size.height;
      
      UIColor* fillColor= highlightedMonth == index ? [self.barColor colorByMultiplyingByRed:1 green:1 blue:1 alpha:0.5] : self.barColor;
      
      CGContextSetFillColorWithColor(context, fillColor.CGColor);
      
      CGContextFillRect(context, CGRectMake(rect.origin.x + index * width + index * spacing,
                                            rect.origin.y + rect.size.height - height,
                                            width,
                                            height));
   }

   if (highlightedMonth == index)
   {
      CGContextSetFillColorWithColor(context, [UIColor colorNamed:@"highlightColor"].CGColor);
      CGContextFillRect(context, CGRectMake(rect.origin.x + index * width + index * spacing,
                                            rect.origin.y,
                                            width,
                                            rect.size.height - height));
   }
   else if (aDays <= 0)
   {
      // clear highlight for empty months
      
      CGContextSetFillColorWithColor(context, [UIColor colorNamed:@"cellBackground"].CGColor);
      CGContextFillRect(context, CGRectMake(rect.origin.x + index * width + index * spacing,
                                            rect.origin.y,
                                            width,
                                            rect.size.height - height));
   }
}

//************************************************************
// drawMonthName
//************************************************************

-(void)drawMonthName:(int)index month:(int)month inRect:(CGRect)rect withWidth:(double)width andSpacing:(double)spacing
{
   NSDateFormatter* formatter= [Service dateFormatter];
   NSString* text= [formatter.shortMonthSymbols objectAtIndex:month];
   UIFont* font= [UIFont systemFontOfSize:8.0];
   NSMutableParagraphStyle* paragraphStyle = [[NSParagraphStyle defaultParagraphStyle] mutableCopy];
   paragraphStyle.alignment= NSTextAlignmentCenter;
   
   [text drawInRect:CGRectMake(rect.origin.x + index * width + index * spacing,
                               rect.origin.y,
                               width,
                               rect.size.height) withAttributes: @{ NSFontAttributeName:font, NSParagraphStyleAttributeName:paragraphStyle, NSForegroundColorAttributeName: [UIColor lightGrayColor] }];
}

//************************************************************
// drawDetailText
//************************************************************

-(void)drawDetailText:(NSString*)text inRect:(CGRect)rect
{
   UIFont* font= [UIFont systemFontOfSize:12.0];
   NSMutableParagraphStyle* paragraphStyle = [[NSParagraphStyle defaultParagraphStyle] mutableCopy];
   paragraphStyle.alignment= NSTextAlignmentCenter;
   
   NSDictionary* attributes= @{ NSFontAttributeName:font, NSParagraphStyleAttributeName:paragraphStyle, NSForegroundColorAttributeName: [UIColor lightGrayColor] };
   
   [text drawInRect:rect withAttributes:attributes];
}

#pragma mark - Touch detection

//************************************************************
// touchesBegan
//************************************************************

-(void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event
{
   UITouch* touch = [touches anyObject];
   [self highlightBar:touch];
   
   [super touchesBegan:touches withEvent:event];
}

//************************************************************
// touchesMoved
//************************************************************

-(void)touchesMoved:(NSSet *)touches withEvent:(UIEvent *)event
{
   UITouch* touch = [touches anyObject];
   [self highlightBar:touch];
   
   [super touchesMoved:touches withEvent:event];
}

//************************************************************
// highlightBar
//************************************************************

-(void)highlightBar:(UITouch*)touch
{
   double xSpacing= 10.0;
   double chartWidth= self.frame.size.width - 2*xSpacing;
   double barSpacing= 2.0;
   double barWidth= (chartWidth - 11*barSpacing) / 12;
   CGPoint touchPoint = [touch locationInView:self];
   
   if (touchPoint.x < chartRect.origin.x || touchPoint.x > chartRect.origin.x + chartRect.size.width)
      return;
   
   if (touchPoint.y < chartRect.origin.y || touchPoint.y > chartRect.origin.y + chartRect.size.height)
      return;
   
   [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(clearHighlight) object:nil];
   [self performSelector:@selector(clearHighlight) withObject:nil afterDelay:2];

   for (int i= 0; i < 12; i++)
   {
      double x1= xSpacing + i*barWidth + i*barSpacing;
      double x2= x1+barWidth;
      
      if (touchPoint.x >= x1 && touchPoint.x <= x2)
      {
         highlightedMonth= i;
         
         [self setNeedsDisplay];
         break;
      }
   }
}

//************************************************************
// clearHighlight
//************************************************************

-(void)clearHighlight
{
   highlightedMonth= na;
   [self setNeedsDisplay];
}

@end
