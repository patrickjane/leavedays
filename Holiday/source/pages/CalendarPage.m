//************************************************************
// CalendarPage.m
// Holliday
//************************************************************
// Created by Patrick Fial on 26.12.14.
// Copyright 2014-2014 Patrick Fial. All rights reserved.
//************************************************************

//************************************************************
// includes
//************************************************************

#import "CalendarPage.h"
#import "LeaveInfo.h"
#import "Service.h"
#import "Storage.h"
#import "PublicHoliday.h"
#import "User.h"
#import "Category.h"
#import "SessionManager.h"
#import "Settings.h"
#import "Storage.h"
#import "Calculation.h"
#import "UIColor-Expanded.h"
#import "UIColor-HSVAdditions.h"
#import "Freeday.h"

#import "PopoverTable.h"

#import "JASidePanelController.h"
#import "TabController.h"

#define BASE_YEAR 1980
#define MONTH_WIDTH (210 * SCALEFACTOR)
#define MONTH_HEIGHT (209 * SCALEFACTOR)
#define MONTH_SPACING (44.0 * SCALEFACTOR)
#define TITLE_HEIGHT (46.0 * SCALEFACTOR)
#define CALENDAR_SPACING (38.0)
#define CALENDAR_TOP_PADDING (44.0 * SCALEFACTOR)
#define CALENDAR_HEIGHT (CALENDAR_TOP_PADDING + TITLE_HEIGHT + 1.0 + 4*MONTH_HEIGHT + 3*MONTH_SPACING + CALENDAR_SPACING)

#pragma mark - Class GridView

//************************************************************
// Sizes used below
//
// Page Width:        35 + 210 + 25 + 210 + 28 + 210 + 32 = 750 / 2   = 375
// Page Height:       17 + 46 + 18 + 1 + 209*4 + 44*3 + 20 = 1070 / 2 = 535
// Header Size:       150 x 46
// Container Size:    210 x 209
// Container x space: 35 / 25 / 28 / 32
// Container y space: 44
// Cell Size:         30x34
//************************************************************

//************************************************************
// class GridView
//************************************************************

@implementation GridView

@synthesize popOver, darkerFillerGrey, darkerFillerColored;

//************************************************************
// initWithFrame
//************************************************************

- (id)initWithFrame:(CGRect)frame andYear:(int)aYear
{
   self= [super initWithFrame:frame];
   
   if (self)
   {
      yearNum= aYear;
      
      self.darkerFillerColored= [MAINCOLORDARK colorByDarkeningTo:0.3];
      self.darkerFillerGrey= [[UIColor lightGrayColor] colorByDarkeningTo:0.3];
      self.popOver= nil;
      self.clipsToBounds= NO;
      self.backgroundColor= [UIColor colorNamed:@"cellBackground"];

      // build array with weekdays from 0-6, where array[n] is the actual weekday for the n-th column
      
      static NSUInteger firstWeekdayIndex = -1;
      
      if (firstWeekdayIndex == -1)
         firstWeekdayIndex= [[NSCalendar currentCalendar] firstWeekday] - 1;
      
      for (int i= 0; i< 7; i++)
         weekdays[i]= (i+firstWeekdayIndex) % 7;
      
      NSDateComponents* comps= [[[NSDateComponents alloc] init] autorelease];
      NSDate* date;
      comps.year= aYear;
      comps.month= 1;
      comps.day= 1;
      
      for (int i= 0; i < 12; i++)
      {
         comps.month= i+1;
         date= [[NSCalendar currentCalendar] dateFromComponents:comps];
         numberOfDaysInMonth[i]= (int)[[NSCalendar currentCalendar] rangeOfUnit:NSCalendarUnitDay inUnit:NSCalendarUnitMonth forDate:date].length;
      }
   }
   
   return self;
}

//************************************************************
// dealloc
//************************************************************

-(void)dealloc
{
   self.darkerFillerColored= nil;
   self.darkerFillerGrey= nil;
   
   self.popOver= nil;
   [super dealloc];
}

//************************************************************
// draw Rect
//************************************************************

-(void)drawRect:(CGRect)rect
{
   int monthNum= 0;

   for (int i= 0; i < 12; i++)
      for (int d= 0; d < 31; d++)
         dayRects[i][d]= CGRectZero;

   for (int row= 0; row < 4; row++)
   {
      for (int column= 0; column < 3; column++)
      {
         double xSpacing= 0.0;
         
         if (column == 1)
            xSpacing += (25.0 * SCALEFACTOR);
         else if (column == 2)
            xSpacing += (25.0 * SCALEFACTOR + 28.0 * SCALEFACTOR);
         
         monthRects[monthNum]= CGRectMake(xSpacing + column * MONTH_WIDTH,
                                          row*(MONTH_HEIGHT + MONTH_SPACING),
                                          MONTH_WIDTH,
                                          MONTH_HEIGHT);
         
         [self drawMonthRect:monthRects[monthNum] andMonth:monthNum];
         
         monthNum++;
      }
   }
}

//************************************************************
// draw Month Rect
//************************************************************

-(void)drawMonthRect:(CGRect)rect andMonth:(int)monthNum
{
   NSString* monthName= [[[Service dateFormatter] monthSymbols] objectAtIndex:monthNum];
   static UIFont *defaultFont, *boldFont, *nameFont;
   static NSDateComponents* staticComps= nil;
   
   if (!defaultFont)
   {
      defaultFont= [[UIFont fontWithName:@"HelveticaNeue" size:8.0] retain];
      boldFont= [[UIFont fontWithName:@"HelveticaNeue-Bold" size:8.0] retain];
      nameFont= [[UIFont fontWithName:@"HelveticaNeue-Light" size:13.0f] retain];
   }
   
   if (!staticComps)
      staticComps= [[NSDateComponents alloc] init];   // never released, used during whole runtime
   
   [staticComps setDay:1];
   [staticComps setMonth:monthNum+1];
   [staticComps setYear:yearNum];
   
   NSDate* date= [[NSCalendar currentCalendar] dateFromComponents:staticComps];
   int firstOfMonthWeekday= (int)[[[NSCalendar currentCalendar] components:NSCalendarUnitWeekday fromDate:date] weekday]-1;
   int todayDay, todayMonth, todayYear;
   
   NSDateComponents* comps= [[NSCalendar currentCalendar] components:NSCalendarUnitDay|NSCalendarUnitMonth|NSCalendarUnitYear fromDate:[NSDate date]];

   todayDay= (int)comps.day;
   todayMonth= (int)comps.month;
   todayYear= (int)comps.year;
   
   // find column for this date
   
   int i= 0;
   
   for (i= 0; i < 7; i++)
      if (weekdays[i] == firstOfMonthWeekday)
         break;
   
   const double width= 30.0 * SCALEFACTOR;         // 15 width
   const double height= 34.0 * SCALEFACTOR;        // 17 height
   const double yOffset= 20.0;
   
   CGRect nameRect= CGRectMake(rect.origin.x, rect.origin.y, 200.0, 20.0);
   int day= 1;
   
   // (1) draw month name
   
   [self drawString:[monthName uppercaseString] withFont:nameFont andColor:[UIColor redColor] andAlignment:NSTextAlignmentLeft inRect:nameRect];

   // (2) draw day grid
   
   CGRect todayRect;
   int todayNum= na;

   for (int row= 0; row < 6 && day <= numberOfDaysInMonth[monthNum]; row++)
   {
      for (int column= 0; column < 7 && day <= numberOfDaysInMonth[monthNum]; column++)
      {
         if (i-- > 0)
            continue;

         NSString* dayString= [NSString stringWithFormat:@"%d", day];
         CGRect* dayRect= &dayRects[monthNum][day-1];

         *dayRect= CGRectMake(rect.origin.x + width * column,
                                    rect.origin.y + yOffset + height * row,
                                    width,
                                    height);

         if (markers[monthNum][day-1][0])
         {
            // (a) draw leave marker (begin, mid, end piece)

            int theDay= day-1;
            int prevDay= theDay == 0 ? na : theDay-1;
            int nextDay= theDay == numberOfDaysInMonth[monthNum]-1 ? na : theDay+1;

            int before= prevDay != na && markers[monthNum][prevDay][0];
            int after= nextDay != na && markers[monthNum][nextDay][0];
            LeaveInfo* info= markers[monthNum][day-1][0];
            bool colorByCategory = [Settings globalSettingBool:skCalendarColorByCategory];
            CategoryRef* c= info && info.category ? [Storage categoryForName:info.category ofUser:[[Storage currentStorage] userWithUUid:info.userid]] : nil;
            UIColor* color = colorByCategory && c ?  [Service colorString:c.color] : (info.status.integerValue ? MAINCOLORDARK : MAINCOLORBRIGHT);
            UIColor* textColor = [UIColor whiteColor];

            double brightness= 1 - (0.299 * color.red * 255 + 0.587 * color.green * 255 + 0.114 * color.blue * 255)/255;

            if (brightness < 0.2)          // bright background, dark font
               textColor = [UIColor darkGrayColor];

            CGRect cRect= CGRectMake(dayRect->origin.x, dayRect->origin.y + (dayRect->size.height-dayRect->size.width)/2 + 0.5,
                                     dayRect->size.width + 0.5, dayRect->size.width);

            [self fillCell:cRect withColor:color andBefore:before andAfter:after];
            [self drawString:dayString withFont:boldFont andColor:textColor andAlignment:NSTextAlignmentCenter inRect:*dayRect];
         }
         else
         {
            // (b) default cell (black text)

            [self drawString:dayString withFont:defaultFont andColor:[UIColor colorNamed:@"cellMainText"] andAlignment:NSTextAlignmentCenter inRect:*dayRect];
         }

         if (day == todayDay && monthNum == todayMonth-1 && yearNum == todayYear)
         {
            // (c) for today, only temp-save CGRect and day number. will be drawn in the end
            //     to overwrite already painted background with white border

            todayRect= *dayRect;
            todayNum= day;
         }

         day++;
      }
   }

   // draw public holiday on top of all

   for (int i= 1; i < 13; i++)
   {
      NSArray* publicHoliday= [[PublicHoliday instance] getPublicHolidayForMonth:i inYear:yearNum];

      if (!publicHoliday || !publicHoliday.count)
         continue;

      for (PublicHolidayInfo* ifo in publicHoliday)
      {
         int day= (int)[[NSCalendar currentCalendar] component:NSCalendarUnitDay fromDate:ifo.date];
         CGRect dayRect= dayRects[i-1][day-1];
         
         if (CGRectIsEmpty(dayRect))
            continue;

         [self fillCircleCell:dayRect withDay:day andFont:boldFont andColor:[UIColor whiteColor] andBackground:[UIColor lightGrayColor]];
      }
   }
   
   // .. and also free days (same color as public holiday)
   
   for (Freeday* freeday in [Storage freedaysList].allValues)
   {
      CGRect dayRect= dayRects[freeday.month.intValue-1][freeday.day.intValue-1];

      if (CGRectIsEmpty(dayRect))
         continue;

      [self fillCircleCell:dayRect withDay:freeday.day.intValue andFont:boldFont andColor:[UIColor whiteColor] andBackground:[UIColor lightGrayColor]];
   }

   // (3) last but not least TODAY cell (red circle, white text) (to overwrite previous colors nicely)

   if (todayNum != na)
      [self fillCircleCell:todayRect withDay:todayNum andFont:boldFont andColor:[UIColor whiteColor] andBackground:[UIColor redColor]];
}

//************************************************************
// fillCell
//************************************************************

-(void)fillCell:(CGRect)cRect withColor:(UIColor*)aColor andBefore:(int)before andAfter:(int)after
{
   if (before && after)
   {
      // middle of marker. fill square (no rounded corners)
      
      CGContextRef context = UIGraphicsGetCurrentContext();
      CGContextSetFillColorWithColor(context, aColor.CGColor);
      CGContextFillRect(context, cRect);
   }
   else
   {
      // begin, end or single day marker. first draw circle
      
      CGContextRef context = UIGraphicsGetCurrentContext();
      CGContextSetFillColorWithColor(context, aColor.CGColor);
      CGContextFillEllipseInRect(context, cRect);
      
      // prepend/append half-square
      
      if (after)
      {
         CGRect aRect= CGRectMake(cRect.origin.x + cRect.size.width / 2, cRect.origin.y,
                                  cRect.size.width / 2, cRect.size.height);
         
         CGContextRef context = UIGraphicsGetCurrentContext();
         CGContextSetFillColorWithColor(context, aColor.CGColor);
         CGContextFillRect(context, aRect);
      }
      else if (before)
      {
         CGRect aRect= CGRectMake(cRect.origin.x, cRect.origin.y,
                                  cRect.size.width / 2, cRect.size.height);
         
         CGContextRef context = UIGraphicsGetCurrentContext();
         CGContextSetFillColorWithColor(context, aColor.CGColor);
         CGContextFillRect(context, aRect);
      }
   }
}

//************************************************************
// fillCircleCell
//************************************************************

-(void)fillCircleCell:(CGRect)aRect withDay:(int)aDay andFont:(UIFont*)aFont andColor:(UIColor*)aColor andBackground:(UIColor*)aBackground
{
   CGRect cRect= CGRectMake(aRect.origin.x, aRect.origin.y + (aRect.size.height-aRect.size.width)/2 + 0.5,
                            aRect.size.width, aRect.size.width);
   
   CGRect bRect= CGRectMake(cRect.origin.x - 1.5, cRect.origin.y - 1.5,
                            cRect.size.width + 3.0, cRect.size.width + 3.0);
   
   CGContextRef context = UIGraphicsGetCurrentContext();
   CGContextSetFillColorWithColor(context, [UIColor colorNamed:@"cellBackground"].CGColor);
   CGContextFillEllipseInRect(context, bRect);
   
   CGContextSetFillColorWithColor(context, aBackground.CGColor);
   CGContextFillEllipseInRect(context, cRect);
   
   [self drawString:[NSString stringWithFormat:@"%d", aDay] withFont:aFont andColor:aColor andAlignment:NSTextAlignmentCenter inRect:aRect];
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
                                 NSParagraphStyleAttributeName: paragraphStyle };
   
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

#pragma mark - Marker Stuff

//************************************************************
// add marker
//************************************************************

-(void)addMarker:(LeaveInfo*)info
{
   int startYear= (int)[[NSCalendar currentCalendar] components:NSCalendarUnitYear fromDate:info.begin].year;
   int endYear= (int)[[NSCalendar currentCalendar] components:NSCalendarUnitYear fromDate:info.end].year;

   if (!(yearNum >= startYear && yearNum <= endYear))
      return;
   
   NSDateComponents* comps;
   NSArray* days= [Calculation getDistinctDays:info.begin to:info.end inMonth:na andYear:na];
   
   for (NSDate* date in days)
   {
      comps= [[NSCalendar currentCalendar] components:NSCalendarUnitYear | NSCalendarUnitMonth | NSCalendarUnitDay fromDate:date];

      int i= na;
      
      if (comps.year != yearNum)
         continue;
      
      while (markers[comps.month-1][comps.day-1][++i] && i < 100)
         ;
      
      if (i < 100 && !markers[comps.month-1][comps.day-1][i])
         markers[comps.month-1][comps.day-1][i]= info;
   }
   
   [self setNeedsDisplay];
}

//************************************************************
// clearMarkers
//************************************************************

-(void)clearMarkers
{
   memset(markers, 0, sizeof(markers));
   
   [self setNeedsDisplay];
}

#pragma mark - Touch Stuff

//************************************************************
// touchesEnded
//************************************************************

-(void)touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event
{
   UITouch* touch = [touches anyObject];
   CGPoint touchPoint = [touch locationInView:self];
   int touchMonth= na;
   int touchDay= na;
   
   if (self.popOver)
   {
      [self.popOver dismiss];
      self.popOver= nil;
      
      return;
   }
   
   for (int i= 0; i < 12; i++)
   {
      if (CGRectContainsPoint(monthRects[i], touchPoint))
      {
         touchMonth= i;
         break;
      }
   }
   
   for (int i= 0; i < 31 && touchMonth != na; i++)
   {
      if (CGRectContainsPoint(dayRects[touchMonth][i], touchPoint))
      {
         touchDay= i;
         break;
      }
   }
   
   if (touchMonth == na || touchDay == na)
      return;
   
   CGPoint tooltipPoint= CGPointMake(dayRects[touchMonth][touchDay].origin.x + dayRects[touchMonth][touchDay].size.width/2,
                                     dayRects[touchMonth][touchDay].origin.y + dayRects[touchMonth][touchDay].size.height/2);
   
   NSMutableArray* array= [NSMutableArray array];
   
   // (1) add holiday
   
   int i= na;
   
   while (markers[touchMonth][touchDay][++i] && i < 100)
      [array addObject:markers[touchMonth][touchDay][i]];
   
   // (2) add public holiday
   
   NSArray* publicHoliday= [[PublicHoliday instance] getPublicHolidayForDay:touchDay+1 inMonth:touchMonth+1 inYear:yearNum];
   
   if (publicHoliday && publicHoliday.count)
   {
      for (EKEvent* info in publicHoliday)
      {
         [array addObject:info];
      }
   }
   
   // (3) add free days
   
   NSString* key = [NSString stringWithFormat:@"%d%d", touchDay+1, touchMonth+1];
   
   if ([[Storage freedaysList] objectForKey:key])
      [array addObject:[[Storage freedaysList] valueForKey:key]];
   
   if (!array.count)
      return;
   
   self.popOver= [[[PopoverTable alloc] initWithValues:array atPoint:tooltipPoint inFrame:self.frame] autorelease];
   self.popOver.itemSelected= ^(int index)
   {
      LeaveInfo* info= [array objectAtIndex:index];
      
      [[Storage currentStorage] showAddDialog:info withBegin:nil endEnd:nil andYear:0 completion:^(void){ self.popOver= nil; }];
   };

   [self.popOver showInView:self];
}

@end

#pragma mark - Class CalendarView

//************************************************************
// class CalendarView
//************************************************************

@implementation CalendarView

//************************************************************
// initWithFrame
//************************************************************

-(id)initWithFrame:(CGRect)frame
{
   self= [super initWithFrame:frame];

   if (self)
   {
      yearNum= na;
      const double leftPadding= 35.0 * SCALEFACTOR;
      const double sepSpacing= 18.0 * SCALEFACTOR;
      
      self.backgroundColor= [UIColor colorNamed:@"cellBackground"];

      titleLabel= [[[UILabel alloc] initWithFrame:CGRectMake(leftPadding,
                                                             CALENDAR_TOP_PADDING,
                                                             150.0 * SCALEFACTOR,
                                                             TITLE_HEIGHT)] autorelease];
      
      titleLabel.font= [UIFont fontWithName:@"HelveticaNeue-Thin" size:25.0f];
      titleLabel.text= @"2015";
      titleLabel.textColor= [UIColor colorNamed:@"cellMainText"];

      [self addSubview:titleLabel];

      UIView* separator= [[[UIView alloc] initWithFrame:CGRectMake(leftPadding,
                                                                   titleLabel.frame.origin.y + titleLabel.frame.size.height + sepSpacing,
                                                                   frame.size.width - leftPadding,
                                                                   1.0)] autorelease];
      separator.backgroundColor= [UIColor colorNamed:@"separatorColor"];
      [self addSubview:separator];

      grid= 0;
      gridFrame= CGRectMake(leftPadding,
                            separator.frame.origin.y + separator.frame.size.height + (24.0 * SCALEFACTOR),
                            frame.size.width - leftPadding,
                            CALENDAR_HEIGHT - 1.0 - TITLE_HEIGHT);
   }

   return self;
}

//************************************************************
// showYear
//************************************************************

-(void)showYear:(int)year
{
   yearNum= year;
   titleLabel.text= [NSString stringWithFormat:@"%d", yearNum];
   
   if (grid)
      [grid removeFromSuperview];
   
   grid= [[[GridView alloc] initWithFrame:gridFrame andYear:year] autorelease];
   
   [self addSubview:grid];
}

//************************************************************
// reloadMarkers
//************************************************************

-(void)reloadMarkers
{
   [grid clearMarkers];
   
   NSDateComponents* comps= [[[NSDateComponents alloc] init] autorelease];
   
   comps.day= 1;
   comps.month= 1;
   comps.year= yearNum;
   
   NSDate* beginDate= [[NSCalendar currentCalendar] dateFromComponents:comps];
   
   comps.day= 31;
   comps.month= 12;
   comps.year= yearNum;
   
   NSDate* endDate= [[NSCalendar currentCalendar] dateFromComponents:comps];
   
   NSPredicate* pred= [NSPredicate predicateWithFormat:@"(begin >= %@ && begin <= %@) || (end >= %@ && end <= %@)", beginDate, endDate, beginDate, endDate];
   
   NSMutableArray* leave= [[Storage currentStorage] getLeaveForUsers:[SessionManager displayUserIds] withFilter:pred andSorting:nil];
   
   for (LeaveInfo* info in leave)
      [grid addMarker:info];
}

@end

#pragma mark - Class Calendar Page

//************************************************************
// class CalendarPage
//************************************************************

@implementation CalendarPage

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
   self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
   
   if (self)
   {
      // Custom initialization
      
      self.tabBarItem= [[[UITabBarItem alloc] initWithTitle:NSLocalizedString(@"Calendar", nil) image:[UIImage imageNamed:@"Tab_Calendar.png"] tag:1] autorelease];
      self.view.backgroundColor= [UIColor colorNamed:@"cellBackground"];
      self.calendarViews= [NSMutableArray array];

      CGRect bounds = [[UIScreen mainScreen] bounds];
      
      // (1) build container (Scrollview)
      
      int nPages= 20;
      int todayYear= (int)[[NSCalendar currentCalendar] components:NSCalendarUnitYear fromDate:[NSDate date]].year;
      
      self.scrollView.contentSize= CGSizeMake(bounds.size.width, nPages * CALENDAR_HEIGHT);
      
      // (2) by default, add this year +- 1 year subviews (3x CalendarView)
      
      int range= CALENDAR_YEAR_RANGE;
      
      for (int year= todayYear-range; year < todayYear+range; year++)
      {
         int index= year-todayYear+range;
         CGRect calendarFrame= CGRectMake(0.0, index * CALENDAR_HEIGHT, bounds.size.width, CALENDAR_HEIGHT);
         
         CalendarView* calendarView= [[[CalendarView alloc] initWithFrame:calendarFrame] autorelease];
         
         [calendarView showYear:year];
         
         [self.calendarViews addObject:calendarView];
         [self.scrollView addSubview:calendarView];
      }
      
      // (3) scroll to last page
      
      [self.scrollView setContentOffset:CGPointMake(0.0, CALENDAR_HEIGHT * 10) animated:NO];
      
      // (4) register several events
      
      [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(updateCalendar:) name:kUserLoggedIn object:nil];
      [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(updateCalendar:) name:kLeaveChanged object:nil];
      [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(updateCalendar:) name:kPublicHolidayEntriesLoaded object:nil];
      [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(updateCalendar:) name:kYearChangedNotification object:nil];
      [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(updateCalendar:) name:kImportFinished object:nil];
      [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(updateCalendar:) name:kICloudUpdate object:nil];
   }
   
   return self;
}

//************************************************************
// dealloc
//************************************************************

-(void)dealloc
{
   self.calendarViews= nil;
   [super dealloc];
}

//************************************************************
// pageTitle
//************************************************************

-(NSString*)pageTitle
{
   return NSLocalizedString(@"Calendar", nil);
}

//************************************************************
// updateCalendar
//************************************************************

-(void)updateCalendar:(NSNotification*) notification
{
   for (CalendarView* view in self.calendarViews)
      [view reloadMarkers];
}

@end
