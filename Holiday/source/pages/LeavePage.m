//************************************************************
// LeavePage.m
// Holiday
//************************************************************
// Created by Patrick Fial on 01.02.15.
// Copyright 2015-2015 Patrick Fial. All rights reserved.
//************************************************************

//************************************************************
// includes
//************************************************************

#import "Service.h"
#import "SessionManager.h"
#import "Storage.h"
#import "LeavePage.h"

#import "OverviewCell.h"
#import "LegendView.h"

#import "User.h"
#import "Pool.h"
#import "Category.h"
#import "YearSummary.h"
#import "LeaveInfo.h"
#import "JASidePanelController.h"
#import "TabController.h"
#import "VacationDaysCell.h"

#define LEGEND_ROW_HEIGHT 30.0

#pragma mark - class MonthSummary

//************************************************************
// class MonthSummary
//************************************************************

@implementation MonthSummary
@synthesize amount, category, unitTitle, earned, spent;
@end

#pragma mark - class MonthSummaries

//************************************************************
// class MonthSummaries
//************************************************************

@implementation MonthSummaries
@synthesize items, year, month;

-(id)init
{
   self = [super init];
   
   if (self)
   {
      self.items = [NSMutableArray array];
   }
   
   return self;
}

+(MonthSummaries*)summariesOfYear:(int)year andMonth:(int)month
{
   MonthSummaries* res = [[[MonthSummaries alloc] init] autorelease];
   
   res.year = year;
   res.month = month;
   
   return res;
}

@end

#pragma mark - Lifecycle

//************************************************************
// class LeavePage
//************************************************************

@implementation LeavePage

@synthesize items, keys, tableView, monthItems;

//************************************************************
// initWithNibName
//************************************************************

-(id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
   self= [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
   
   if (self)
   {
      displayMode= lldmLeave;
      
      self.keys= nil;
      self.items= nil;
      self.monthItems = nil;
      self.tabBarItem= [[[UITabBarItem alloc] initWithTitle:NSLocalizedString(@"Leave", nil) image:[UIImage imageNamed:@"Tab_List.png"] tag:0] autorelease];
      self.tableView.sectionIndexColor = [UIColor lightGrayColor];
      self.tableView.sectionIndexBackgroundColor = [UIColor clearColor];
      
      [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(filterByNotification) name:kInsertedNotification object:nil];
      [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(filterByNotification) name:kDeletedNotification object:nil];
      [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(filterByNotification) name:kYearChangedNotification object:nil];
      [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(filterByNotification) name:kICloudUpdate object:nil];
      [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(filterByNotification) name:kImportFinished object:nil];
   }
   
   return self;
}

//************************************************************
// dealloc
//************************************************************

-(void)dealloc
{
   self.items= nil;
   self.keys= nil;
   [super dealloc];
}

-(void)viewDidLoad
{
   [super viewDidLoad];
   
   UIBarButtonItem* switchItem=  [[[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"sum.png"] style:UIBarButtonItemStylePlain target:self action:@selector(toggleMode)] autorelease];
   UIBarButtonItem* smallSpacer= [[[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFixedSpace target:nil action:nil] autorelease];
   smallSpacer.width = 10.0;
   
   self.toolbar.items= [NSMutableArray arrayWithObjects:menuItem, smallSpacer, switchItem, spacer, titleItem, spacer, addItem, nil];
}

//************************************************************
// toggleMode (leave list or monthly view)
//************************************************************

-(void)toggleMode
{
   NSMutableArray* items= [self.toolbar.items mutableCopy];

   if (displayMode == lldmLeave)
   {
      displayMode= lldmMonthly;
      [items replaceObjectAtIndex:2 withObject:[[[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemRefresh target:self action:@selector(toggleMode)] autorelease]];
   }
   else
   {
      displayMode= lldmLeave;
      [items replaceObjectAtIndex:2 withObject:[[[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"sum.png"] style:UIBarButtonItemStylePlain target:self action:@selector(toggleMode)] autorelease]];
   }

   self.toolbar.items= items;

   [self filter];
}

//************************************************************
// viewDidLoad
//************************************************************

- (void)viewWillAppear:(BOOL)animated
{
   [self filter];
   
   [super viewWillAppear:animated];
}

//************************************************************
// pageTitle
//************************************************************

-(NSString*)pageTitle
{
   return NSLocalizedString(@"Leave", nil);
}

#pragma mark - Data

//************************************************************
// filter
//************************************************************

-(void)filter
{
   [self reallyFilter];
}

-(void)filterByNotification
{
   [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(reallyFilter) object:nil];
   [self performSelector:@selector(reallyFilter) withObject:nil afterDelay:2.0];
}

-(void)reallyFilter
{
   self.keys= nil;
   self.items= nil;
   self.monthItems = nil;
   
   if (displayMode == lldmLeave)
   {
      NSSortDescriptor* sort= [NSSortDescriptor sortDescriptorWithKey:@"begin" ascending:NO];
      NSArray* tmp= [[Storage currentStorage] getLeaveForUsers:[SessionManager displayUserIds] withFilter:nil andSorting:[NSArray arrayWithObject:sort]];
      
      self.items= [Service groupObjectsInArray:tmp byKey:^id<NSCopying>(id item) { return ((LeaveInfo*)item).year; }];
      self.keys = [[self.items.allKeys mutableCopy] autorelease];
      
      NSSortDescriptor* highestToLowest = [NSSortDescriptor sortDescriptorWithKey:@"self" ascending:NO];
      
      [self.keys sortUsingDescriptors:[NSArray arrayWithObject:highestToLowest]];
   }
   else
   {
      NSPredicate* pred= [NSPredicate predicateWithBlock:^(id obj, NSDictionary* bindings) {
         LeaveInfo* ifo= (LeaveInfo*)obj;
         CategoryRef* cat= ifo && ifo.category ? [Storage categoryForName:ifo.category ofUser:[SessionManager displayUser]] : nil;

         if (!cat || !cat.sumMonthly.boolValue)
            return NO;
         
         return YES;
      }];

      NSSortDescriptor* sort= [NSSortDescriptor sortDescriptorWithKey:@"begin" ascending:YES];
      NSArray* tmp= [[Storage currentStorage] getLeaveForUsers:[SessionManager displayUserIds] withFilter:pred andSorting:[NSArray arrayWithObject:sort]];

      NSMutableDictionary* poolCache= [NSMutableDictionary dictionary];
      NSMutableArray* items= [NSMutableArray array];

      for (LeaveInfo* ifo in tmp)
      {
         YearSummary* yearSummary = [[Storage currentStorage] getYear:ifo.year.intValue];
         CategoryRef* cat= ifo.category ? [Storage categoryForName:ifo.category ofUser:[SessionManager displayUser]] : nil;
         Pool* pool= yearSummary && cat ? [Storage poolOfArray:yearSummary.pools withName:ifo.category] : nil;
         
         MonthSummaries* monthItems = nil;
         
         for (MonthSummaries* s in items)
         {
            if (s.year == ifo.year.intValue && s.month == ifo.month.intValue)
            {
               monthItems = s;
               break;
            }
         }

         if (!monthItems)
         {
            monthItems= [MonthSummaries summariesOfYear:ifo.year.intValue andMonth:ifo.month.intValue];
            [items addObject:monthItems];
         }
         
         MonthSummary* monthSum= nil;
         
         for (MonthSummary* sum in monthItems.items)
         {
            if ([sum.category isEqualToString:ifo.category])
            {
               monthSum= sum;
               break;
            }
         }

         NSString* poolCacheKey = [NSString stringWithFormat:@"%@-%d", ifo.category, ifo.year.intValue];
         NSNumber* poolCacheValue = [poolCache valueForKey:poolCacheKey];
         double poolValue = poolCacheValue ? poolCacheValue.doubleValue : (pool ? pool.pool.doubleValue : 0.0);

         if (!monthSum)
         {
            monthSum= [[[MonthSummary alloc] init] autorelease];
            monthSum.category= ifo.category;
            monthSum.amount= poolValue;
            monthSum.earned = 0.0;
            monthSum.spent = 0.0;
            monthSum.unitTitle= cat ? (cat.savedAsHours.boolValue ? NSLocalizedString(@"Hours", nil) : NSLocalizedString(@"Days", nil)) : NSLocalizedString(@"Days", nil);
            [monthItems.items addObject:monthSum];
         }

         if (ifo.mode.integerValue == lmEarn)
         {
            monthSum.earned+= ifo.duration.doubleValue;
            [poolCache setValue:[NSNumber numberWithDouble:poolValue + ifo.duration.doubleValue] forKey:poolCacheKey];
         }
         else
         {
            monthSum.spent+= ifo.duration.doubleValue;
            [poolCache setValue:[NSNumber numberWithDouble:poolValue - ifo.duration.doubleValue] forKey:poolCacheKey];
         }
      }
      
      NSArray* descriptors = [NSArray arrayWithObjects:[NSSortDescriptor sortDescriptorWithKey:@"year" ascending:NO], [NSSortDescriptor sortDescriptorWithKey:@"month" ascending:NO], nil];
      
      self.monthItems = [items sortedArrayUsingDescriptors:descriptors];
   }
   
   [self.tableView reloadData];
}

#pragma mark - Table view data source

//************************************************************
// numberOfSectionsInTableView
//************************************************************

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
   if (displayMode == lldmLeave)
      return self.items.count ? self.items.count : 1;
   
   return self.monthItems.count ? self.monthItems.count+1 : 1;
}

//************************************************************
// numberOfRowsInSection
//************************************************************

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
   if (displayMode == lldmLeave)
   {
      if (!self.items.count)
         return 0;
      
      if (section == self.items.count)
         return 1;

      NSArray* array= [self.items objectForKey:[self.keys objectAtIndex:section]];
      return array.count;
   }

   if (section == self.monthItems.count)
      return 1;

   MonthSummaries* sums = [self.monthItems objectAtIndex:section];
   return sums.items.count;
}

//************************************************************
// cellForRowAtIndexPath
//************************************************************

- (UITableViewCell *)tableView:(UITableView *)aTableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
   if (displayMode == lldmLeave)
   {
      NSArray* array= [self.items objectForKey:[self.keys objectAtIndex:indexPath.section]];
      LeaveInfo* info= [array objectAtIndex:indexPath.row];
      OverviewCell* cell = (OverviewCell*)[aTableView dequeueReusableCellWithIdentifier:@"OverviewCell"];

      if (cell == nil)
      {
         NSArray* nibContents = [[NSBundle mainBundle] loadNibNamed:@"OverviewCell" owner:self options:nil];
         cell = [nibContents lastObject];
      }

      [cell fill:info];
      return cell;
   }
   else if (indexPath.section < self.monthItems.count)
   {
      MonthSummaries* sums = [self.monthItems objectAtIndex:indexPath.section];
      VacationDaysCell* cell = (VacationDaysCell*)[tableView dequeueReusableCellWithIdentifier:@"VacationDaysCell"];
      
      if (!cell)
      {
         cell= [[[NSBundle mainBundle] loadNibNamed:@"VacationDaysCell" owner:self options:nil] lastObject];
         cell.daysView.modeShort = YES;
      }
      
      MonthSummary* sum= [sums.items objectAtIndex:indexPath.row];
      CategoryRef* c= [Storage categoryForName:sum.category ofUser:[SessionManager displayUser]];

      cell.selectionStyle = UITableViewCellSelectionStyleNone;
      cell.userInteractionEnabled= NO;

      cell.labelTitle.text= c.name;
      cell.labelTitle.textColor= [Service colorString:c.color];
      
      [cell.daysView setValues:sum.amount and:sum.spent and:(sum.amount + sum.earned - sum.spent) /*remain*/ and:sum.earned];

      return cell;
   }
   
   UITableViewCell* cell = [tableView dequeueReusableCellWithIdentifier:@"Cell"];
   
   if (cell == nil)
   {
      cell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"Cell"] autorelease];
      cell.userInteractionEnabled= NO;
      
      double legendHeight= 15.0;
      
      LegendView* legend= [[[LegendView alloc] initWithFrame:CGRectMake(0.0, (LEGEND_ROW_HEIGHT - legendHeight)/2, cell.frame.size.width, legendHeight)] autorelease];
      
      double offset = 0.0;
      
      offset = [legend addLegendItem:NSLocalizedString(@"Earned", nil) color:EARNCOLOR offset:offset otherColor:nil skipSpacing:NO];
      offset = [legend addLegendItem:NSLocalizedString(@"Spent", nil) color:DETAILCOLOR offset:offset otherColor:nil skipSpacing:NO];
      offset = [legend addLegendItem:@"|" color:MAINCOLORDARK offset:offset otherColor:nil skipSpacing:NO];
      offset = [legend addLegendItem:NSLocalizedString(@"Rest", nil) color:[UIColor redColor] offset:offset otherColor:nil skipSpacing:YES];

      [cell addSubview:legend];
   }
   
   return cell;
}

// ************************************************************
// heightForRowAtIndexPath
// ************************************************************

-(double)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
   if (displayMode == lldmMonthly && self.monthItems.count && indexPath.section == self.monthItems.count)
      return LEGEND_ROW_HEIGHT;
   
   return tableView.rowHeight;
}

// ************************************************************
// titleForHeaderInSection
// ************************************************************

- (NSString*)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
   if (displayMode == lldmLeave)
   {
      if (!self.items.count)
         return NSLocalizedString(@"No entries", nil);
      
      return nil;
   }
   
   if (section < self.monthItems.count)
   {
      MonthSummaries* sums = [self.monthItems objectAtIndex:section];
      NSArray* names= [Service dateFormatter].monthSymbols;
      NSString* monthName= [names objectAtIndex:sums.month-1];

      return [NSString stringWithFormat:@"%@ %d", monthName, sums.year];
   }

   return NSLocalizedString(@"Legend", nil);
}

// ************************************************************
// sectionIndexTitlesForTableView
// ************************************************************

- (NSArray *)sectionIndexTitlesForTableView:(UITableView *)tableView
{
   if (displayMode == lldmMonthly)
      return nil;

   NSMutableArray* result = [NSMutableArray arrayWithCapacity:self.items.allKeys.count];

   [self.keys enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
      [result addObject:[[NSString stringWithFormat:@"%@", obj] substringFromIndex:2]];
   }];

   return result;
}

// ************************************************************
// sectionForSectionIndexTitle
// ************************************************************

- (NSInteger)tableView:(UITableView *)tableView sectionForSectionIndexTitle:(NSString *)title atIndex:(NSInteger)index
{
   return index;
}

#pragma mark - Table view delegate

// ************************************************************
// didSelectRowAtIndexPath
// ************************************************************

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
   if (displayMode == lldmMonthly)
      return;

   NSArray* array= [self.items objectForKey:[self.keys objectAtIndex:indexPath.section]];
   LeaveInfo* info= [array objectAtIndex:indexPath.row];
   
   [[Storage currentStorage] showAddDialog:info withBegin:nil endEnd:nil andYear:0 completion:^(){ [self filter]; }];
}
@end
