//************************************************************
// TimeTableSelection.h
// Holiday
//************************************************************
// Created by Patrick Fial on 23.10.2011
// Copyright 2011-2015 Patrick Fial. All rights reserved.
//************************************************************

//************************************************************
// includes
//************************************************************

#import "TimeTableSelection.h"
#import "TimeTableList.h"
#import "Timetable.h"
#import "Service.h"
#import "SessionManager.h"
#import "User.h"

@implementation TimeTableSelection

@synthesize timeTables;
@synthesize editedIndex;

#pragma mark - Lifecycle

// ************************************************************
// initWithStyle
// ************************************************************

- (id)initWithStyle:(UITableViewStyle)style
{
   self = [super initWithStyle:style];
   
   if (self) 
   {
      // Custom initialization
      
      self.timeTables= nil;
      self.editedIndex= nil;
   }
   
   return self;
}

-(void)dealloc
{
   self.timeTables= nil;
   self.editedIndex= nil;
   
   [super dealloc];
}

// ************************************************************
// initWithStyle
// ************************************************************

- (void)viewDidLoad
{
   [super viewDidLoad];
   
   self.navigationItem.rightBarButtonItem= [[[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemAdd target:self action:@selector(addRecord)] autorelease];
}

#pragma mark - Table view data source

// ************************************************************
// numberOfSectionsInTableView
// ************************************************************

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
   return self.timeTables.count;
}

// ************************************************************
// numberOfRowsInSection
// ************************************************************

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
   return 1;
}

// ************************************************************
// cellForRowAtIndexPath
// ************************************************************

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
   UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"Cell"];
   
   if (cell == nil) 
      cell= [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleValue1 reuseIdentifier:@"Cell"] autorelease];
   
   Timetable* tt= [self.timeTables objectAtIndex:indexPath.section];
   cell.textLabel.text= tt.name;
   
   return cell;
}

// ************************************************************
// titleForHeaderInSection
// ************************************************************

- (NSString*) tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
   if (self.timeTables.count == 1)
      return NSLocalizedString(@"Timetable", nil);
   
   NSString* tt= NSLocalizedString(@"Timetable", nil);
   NSString* w= NSLocalizedString(@"week", nil);
   
   return [NSString stringWithFormat:@"%@ %@ %d", tt, w, (int)section+1];
}

// ************************************************************
// titleForHeaderInSection
// ************************************************************

- (NSString*) tableView:(UITableView *)tableView titleForFooterInSection:(NSInteger)section
{
   if (section == self.timeTables.count - 1)
      return NSLocalizedString(@"Selected timetables (rotating)", nil);

   return nil;
}

// ************************************************************
// canEditRowAtIndexPath
// ************************************************************

- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath
{
   // disable deletion of last record
   
   if (self.timeTables.count == 1)
      return NO;
   
   return YES;
}

// ************************************************************
// addRecord
// ************************************************************

-(void) addRecord
{
   [self showTimeTableSheet:^(UIAlertController* actionSheet, Timetable* tt)
    {
       [actionSheet addAction:[UIAlertAction actionWithTitle:tt.name style:UIAlertActionStyleDefault handler:^(UIAlertAction* action)
                               {
                                  [self.timeTables addObject:tt];
                                  [[self tableView] reloadData];
                               }]];
    }];
}

// ************************************************************
// trailingSwipeActionsConfigurationForRowAtIndexPath
// ************************************************************

- (UISwipeActionsConfiguration *)tableView:(UITableView *)tableView trailingSwipeActionsConfigurationForRowAtIndexPath:(NSIndexPath *)indexPath
{
   UIContextualAction* act = [UIContextualAction contextualActionWithStyle:UIContextualActionStyleDestructive title:NSLocalizedString(@"Remove", nil) handler:^(UIContextualAction* action, UIView *sourceView, void (^completionHandler)(BOOL actionPerformed))
   {
      // show UIActionSheet
      
      [self.timeTables removeObjectAtIndex:indexPath.section];
      [[self tableView] reloadData];
      completionHandler(YES);
   }];
   
   return [UISwipeActionsConfiguration configurationWithActions:[NSArray arrayWithObject: act]];
}

#pragma mark - Table view delegate

// ************************************************************
// didSelectRowAtIndexPath
// ************************************************************

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
   [self showTimeTableSheet:^(UIAlertController* actionSheet, Timetable* tt)
   {
      [actionSheet addAction:[UIAlertAction actionWithTitle:tt.name style:UIAlertActionStyleDefault handler:^(UIAlertAction* action)
                              {
                                 [self.tableView reloadRowsAtIndexPaths:[NSArray arrayWithObject:indexPath] withRowAnimation:YES];
                                 [self.tableView reloadData];
                              }]];
   }];
}

// ************************************************************
// showTimeTableSheet
// ************************************************************

-(void)showTimeTableSheet:(void (^)(UIAlertController* actionSheet, Timetable* tt))processor
{
   UIAlertController* actionSheet= [UIAlertController alertControllerWithTitle:nil message:nil preferredStyle:UIAlertControllerStyleActionSheet];
   NSArray* allTables= [SessionManager activeUser].timetables;
   
   for (Timetable* tt in allTables)
      processor(actionSheet, tt);
   
   [actionSheet addAction:[UIAlertAction actionWithTitle:NSLocalizedString(@"Cancel", nil) style:UIAlertActionStyleCancel handler:nil]];
   [self presentViewController:actionSheet animated:YES completion:nil];
   actionSheet.view.tintColor = MAINCOLORDARK;
   
}

@end
