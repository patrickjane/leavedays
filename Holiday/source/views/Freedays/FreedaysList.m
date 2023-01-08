//************************************************************
// FreedaysList.m
// Holiday
//************************************************************
// Created by Patrick Fial on 28.11.202
// Copyright 202-202 Patrick Fial. All rights reserved.
//************************************************************

//************************************************************
// includes
//************************************************************

#import "FreedaysList.h"
#import "Freeday.h"
#import "Service.h"
#import "FreedayEdit.h"
#import "Storage.h"
#import "SessionManager.h"
#import "User.h"

@implementation FreedaysList

@synthesize items;

// ************************************************************
// initWithStyle
// ************************************************************

- (id)initWithStyle:(UITableViewStyle)style
{
   self = [super initWithStyle:style];
   
   if (self)
   {
      // Custom initialization
      
      self.items= nil;
//      self.preferredContentSize= CGSizeMake(320.0, 360.0);
   }
   
   return self;
}

// ************************************************************
// dealloc
// ************************************************************

- (void)dealloc
{
   self.items= nil;
   [super dealloc];
}

// ************************************************************
// dateStringForFreeday
// ************************************************************

-(NSString*)dateStringForFreeday:(Freeday*)freeday
{
   NSDateComponents* comps = [[[NSDateComponents alloc] init] autorelease];
   comps.day = freeday.day.integerValue;
   comps.month = freeday.month.integerValue;
   
   NSDate* date = [[NSCalendar currentCalendar] dateFromComponents:comps];
   
   return [[Service dateFormatterFreeday] stringFromDate: date];
}

#pragma mark - View lifecycle

// ************************************************************
// viewDidLoad
// ************************************************************

- (void)viewDidLoad
{
   [self.tableView setSeparatorStyle:UITableViewCellSeparatorStyleSingleLine];
   
   self.navigationItem.title = NSLocalizedString(@"Free days", nil);
   
   UIBarButtonItem* addButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemAdd target:self action:@selector(addFreeday)];
   self.navigationItem.rightBarButtonItem = addButton;
   [addButton release];
   
   self.tableView.backgroundColor= DARKTABLEBACKCOLOR;
   self.tableView.separatorColor= DARKTABLESEPARATORCOLOR;
   
   NSArray* sorting = [NSArray arrayWithObjects:[NSSortDescriptor sortDescriptorWithKey:@"month" ascending:YES], [NSSortDescriptor sortDescriptorWithKey:@"day" ascending:YES], nil];
   
   self.items= [[SessionManager activeUser].freedays sortedArrayUsingDescriptors:sorting];
   
   [super viewDidLoad];
}

// ************************************************************
// viewWillAppear
// ************************************************************

-(void)viewWillAppear:(BOOL)animated
{
   NSArray* sorting = [NSArray arrayWithObjects:[NSSortDescriptor sortDescriptorWithKey:@"month" ascending:YES], [NSSortDescriptor sortDescriptorWithKey:@"day" ascending:YES], nil];
   self.items= [[SessionManager activeUser].freedays sortedArrayUsingDescriptors:sorting];
   [self.tableView reloadData];
   [super viewWillAppear:animated];
}

#pragma mark - Interaction

// ************************************************************
// addTimeTable
// ************************************************************

-(void)addFreeday
{
   Freeday* day= [Storage createFreeday:[SessionManager activeUser]];

   day.title = NSLocalizedString(@"New free day", nil);
   day.day= [NSNumber numberWithInt:1];
   day.month = [NSNumber numberWithInt:1];
   
   [[SessionManager activeUser] saveDocument:^(BOOL success)
    {
       NSArray* sorting = [NSArray arrayWithObjects:[NSSortDescriptor sortDescriptorWithKey:@"month" ascending:YES], [NSSortDescriptor sortDescriptorWithKey:@"day" ascending:YES], nil];
       self.items= [[SessionManager activeUser].freedays sortedArrayUsingDescriptors:sorting];
       [[self tableView] reloadData];
    }];
}

// ************************************************************
// saveSelection
// ************************************************************

- (void) saveSelection
{
   [self.navigationController popViewControllerAnimated:YES];
}

#pragma mark - Table view data source

// ************************************************************
// numberOfSectionsInTableView
// ************************************************************

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
   return 1;
}

// ************************************************************
// numberOfRowsInSection
// ************************************************************

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
   return [self.items count];
}

// ************************************************************
// cellForRowAtIndexPath
// ************************************************************

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
   static NSString *CellIdentifier = @"Cell";
   
   UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
   
   if (cell == nil)
   {
      cell= [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleValue1 reuseIdentifier:CellIdentifier] autorelease];
      cell.backgroundColor= DARKTABLEBACKCOLOR;
      cell.textLabel.textColor= DARKTABLETEXTCOLOR;
      cell.detailTextLabel.textColor= UIColorFromRGB(0x8e8e93);
   }
   
   Freeday* day= (Freeday*)[self.items objectAtIndex:indexPath.row];
   
   cell.textLabel.text = day.title;
   cell.detailTextLabel.text = [self dateStringForFreeday:day];

   return cell;
}

// *****************************************
// titleForHeaderInSection
// *****************************************

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
   return NSLocalizedString(@"Configure free days", nil);
}

// *****************************************
// titleForFooterInSection
// *****************************************

- (NSString *)tableView:(UITableView *)tableView titleForFooterInSection:(NSInteger)section
{
   return NSLocalizedString(@"Additional free days which will be considered non-working days every year (in addition to weekends and public holiday), and thus affect the calculation of leave duration", nil);
}

#pragma mark - Table view delegate

// ************************************************************
// didSelectRowAtIndexPath
// ************************************************************

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
   FreedayEdit* dvc = [[[FreedayEdit alloc] initWithStyle:UITableViewStyleGrouped] autorelease];

   dvc.day = [self.items objectAtIndex:indexPath.row];

   [self.navigationController pushViewController:dvc animated:YES];
}

@end
