//************************************************************
// PopoverTable.m
// Holiday
//************************************************************
// Created by Patrick Fial on 01.07.2015
// Copyright 2015-2015 Patrick Fial. All rights reserved.
//************************************************************

//************************************************************
// includes
//************************************************************

#import "PopoverTable.h"
#import "AppDelegate.h"
#import "LeaveInfo.h"
#import "Service.h"
#import "PublicHoliday.h"
#import "Freeday.h"

#pragma mark - PopoverTable

//************************************************************
// class PopoverTable(private)
//************************************************************

@interface PopoverTable()
{
   double cellHeight;
   double tableWidth;
}

@property (nonatomic, retain) UITableView* tableview;
@property (nonatomic, retain) NSArray* values;
@property (nonatomic, retain) UIFont* mainFont;
@property (nonatomic, retain) UIFont* detailFont;

@end

//************************************************************
// class ActionTable
//************************************************************

@implementation PopoverTable

@synthesize values, tableview, mainFont, detailFont;

#pragma mark - Lifecycle

//************************************************************
// initWithValues
//************************************************************

-(id)initWithValues:(NSArray*)aValues atPoint:(CGPoint)point inFrame:(CGRect)frame
{
   self= [super initWithFrame:[UIScreen mainScreen].bounds];
   
   if (self)
   {
      self.values= aValues;
      self.mainFont= [UIFont fontWithName:@"HelveticaNeue" size:14.0];
      self.detailFont= [UIFont fontWithName:@"HelveticaNeue-Light" size:9.0];
      
      static int init= YES;
      static CGSize dateStringSize;
      
      if (init)
      {
         NSString* dateString= [Service rangeStringForDate:[NSDate date] end:[NSDate date]];
         dateStringSize= [dateString sizeWithAttributes:@{ NSFontAttributeName : detailFont }];
         init= NO;
      }
      
      // (1) calculate position, size and direction of popover

      int maxRows= 3;
      int direction;
      CGRect rect;
      double tableHeight;
      double tooltipPadding = 10.0;
      double cornerRadius= 5.0;
      double arrowLength= 20.0;
      double arrowHeight= sqrt(pow(arrowLength, 2.0) - (pow(arrowLength/2, 2.0))) * 0.5;
      double padding = (100.0) * SCALEFACTOR;
      double maxSize= dateStringSize.width;

      for (LeaveInfo* ifo in self.values)
      {
         CGSize size= [ifo.title sizeWithAttributes:@{ NSFontAttributeName : self.mainFont }];
         maxSize= maxSize < size.width ? size.width : maxSize;
      }

      cellHeight= 44.0;
      tableWidth= (maxSize+padding) > 220.0 ? 220.0 : (maxSize+padding);
      tableHeight= aValues.count > maxRows ? (maxRows * cellHeight) + 0.5*cellHeight : aValues.count * cellHeight;

      if (point.x < (frame.origin.x + frame.size.width - tableWidth - tooltipPadding - arrowHeight))
      {
         direction= dirLeft;
         rect= CGRectMake(point.x + arrowHeight, point.y - tableHeight/2, tableWidth, tableHeight);
      }
      else if (point.x > frame.origin.x + tableWidth + tooltipPadding + arrowHeight)
      {
         direction= dirRight;
         rect= CGRectMake(point.x - arrowHeight - tableWidth, point.y - tableHeight/2, tableWidth, tableHeight);
      }
      else
      {
         direction= dirBottom;
         rect= CGRectMake((point.x - tableWidth/2) < padding ? padding : point.x - tableWidth/2, point.y + arrowHeight, tableWidth, tableHeight);
      }
      
      // (2) draw rounded rect with arrow extension
      
      CGMutablePathRef path = CGPathCreateMutable();
      CGPathMoveToPoint(path, 0, rect.origin.x + cornerRadius, rect.origin.y);
      
      // top line + arc going down
      
      if (direction == dirBottom)
      {
         double segmentLength= point.x - rect.origin.x - arrowLength/2;
         
         CGPathAddLineToPoint(path, 0, rect.origin.x + segmentLength, rect.origin.y);
         CGPathAddLineToPoint(path, 0, rect.origin.x + segmentLength + arrowLength / 2, rect.origin.y - arrowHeight);
         CGPathAddLineToPoint(path, 0, rect.origin.x + segmentLength + arrowLength, rect.origin.y);
      }
      
      CGPathAddLineToPoint(path, 0, rect.origin.x+rect.size.width - 2*cornerRadius, rect.origin.y);
      CGPathAddArc(path, 0, rect.origin.x + rect.size.width - cornerRadius, rect.origin.y + cornerRadius, cornerRadius, 3*M_PI/2, 0.0, NO);
      
      // right line + arc going left
      
      if (direction == dirRight)
      {
         double segmentLength= (rect.size.height - arrowLength - 2* cornerRadius) / 2;
         
         CGPathAddLineToPoint(path, 0, rect.origin.x + rect.size.width, rect.origin.y + cornerRadius + segmentLength);
         CGPathAddLineToPoint(path, 0, rect.origin.x + rect.size.width + arrowHeight, rect.origin.y + cornerRadius + segmentLength + arrowLength/2);
         CGPathAddLineToPoint(path, 0, rect.origin.x + rect.size.width, rect.origin.y + cornerRadius + segmentLength + arrowLength);
      }
      
      CGPathAddLineToPoint(path, 0, rect.origin.x + rect.size.width, rect.origin.y + rect.size.height - 2*cornerRadius);
      CGPathAddArc(path, 0, rect.origin.x + rect.size.width - cornerRadius, rect.origin.y + rect.size.height - cornerRadius, cornerRadius, 0.0, M_PI/2, NO);
      
      // bottom line + arc going up

      CGPathAddLineToPoint(path, 0, rect.origin.x + cornerRadius, rect.origin.y + rect.size.height);
      CGPathAddArc(path, 0, rect.origin.x + cornerRadius, rect.origin.y + rect.size.height - cornerRadius, cornerRadius, M_PI/2, M_PI, NO);
      
      // left line + arc going right

      if (direction == dirLeft)
      {
         double segmentLength= (rect.size.height - arrowLength - 2* cornerRadius) / 2;
         
         CGPathAddLineToPoint(path, 0, rect.origin.x, rect.origin.y + cornerRadius + segmentLength + arrowLength);
         CGPathAddLineToPoint(path, 0, rect.origin.x - arrowHeight, rect.origin.y + cornerRadius + segmentLength + arrowLength - arrowLength/2);
         CGPathAddLineToPoint(path, 0, rect.origin.x, rect.origin.y + cornerRadius + segmentLength);
      }
      
      CGPathAddLineToPoint(path, 0, rect.origin.x, rect.origin.y + cornerRadius);
      CGPathAddArc(path, 0, rect.origin.x + cornerRadius, rect.origin.y + cornerRadius, cornerRadius, M_PI, 3*M_PI/2, NO);
      
      CAShapeLayer *shapeLayer = [CAShapeLayer layer];
      [shapeLayer setPath:path];
      [shapeLayer setFillColor:[[UIColor colorNamed:@"cellBackground"] CGColor]];
      [shapeLayer setStrokeColor:UIColorFromRGB(0xcccccc).CGColor];
      [shapeLayer setBounds:rect];
      [shapeLayer setAnchorPoint:CGPointMake(0.0f, 0.0f)];
      [shapeLayer setPosition:CGPointMake(rect.origin.x, rect.origin.y)];
      [shapeLayer setLineWidth:1.0];
      [shapeLayer setShadowRadius:2.0];

      CGPathRelease(path);
      
      [self.layer addSublayer:shapeLayer];
      self.layer.masksToBounds = YES;
      
      // (3) finally add tableview as subview

      self.tableview= [[[UITableView alloc] initWithFrame:rect] autorelease];
      self.tableview.dataSource= self;
      self.tableview.delegate= self;
      self.tableview.showsVerticalScrollIndicator= NO;
      self.tableview.separatorStyle= UITableViewCellSeparatorStyleNone;
      self.tableview.layer.cornerRadius = 5.0;

      [self addSubview:self.tableview];
   }
   
   return self;
}

//************************************************************
// includes
//************************************************************

-(void)dealloc
{
   self.tableview= nil;
   self.values= nil;

   [super dealloc];
}

#pragma mark - Hide/Show

//************************************************************
// show
//************************************************************

-(void)showInView:(UIView*)aView
{
   [aView addSubview:self];
}

//************************************************************
// dismiss
//************************************************************

-(void)dismiss
{
   [self removeFromSuperview];
}

//************************************************************
// numberOfSectionsInTableView
//************************************************************

-(NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
   return 1;
}

//************************************************************
// numberOfRowsInSection
//************************************************************

-(NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
   return self.values.count;
}

//************************************************************
// heightForRowAtIndexPath
//************************************************************

-(CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
   return cellHeight;
}

//************************************************************
// cellForRowAtIndexPath
//************************************************************

-(UITableViewCell*)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
   UITableViewCell* cell= [tableView dequeueReusableCellWithIdentifier:@"Cell"];
   
   LeaveInfo* leaveInfo= nil;
   PublicHolidayInfo* publicHolidayInfo= nil;
   Freeday* freeday = nil;
   
   id ifo= [self.values objectAtIndex:indexPath.row];
   
   if ([ifo isKindOfClass:[LeaveInfo class]])
      leaveInfo= ifo;
   else if ([ifo isKindOfClass:[Freeday class]])
      freeday= ifo;
   else
      publicHolidayInfo= ifo;
   
   if (cell == nil)
   {
      cell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:@"Cell"] autorelease];
      cell.textLabel.font= self.mainFont;
      cell.detailTextLabel.font= self.detailFont;
//      cell.textLabel.textColor= [UIColor blackColor];
//      cell.detailTextLabel.textColor= [UIColor blackColor];
      cell.backgroundColor= [UIColor colorNamed:@"cellBackground"];
      cell.frame= CGRectMake(cell.frame.origin.x, cell.frame.origin.y, tableWidth, cellHeight);
   }
   
   if (leaveInfo)
   {
      cell.textLabel.text= leaveInfo.title;
      cell.detailTextLabel.text= [Service rangeStringForDate:leaveInfo.begin end:leaveInfo.end];
   }
   else if (freeday)
   {
      cell.textLabel.text= freeday.title;
      cell.detailTextLabel.text = nil;
      cell.userInteractionEnabled = NO;
   }
   else
   {
      cell.textLabel.text= publicHolidayInfo.title;
      cell.detailTextLabel.text= [Service rangeStringForDate:publicHolidayInfo.date end:publicHolidayInfo.date];
      cell.userInteractionEnabled = NO;
   }
   
   return cell;
}

//************************************************************
// didSelectRowAtIndexPath
//************************************************************

-(void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
   if (self.itemSelected)
   {
      id ifo= [self.values objectAtIndex:indexPath.row];
      
      if (![ifo isKindOfClass:[LeaveInfo class]])
         return;
      
      self.itemSelected((int)indexPath.row);
      [self dismiss];
   }
}

@end


