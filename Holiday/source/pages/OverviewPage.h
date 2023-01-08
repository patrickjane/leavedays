//************************************************************
// OverviewPage.h
// Holiday
//************************************************************
// Created by Patrick Fial on 28.01.12.
// Copyright 2014-2014 Patrick Fial. All rights reserved.
//************************************************************

//************************************************************
// includes
//************************************************************

#import <UIKit/UIKit.h>
#import "BasePage.h"
#import "OverviewDetails.h"

@class DonutView;
@class YearChart;

@class YearSummary;

enum OverviewMode
{
   omDonut,
   omDetails
};

//************************************************************
// class OverviewPageContent
//************************************************************

@interface OverviewPageContent : UIView

@property (nonatomic, retain) IBOutlet DonutView* donut;
@property (nonatomic, retain) IBOutlet YearChart* year;
@property (nonatomic, retain) IBOutlet OverviewDetails* detailsView;
@property (nonatomic, assign) int yearNum;

-(void)updateContent;

@end

//************************************************************
// class OverviewPage
//************************************************************

@interface OverviewPage : BasePage <UIScrollViewDelegate>
{
   OverviewPageContent* currentContent;
   int displayMode;
}

@property (nonatomic, retain) IBOutlet UIScrollView* scrollView;
@property (nonatomic, retain) IBOutlet UIPageControl* pageControl;
@property (nonatomic, retain) NSMutableArray* contentPages;

-(void)scrollToPage:(int)page;

@end
