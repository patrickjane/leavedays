//************************************************************
// TimeTableList.m
// Holiday
//************************************************************
// Created by Patrick Fial on 30.08.2011
// Copyright 2011-2015 Patrick Fial. All rights reserved.
//************************************************************

//************************************************************
// includes
//************************************************************

#import "TimeTableList.h"
#import "Timetable.h"
#import "Service.h"
#import "TimeTableEdit.h"
#import "Storage.h"
#import "SessionManager.h"
#import "User.h"

@implementation TimeTableList

@synthesize menuItems;
@synthesize selection;

// ************************************************************
// initWithStyle
// ************************************************************

- (id)initWithStyle:(UITableViewStyle)style
{
   self = [super initWithStyle:style];
   
   if (self) 
   {
      // Custom initialization
      
      self.menuItems= nil;
      self.selection= nil;
      self.preferredContentSize= CGSizeMake(320.0, 360.0);
   }
   
   return self;
}

// ************************************************************
// dealloc
// ************************************************************

- (void)dealloc
{
   self.menuItems= nil;
   self.selection= nil;
   
   [super dealloc];
}

#pragma mark - View lifecycle

// ************************************************************
// viewDidLoad
// ************************************************************

- (void)viewDidLoad
{
   [self.tableView setSeparatorStyle:UITableViewCellSeparatorStyleSingleLine];
   
   self.navigationItem.title = NSLocalizedString(@"Timetables", nil);
   
   UIBarButtonItem* addButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemAdd target:self action:@selector(addTimeTable)];
   self.navigationItem.rightBarButtonItem = addButton;
   [addButton release];
   
   self.tableView.backgroundColor= DARKTABLEBACKCOLOR;
   self.tableView.separatorColor= DARKTABLESEPARATORCOLOR;
   
   self.menuItems= [SessionManager activeUser].timetables;
   
   [super viewDidLoad];
}

// ************************************************************
// viewWillAppear
// ************************************************************

-(void)viewWillAppear:(BOOL)animated
{
   [self.tableView reloadData];
   
   [super viewWillAppear:animated];
}

#pragma mark - Interaction

// ************************************************************
// addTimeTable
// ************************************************************

-(void)addTimeTable
{
   Timetable* tt= [Storage createTimetable:[SessionManager activeUser]];

   tt.name = NSLocalizedString(@"New timetable", nil);
   tt.internalname= nil;
   tt.hours_total= [NSNumber numberWithDouble:40.0];
   tt.day_0 = [NSNumber numberWithDouble:0.0];
   tt.day_1 = [NSNumber numberWithDouble:8.0];
   tt.day_2 = [NSNumber numberWithDouble:8.0];
   tt.day_3 = [NSNumber numberWithDouble:8.0];
   tt.day_4 = [NSNumber numberWithDouble:8.0];
   tt.day_5 = [NSNumber numberWithDouble:8.0];
   tt.day_6 = [NSNumber numberWithDouble:0.0];
   tt.uuid = [Service createUUID];
   
   [[SessionManager activeUser] saveDocument:^(BOOL success)
    {
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
   return [self.menuItems count];
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
   }
   
   // Configure the cell...
   
   Timetable* tt= (Timetable*)[self.menuItems objectAtIndex:indexPath.row];
   
   cell.textLabel.text = tt.name;
   cell.detailTextLabel.text = [Service niceHours:[tt.hours_total doubleValue]];
   
   cell.backgroundColor= DARKTABLEBACKCOLOR;
   cell.textLabel.textColor= DARKTABLETEXTCOLOR;
   cell.detailTextLabel.textColor= UIColorFromRGB(0x8e8e93);

   return cell;
}

// *****************************************
// titleForHeaderInSection
// *****************************************

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section 
{
   return NSLocalizedString(@"Configure timetables", nil);
}

#pragma mark - Table view delegate

// ************************************************************
// didSelectRowAtIndexPath
// ************************************************************

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
   TimeTableEdit* dvc = [[TimeTableEdit alloc] initWithStyle:UITableViewStyleGrouped];

   dvc.timeTable= [self.menuItems objectAtIndex:indexPath.row];
   
   [self.navigationController pushViewController:dvc animated:YES];
   [dvc release];
}

@end
