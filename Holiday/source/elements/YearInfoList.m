//************************************************************
// YearInfoList.m
// Holiday
//************************************************************
// Created by Patrick Fial on 28.12.2014
// Copyright 2014-2014 Patrick Fial. All rights reserved.
//************************************************************

//************************************************************
// includes
//************************************************************

#import "YearInfoList.h"
#import "Service.h"
#import "UIColor-Expanded.h"

//************************************************************
// class YearInfoList
//************************************************************

@implementation YearInfoList

#pragma mark - View Lifecycle

//************************************************************
// initWithCoder
//************************************************************

-(id)initWithCoder:(NSCoder *)aDecoder
{
   self= [super initWithCoder:aDecoder];
   
   if (self)
   {
      tappedRow= 0;
      tappedCol= 0;
      highlightCell= NO;
      displayDays= NO;
   }
   
   return self;
}

//************************************************************
// drawRect
//************************************************************

- (void)drawRect:(CGRect)rect
{
   // Drawing code
   
   double cellHeight= rect.size.height / 6;
   double cellWidth= rect.size.width / 2;
   double sizeFactor= cellHeight / 37.3333333333333333333;

   CGContextRef context = UIGraphicsGetCurrentContext();
   
   NSDateFormatter* formatter= [Service dateFormatter];
   NSArray* monthNames= formatter.monthSymbols;
   UIFont* font= [UIFont systemFontOfSize:12 * sizeFactor];
   
   int cellNr= 1;
   
   for (int col= 0; col < 2; col++)
   {
      for (int row= 0; row < 6; row++)
      {
         // draw progress bar grid
         
         double actualCellWidth= cellWidth * (rand() % 50) / 100;
         
         if (cellNr % 3)
            actualCellWidth= 0.0;
         
         [self drawCell:row atCol:col withFillWidth:actualCellWidth withColor:MAINCOLORDARK andFillColor:[UIColor lightGrayColor] doHighlight:(row == tappedRow) && (col == tappedCol) && highlightCell];
         
         // draw month text
         
         NSMutableParagraphStyle* paragraphStyle = [[NSParagraphStyle defaultParagraphStyle] mutableCopy];
         paragraphStyle.lineBreakMode = NSLineBreakByTruncatingTail;
         paragraphStyle.alignment= col ? NSTextAlignmentRight : NSTextAlignmentLeft;
         
         [[monthNames objectAtIndex:cellNr-1] drawInRect:CGRectMake(cellWidth * col + (col ? (-5) : 5), (cellHeight * row) + cellHeight/4, cellWidth - 5, cellHeight/2) withAttributes: @{ NSFontAttributeName:font, NSParagraphStyleAttributeName:paragraphStyle, NSForegroundColorAttributeName: LIGHTTEXTCOLOR }];
         
         [paragraphStyle release];
         
         // draw day number for tapped cells
         
         if (displayDays && (row == tappedRow) && (col == tappedCol))
         {
            paragraphStyle.alignment= !col ? NSTextAlignmentRight : NSTextAlignmentLeft;
            
            [[NSString stringWithFormat:@"%d", 21] drawInRect:CGRectMake(cellWidth * col + (!col ? (-5) : 10), (cellHeight * row) + cellHeight/4, cellWidth - 5, cellHeight/2) withAttributes: @{ NSFontAttributeName:font, NSParagraphStyleAttributeName:paragraphStyle, NSForegroundColorAttributeName: LIGHTTEXTCOLOR }];
            
            [self performSelector:@selector(clearDayDisplay) withObject:nil afterDelay:2];
         }

         cellNr++;
      }
   }
   
   // draw some soft lines to prettify the grid
   
   CGContextSetStrokeColorWithColor(context, [UIColor whiteColor].CGColor);
   CGContextStrokeRect(context, CGRectMake(cellWidth, 0.0, 0.5, rect.size.height));
   
   for (int row= 1; row < 6; row++)
   {
      CGContextStrokeRect(context, CGRectMake(0.0, row * cellHeight, rect.size.width, 0.5));
   }
}

//************************************************************
// touchesBegan
//************************************************************

-(void)drawCell:(int)row atCol:(int)col withFillWidth:(double)fillWidth withColor:(UIColor*)color andFillColor:(UIColor*)fillColor doHighlight:(int)highlight
{
   CGContextRef context = UIGraphicsGetCurrentContext();

   UIColor* theColor= highlight ? [color colorByMultiplyingByRed:1 green:1 blue:1 alpha:0.5] : color;
   UIColor* theFillColor= highlight ? [fillColor colorByMultiplyingByRed:1 green:1 blue:1 alpha:0.5] : fillColor;

   double cellHeight= self.bounds.size.height / 6;
   double cellWidth= self.bounds.size.width / 2;
   
   CGContextSetFillColorWithColor(context, theFillColor.CGColor);
   
   if (col)
   {
      CGContextFillRect(context, CGRectMake(cellWidth * col + cellWidth - fillWidth, cellHeight * row, fillWidth, cellHeight));
      
      if (fillWidth < cellWidth)
      {
         CGContextSetFillColorWithColor(context, theColor.CGColor);
         CGContextFillRect(context, CGRectMake(cellWidth * col, cellHeight * row, cellWidth - fillWidth, cellHeight));
      }
   }
   else
   {
      CGContextFillRect(context, CGRectMake(cellWidth * col, cellHeight * row, fillWidth, cellHeight));
      
      if (fillWidth < cellWidth)
      {
         CGContextSetFillColorWithColor(context, theColor.CGColor);
         CGContextFillRect(context, CGRectMake(fillWidth, cellHeight * row, cellWidth - fillWidth, cellHeight));
      }
   }
}

#pragma mark - Touch detection

//************************************************************
// touchesBegan
//************************************************************

-(void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event
{
   double cellHeight= self.bounds.size.height / 6;
   double cellWidth= self.bounds.size.width / 2;

   UITouch* touch = [touches anyObject];
   CGPoint touchPoint = [touch locationInView:self];
   
   [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(clearDayDisplay) object:nil];
   
   tappedRow= touchPoint.y / cellHeight;
   tappedCol= touchPoint.x / cellWidth;
   highlightCell= YES;
   displayDays= YES;
   
   [self setNeedsDisplay];

   [super touchesBegan:touches withEvent:event];
}

//************************************************************
// touchesCancelled
//************************************************************

-(void)touchesCancelled:(NSSet *)touches withEvent:(UIEvent *)event
{
   if (highlightCell)
   {
      highlightCell= NO;
      [self setNeedsDisplay];
   }
   
   [super touchesCancelled:touches withEvent:event];
}

//************************************************************
// touchesEnded
//************************************************************

-(void)touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event
{
   if (highlightCell)
   {
      highlightCell= NO;
      [self setNeedsDisplay];
   }
   
   [super touchesEnded:touches withEvent:event];
}

//************************************************************
// touchesMoved
//************************************************************

-(void)touchesMoved:(NSSet *)touches withEvent:(UIEvent *)event
{
   [super touchesMoved:touches withEvent:event];
}

#define mark - Events

//************************************************************
// clearDayDisplay
//************************************************************

-(void)clearDayDisplay
{
   displayDays= NO;
   [self setNeedsDisplay];
}


@end
