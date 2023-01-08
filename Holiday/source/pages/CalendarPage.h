//************************************************************
// CalendarPage.h
// Holliday
//************************************************************
// Created by Patrick Fial on 26.12.14.
// Copyright 2014-2014 Patrick Fial. All rights reserved.
//************************************************************

//************************************************************
// includes
//************************************************************

#import "BasePage.h"

@class LeaveInfo;
@class PopoverTable;

@interface GridView : UIView
{
   int weekdays[7];
   int yearNum;
   int numberOfDaysInMonth[12];
   CGRect monthRects[12];
   CGRect dayRects[12][31];
   
   LeaveInfo* markers[12][31][100];
}

-(id)initWithFrame:(CGRect)frame andYear:(int)aYear;

-(void)drawRect:(CGRect)rect;
-(void)drawMonthRect:(CGRect)rect andMonth:(int)monthNum;
-(void)fillCell:(CGRect)aRect withColor:(UIColor*)aColor andBefore:(int)before andAfter:(int)after;

@property (nonatomic, retain) PopoverTable* popOver;
@property (nonatomic, retain) UIColor* darkerFillerColored;
@property (nonatomic, retain) UIColor* darkerFillerGrey;

@end


@interface CalendarView : UIView
{
   int yearNum;
   
   UILabel* titleLabel;
   GridView* grid;
   CGRect gridFrame;
}

-(id)initWithFrame:(CGRect)frame;
-(void)showYear:(int)year;
-(void)reloadMarkers;

@end


@interface CalendarPage : BasePage<UIScrollViewDelegate>

@property (nonatomic, retain) IBOutlet UIScrollView* scrollView;
@property (nonatomic, retain) NSMutableArray* calendarViews;

@end
