//************************************************************
// OverviewDetails.m
// Holiday
//************************************************************
// Created by Patrick Fial on 24.07.2018
// Copyright 2018-2018 Patrick Fial. All rights reserved.
//************************************************************

//************************************************************
// includes
//************************************************************

#import "OverviewDetails.h"
#import "Service.h"
#import "VacationDaysCell.h"
#import "SplitFillView.h"

#define TITLE_HEIGHT 40.0
#define TITLE_SPACING 10.0
#define LEGEND_HEIGHT 15.0
#define LEGEND_SPACING 10.0

#pragma mark - View Lifecycle

//************************************************************
// class OverviewDetails
//************************************************************

@implementation OverviewDetails

@synthesize tableView, tableData, legendView, legendSpacer;
@synthesize maxLengthSpent, maxLengthAmount, maxLengthEarned, maxLengthRemain;

//************************************************************
// initWithCoder
//************************************************************

-(id)initWithCoder:(NSCoder *)aDecoder
{
   self = [super initWithCoder:aDecoder];
   
   if (!self)
      return self;
   
   UILabel* title= [[UILabel alloc] initWithFrame:CGRectMake(0.0, 0.0, self.frame.size.width, TITLE_HEIGHT)];
   
   title.font= [UIFont systemFontOfSize:20.0];
   title.textColor= [UIColor colorNamed:@"cellSubText"];
   title.text= NSLocalizedString(@"Details", nil);
   title.textAlignment= NSTextAlignmentCenter;
   
   [self addSubview:title];
   
   UIView* spacer= [[[UIView alloc] initWithFrame:CGRectMake(0.0, TITLE_HEIGHT + (TITLE_SPACING/2), self.frame.size.width, 0.5)] autorelease];
   spacer.backgroundColor= [UIColor lightGrayColor];
   
   [self addSubview:spacer];
   
   int nRows= (int)self.tableData.count;
   double tableHeight = (nRows ? nRows : 3) * 35.0;
   
   if (tableHeight > (self.frame.size.height - TITLE_HEIGHT - LEGEND_HEIGHT - TITLE_SPACING - 10))
      tableHeight= (self.frame.size.height - TITLE_HEIGHT - LEGEND_HEIGHT - TITLE_SPACING - 10);
   
   self.tableView= [[[UITableView alloc] initWithFrame:CGRectMake(0.0, TITLE_HEIGHT + TITLE_SPACING, self.frame.size.width, tableHeight)] autorelease];
   self.tableView.dataSource= self;
   self.tableView.delegate= self;
   self.tableView.separatorStyle= UITableViewCellSeparatorStyleNone;
   self.tableView.separatorColor= [UIColor clearColor];
  
   [self addSubview:self.tableView];

   double legendYOffset = TITLE_HEIGHT + TITLE_SPACING + tableHeight + LEGEND_SPACING;
   
   self.legendSpacer= [[[UIView alloc] initWithFrame:CGRectMake(0.0, legendYOffset, self.frame.size.width, 0.5)] autorelease];
   self.legendSpacer.backgroundColor= [UIColor lightGrayColor];
   
   [self addSubview:self.legendSpacer];
   
   self.legendView = [[[LegendView alloc] initWithFrame:CGRectMake(0.0, legendYOffset, self.frame.size.width, LEGEND_HEIGHT)] autorelease];
   self.legendView.backgroundColor= [UIColor clearColor];
   
   double offset = 0.0;

   offset = [self.legendView addLegendItem:NSLocalizedString(@"Earned", nil) color:EARNCOLOR offset:offset otherColor:nil skipSpacing:NO];
   offset = [self.legendView addLegendItem:NSLocalizedString(@"Per year", nil) color:[UIColor lightGrayColor] offset:offset otherColor:nil skipSpacing:NO];
   offset = [self.legendView addLegendItem:NSLocalizedString(@"Spent", nil) color:DETAILCOLOR offset:offset otherColor:nil skipSpacing:NO];
   offset = [self.legendView addLegendItem:@"|" color:MAINCOLORDARK offset:offset otherColor:nil skipSpacing:NO];
   offset = [self.legendView addLegendItem:NSLocalizedString(@"Rest", nil) color:[UIColor redColor] offset:offset otherColor:nil skipSpacing:YES];

   [self addSubview:self.legendView];
   
   self.maxLengthRemain= self.maxLengthEarned= self.maxLengthAmount= self.maxLengthSpent= nil;

   return self;
}

//************************************************************
// dealloc
//************************************************************

-(void)dealloc
{
   [super dealloc];
   
   self.maxLengthRemain= self.maxLengthEarned= self.maxLengthAmount= self.maxLengthSpent= nil;
   self.legendSpacer= nil;
   self.legendView= nil;
   self.tableView= nil;
}

//************************************************************
// layoutSubviews
//************************************************************

-(void)layoutSubviews
{
   self.tableView.separatorStyle= UITableViewCellSeparatorStyleNone;
   self.tableView.separatorColor= [UIColor clearColor];
   [super layoutSubviews];
}

//************************************************************
// reload
//************************************************************

-(void)reload
{
   int nRows= (int)self.tableData.count;
   double tableHeight = (nRows ? nRows : 3) * 35.0;
   
   if (tableHeight > (self.frame.size.height - TITLE_HEIGHT - LEGEND_HEIGHT - TITLE_SPACING - 10))
      tableHeight= (self.frame.size.height - TITLE_HEIGHT - LEGEND_HEIGHT - TITLE_SPACING - 10);

   self.tableView.frame= CGRectMake(0.0, TITLE_HEIGHT + TITLE_SPACING, self.frame.size.width, tableHeight);
   
   double legendYOffset = TITLE_HEIGHT + TITLE_SPACING + tableHeight + LEGEND_SPACING;
   
   self.legendSpacer.frame = CGRectMake(0.0, legendYOffset, self.frame.size.width, 0.5);
   self.legendView.frame = CGRectMake(0.0, legendYOffset + 6.0, self.frame.size.width, LEGEND_HEIGHT);
   
   for (NSDictionary* dict in self.tableData)
   {
      NSString* amount= [[Service numberFormatter] stringFromNumber:[dict objectForKey:@"amount"]];
      NSString* spent= [[Service numberFormatter] stringFromNumber:[dict objectForKey:@"spent"]];
      NSString* remain= [[Service numberFormatter] stringFromNumber:[dict objectForKey:@"remain"]];
      NSString* earned= [[Service numberFormatter] stringFromNumber:[dict objectForKey:@"earned"]];
      
      if (!self.maxLengthAmount || self.maxLengthAmount.length < amount.length)
         self.maxLengthAmount= amount;
      
      if (!self.maxLengthSpent || self.maxLengthSpent.length < spent.length)
         self.maxLengthSpent= spent;

      if (!self.maxLengthRemain || self.maxLengthRemain.length < remain.length)
         self.maxLengthRemain= remain;

      if (!self.maxLengthEarned || self.maxLengthEarned.length < earned.length)
         self.maxLengthEarned= earned;
   }
   
   [self.tableView reloadData];
}

#pragma mark - UITableView Datasource

//************************************************************
// Tableview
//************************************************************

-(NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
   return 1;
}

-(NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
   return self.tableData ? self.tableData.count : 0;
}

-(UITableViewCell*)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
   VacationDaysCell* cell = (VacationDaysCell*)[tableView dequeueReusableCellWithIdentifier:@"VacationDaysCell"];
   NSDictionary* item= [self.tableData objectAtIndex:indexPath.row];

   if (!cell)
      cell= [[[NSBundle mainBundle] loadNibNamed:@"VacationDaysCell" owner:self options:nil] lastObject];

   cell.selectionStyle = UITableViewCellSelectionStyleNone;
   cell.labelTitle.text= [item valueForKey:@"name"];
   cell.daysView.maxLengthRemain= self.maxLengthRemain;
   cell.daysView.maxLengthAmount= self.maxLengthAmount;
   cell.daysView.maxLengthSpent= self.maxLengthSpent;
   cell.daysView.maxLengthEarned= self.maxLengthEarned;
   
   if ([item objectForKey:@"earned"])
      [cell.daysView setValues:[[item valueForKey:@"amount"] doubleValue] and:[[item valueForKey:@"spent"] doubleValue] and:[[item valueForKey:@"remain"] doubleValue] and:[[item valueForKey:@"earned"] doubleValue]];
   else
      [cell.daysView setValues:[[item valueForKey:@"amount"] doubleValue] and:[[item valueForKey:@"spent"] doubleValue] and:[[item valueForKey:@"remain"] doubleValue] and:0.0];
   
   return cell;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
   return 35.0;
}


@end
