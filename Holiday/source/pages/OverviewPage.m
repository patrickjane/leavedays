//************************************************************
// OverviewPage.m
// Holiday
//************************************************************
// Created by Patrick Fial on 28.01.12.
// Copyright 2014-2014 Patrick Fial. All rights reserved.
//************************************************************

//************************************************************
// includes
//************************************************************

#import "OverviewPage.h"
#import "JASidePanelController.h"
#import "TabController.h"
#import "Storage.h"
#import "Service.h"
#import "SessionManager.h"
#import "DonutView.h"
#import "YearChart.h"
#import "YearSummary.h"
#import "Pool.h"
#import "User.h"
#import "VacationDaysCell.h"
#import "Settings.h"
#import "Calculation.h"
#import "CsvCreator.h"

#pragma mark - UIView additions

//************************************************************
// class UIView
//************************************************************

@implementation UIView(Screenshots)

- (UIImage *)__takeSnapshot
{
   UIGraphicsBeginImageContextWithOptions(self.bounds.size, NO, [UIScreen mainScreen].scale);
   
   [self drawViewHierarchyInRect:self.bounds afterScreenUpdates:YES];
   
   // old style [self.layer renderInContext:UIGraphicsGetCurrentContext()];
   
   UIImage *image = UIGraphicsGetImageFromCurrentImageContext();
   UIGraphicsEndImageContext();
   return image;
}

@end

#pragma mark - UILabel additions

//************************************************************
// Class UILabel
//************************************************************

@implementation UILabel (dynamicSizeMeWidth)
- (void)resizeToStretch
{
   float width = [self expectedWidth];
   CGRect newFrame = [self frame];
   newFrame.size.width = width;
   [self setFrame:newFrame];
}

- (float)expectedWidth
{
   [self setNumberOfLines:1];
   CGSize expectedLabelSize = [[self text] sizeWithAttributes:@{NSFontAttributeName:self.font}];

   return expectedLabelSize.width + 10.0;
}

@end

#pragma mark - Class OverviewPageContent

//************************************************************
// Class OverviewPageContent
//************************************************************

@implementation OverviewPageContent

@synthesize donut, year, yearNum, detailsView;

//************************************************************
// initWithCoder
//************************************************************

-(id)initWithCoder:(NSCoder *)aDecoder
{
   self= [super initWithCoder:aDecoder];

   if (self)
   {
      self.yearNum= 0;
   }

   return self;
}

//************************************************************
// dealloc
//************************************************************

-(void)dealloc
{
   [super dealloc];
}

//************************************************************
// updateContent
//************************************************************

-(void)updateContent
{
   YearSummary* summary= [[Storage currentStorage] getYear:self.yearNum withUserId:[SessionManager activeUser].uuid];
   
   if (!summary)
   {
      NSLog(@"ERROR: OverviewPageContent cannot update data for non-existing year (%d) for active user", self.yearNum);
      return;
   }
   
   // (1) get current display year
   
   Pool* pool= [Storage poolOfArray:summary.pools withInternalName:@"residualleave"];
   
   // (2) update donut chart
   
   [self.donut update:summary.amount_with_pools.doubleValue withUsed:summary.amount_spent_with_pools.doubleValue andRemain:pool ? pool.remain.doubleValue : 0.0];
   
   // (3) draw chart according to used days
   
   yeararray years;
   clearYears(&years);
   
   int yearBeginMonth = [Settings userSettingInt:skYearBegin]-1;
   
   if (yearBeginMonth < 0 || yearBeginMonth > 11)
      yearBeginMonth= 0;
   
   for (int i= 0; i < 12; i++)
   {
      int month = (i+yearBeginMonth) % 12;
      
      years[i]= [[Storage currentStorage] getLeaveForMonth:month+1 inYear:self.yearNum + (month < yearBeginMonth ? 1 : 0)];
   }

   [self.year setDays:&years andYearUserd:summary.amount_spent_with_pools.doubleValue];
   
   self.detailsView.tableData= [NSMutableArray array];
   
   [self.detailsView.tableData addObject:@{@"name": NSLocalizedString(@"Total", nil), @"amount": summary.amount_with_pools, @"spent": summary.amount_spent_with_pools, @"remain": summary.amount_remain_with_pools }];
   [self.detailsView.tableData addObject:@{@"name": NSLocalizedString(@"Annual leave", nil), @"amount": summary.days_per_year, @"spent": summary.amount_spent, @"remain": summary.amount_remain }];

   for (Pool* pool in summary.pools)
   {
      [self.detailsView.tableData addObject:@{@"name": pool.category, @"amount": pool.pool, @"spent": pool.spent, @"remain": pool.remain, @"earned": pool.earned }];
      
      if ([pool.internalName isEqualToString:@"residualleave"] && pool.expired.doubleValue > 0.0)
         [self.detailsView.tableData addObject:@{@"name": [NSString stringWithFormat:@"%@ (%@)", pool.category, NSLocalizedString(@"expired", nil)], @"amount":[NSNumber numberWithFloat:0.0] , @"spent":pool.expired, @"remain": [NSNumber numberWithFloat:0.0], @"earned": [NSNumber numberWithFloat:0.0] }];
   }

   [self.detailsView reload];
}

@end

#pragma mark - Class OverviewPage

//************************************************************
// class OverviewPage
//************************************************************

@implementation OverviewPage

@synthesize scrollView, pageControl, contentPages;

-(id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
   self= [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
   
   if (self)
   {
      // tabbar controller
      
      displayMode= omDonut;
      self.tabBarItem= [[[UITabBarItem alloc] initWithTitle:[self pageTitle] image:[UIImage imageNamed:@"Tab_Overview.png"] tag:0] autorelease];
      self.scrollView.frame= [[UIScreen mainScreen] bounds];
      self.scrollView.scrollEnabled= YES;
      self.scrollView.pagingEnabled= YES;
      self.scrollView.delegate= self;
      
      currentContent= 0;

      [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handleYearChangedNotification:) name:kYearChangedNotification object:nil];
      [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handleLoggedInNotification:) name:kUserLoggedIn object:nil];
      [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handleYearInsertedNotification:) name:kInsertedNotification object:nil];
      [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handleYearDeletedNotification:) name:kDeletedNotification object:nil];
      [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(iCloudUpdate:) name:kICloudUpdate object:nil];
      [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(rebuild) name:kImportFinished object:nil];
      
      self.contentPages= [NSMutableArray array];
   }
   
   return self;
}

//************************************************************
// pageTitle
//************************************************************

-(NSString*)pageTitle
{
   return NSLocalizedString(@"Overview", nil);
}

//************************************************************
// viewDidLoad
//************************************************************

-(void)viewDidLoad
{
   [super viewDidLoad];
   
   UIBarButtonItem* switchItem=  [[[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemSearch target:self action:@selector(toggleMode)] autorelease];
   UIBarButtonItem* shareItem= [[[UIBarButtonItem alloc]
                                 initWithImage:[UIImage imageNamed:@"share.png"] style:UIBarButtonItemStylePlain
                                 target:self
                                 action:@selector(share)] autorelease];
   UIBarButtonItem* smallSpacer= [[[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFixedSpace target:nil action:nil] autorelease];
   smallSpacer.width = 10.0;

   UIBarButtonItem* smallSpacer2= [[[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFixedSpace target:nil action:nil] autorelease];
   smallSpacer2.width = 5.0;

   self.toolbar.items= [NSMutableArray arrayWithObjects:menuItem, smallSpacer, switchItem, spacer, titleItem, spacer, shareItem, smallSpacer2, addItem, nil];
}

-(void)toggleMode
{
   NSMutableArray* items= [[self.toolbar.items mutableCopy] autorelease];
   
   if (displayMode == omDonut)
   {
      displayMode= omDetails;
      [items replaceObjectAtIndex:2 withObject:[[[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemRefresh target:self action:@selector(toggleMode)] autorelease]];
      
      for (OverviewPageContent* content in self.contentPages)
         content.detailsView.hidden= NO;
   }
   else
   {
      displayMode= omDonut;
      [items replaceObjectAtIndex:2 withObject:[[[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemSearch target:self action:@selector(toggleMode)] autorelease]];

      for (OverviewPageContent* content in self.contentPages)
         content.detailsView.hidden= YES;
   }
   
   self.toolbar.items= items;
}

//************************************************************
// update
//************************************************************

-(void)layoutContentPages
{
   int currentYear= [Calculation getThisYear];
   int currentPage= na;
   int nPages= (int)[SessionManager displayUser].years.count;
   self.scrollView.contentSize= self.scrollView.frame.size;
   
   // (1) remove previously added content pages
   
   for (OverviewPageContent* content in self.contentPages)
      [content removeFromSuperview];
   
   [self.contentPages removeAllObjects];
   
   // (2) adjust page control
   
   if (!nPages)
      nPages= 1;
   
   currentContent= nil;
   self.pageControl.numberOfPages= nPages;
   self.pageControl.currentPage= 0;
   
   // (3) scrollview size
   
   self.scrollView.contentSize = CGSizeMake(self.scrollView.frame.size.width * nPages, self.scrollView.frame.size.height);
   
   // (4) add pages

   int i= 0;
   
   for (YearSummary* sum in [SessionManager displayUser].years)
   {
      CGFloat xOrigin = i * self.scrollView.frame.size.width;

      OverviewPageContent* content= [[[NSBundle mainBundle] loadNibNamed:@"OverviewPageContent_iPhone" owner:nil options:nil] lastObject];
      
      content.frame= CGRectMake(xOrigin, 0.0, self.scrollView.frame.size.width, self.scrollView.frame.size.height);
      content.donut.colorSpent= DETAILCOLOR;
      content.donut.colorOverspent= [UIColor lightGrayColor];
      content.donut.colorRemain= MAINCOLORDARK;
      content.donut.colorResidual= SECONDDETAILCOLOR;
      content.donut.colorUnused= [UIColor lightGrayColor];
      content.yearNum= sum.year.intValue;
      content.year.thisYear = sum.year.intValue;
      
      [self.scrollView addSubview:content];
      
      if (sum.year.intValue == currentYear)
         currentPage= i;
      
      [contentPages addObject:content];
      [content updateContent];
      
      i++;
   }
   
   if (currentPage != na)
      [self scrollToPage:currentPage];
   
   // (5) set details button correctly
   
   displayMode= omDonut;
   
   NSMutableArray* items= [self.toolbar.items mutableCopy];
   
   [items replaceObjectAtIndex:2 withObject:[[[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemSearch target:self action:@selector(toggleMode)] autorelease]];
   
   self.toolbar.items= items;
}

//************************************************************
// rebuild
//************************************************************

-(void)rebuild
{
   // add/remove any views for years that have been changes
   [self layoutContentPages];
}

//************************************************************
// update
//************************************************************

-(void)update
{
   // only update existing views, without replacing them
   
   for (OverviewPageContent* content in self.contentPages)
      [content updateContent];
}

//************************************************************
// iCloudUpdate
//************************************************************

-(void)iCloudUpdate:(id)sender
{
   [self update];
}

//************************************************************
// scroll to page
//************************************************************

-(void)scrollToPage:(int)page
{
   CGFloat offset= page * self.scrollView.frame.size.width;
   
   if (offset > self.scrollView.contentSize.width || !self.contentPages.count)
      return;

   [self.scrollView setContentOffset:CGPointMake(offset, 0.0) animated:NO];
   
   self.pageControl.currentPage = page;
   
   currentContent= [self.contentPages objectAtIndex:page];
   titleItem.title= [NSString stringWithFormat:@"%d", currentContent.yearNum];
}

#pragma mark - Notification Handling

//************************************************************
// update
//************************************************************

-(void)handleYearChangedNotification:(NSNotification*) notification
{
   NSNumber* year = nil;
   
   if (notification && notification.userInfo)
      year= [notification.userInfo objectForKey:@"year"];
      
   if (!year)
      year= [SessionManager currentYear].year;
   
   for (OverviewPageContent* content in self.contentPages)
      if (content.yearNum == year.intValue)
         [content updateContent];
   
   NSInteger days = [SessionManager currentYear].amount_remain_with_pools.integerValue;
   
   if ([Settings globalSettingBool:skShowBadge])
      [UIApplication sharedApplication].applicationIconBadgeNumber = days;
}

//************************************************************
// Insert
//************************************************************

-(void)handleYearInsertedNotification:(NSNotification*) notification
{
   [self rebuild];
}

//************************************************************
// Delete
//************************************************************

-(void)handleYearDeletedNotification:(NSNotification*) notification
{
   [self rebuild];
}

//************************************************************
// loggedin
//************************************************************

-(void)handleLoggedInNotification:(NSNotification*)notification
{
   [self rebuild];
}

#pragma mark - UIScrollViewDelegate

//***************************************************************************
// scrollViewDidScroll
//***************************************************************************

- (void)scrollViewDidScroll:(UIScrollView *)scrollView
{
   int pageNum= self.scrollView.contentOffset.x / self.scrollView.frame.size.width;
   
   self.pageControl.currentPage = pageNum;

   if (self.contentPages.count)
   {
      currentContent= [self.contentPages objectAtIndex:pageNum];
      titleItem.title= [NSString stringWithFormat:@"%d", currentContent.yearNum];
   }
}

#pragma mark - Share contents

//***************************************************************************
// Share
//***************************************************************************

-(void)share
{
   UIAlertController* actionSheet= [UIAlertController alertControllerWithTitle:NSLocalizedString(@"Share", nil) message:nil preferredStyle:UIAlertControllerStyleActionSheet];

   [actionSheet addAction:[UIAlertAction actionWithTitle:NSLocalizedString(@"Screenshot (current view)", nil) style:UIAlertActionStyleDefault handler:^(UIAlertAction* action)
                           {
                              UIImage* img = [currentContent __takeSnapshot];
                              UIActivityViewController* activity = [[[UIActivityViewController alloc] initWithActivityItems:[NSArray arrayWithObjects:img, nil] applicationActivities:nil] autorelease];

                              [self presentViewController:activity animated:YES completion:nil];
                           }]];
   
   [actionSheet addAction:[UIAlertAction actionWithTitle:NSLocalizedString(@"CSV File", nil) style:UIAlertActionStyleDefault handler:^(UIAlertAction* action)
                           {
                              CsvCreator* dvc= [[[CsvCreator alloc] initWithStyle:UITableViewStyleGrouped] autorelease];
                              UINavigationController* nvc= [[[UINavigationController alloc] initWithRootViewController:dvc] autorelease];
                              nvc.navigationBar.barStyle = UIStatusBarStyleLightContent;

                              [self presentViewController:nvc animated:YES completion:nil];
                           }]];
   
   [actionSheet addAction:[UIAlertAction actionWithTitle:NSLocalizedString(@"Cancel", nil) style:UIAlertActionStyleCancel handler:nil]];
   [self presentViewController:actionSheet animated:YES completion:nil];
   actionSheet.view.tintColor = MAINCOLORDARK;
}

@end
