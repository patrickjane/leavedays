//************************************************************
// AnnualLeaveListController.m
// Annual Leave iPad
//************************************************************
// Created by Patrick Fial on 14.08.11.
// Copyright 2011-2014 Patrick Fial. All rights reserved.
//************************************************************

//************************************************************
// includes
//************************************************************

#import "AnnualLeaveListController.h"
#import "AnnualLeaveController.h"
#import "Service.h"
#import "Settings.h"
#import "Calculation.h"
#import "YearSummary.h"
#import "User.h"
#import "SessionManager.h"
#import "Storage.h"
#import "ActionPicker.h"

//************************************************************
// class AnnualLeaveListController
//************************************************************

@implementation AnnualLeaveListController

@synthesize items;
@synthesize yearList;
@synthesize selectedString;
@synthesize isModal;

#pragma mark - Lifecycle

// *****************************************
// initWithStyle
// *****************************************

- (id)initWithStyle:(UITableViewStyle)style andYears:(NSArray*)years
{
   self = [super initWithStyle:UITableViewStyleGrouped];
   
   if (self) 
   {
      // Custom initialization
      
      self.items= years;
      self.yearList= [Storage getYearNumberList];
      
      self.selectedString= nil;
      self.isModal= NO;
   }
   
   return self;
}

// *****************************************
// dealloc
// *****************************************

- (void)dealloc
{
   self.items= nil;
   self.yearList= nil;
   self.selectedString= nil;
   
   [super dealloc];
}

#pragma mark - View lifecycle

// *****************************************
// viewWillAppear
// *****************************************

-(void)viewWillAppear:(BOOL)animated
{
   self.yearList= [SessionManager displayUser].years;
   
   [self.tableView reloadData];
}

// *****************************************
// viewDidLoad
// *****************************************

- (void)viewDidLoad
{
   self.navigationItem.title = NSLocalizedString(@"Annual leave", nil);
   self.tableView.backgroundColor= DARKTABLEBACKCOLOR;
   self.tableView.separatorColor= DARKTABLESEPARATORCOLOR;

   UIBarButtonItem* addButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemAdd target:self action:@selector(addYear:)];
   self.navigationItem.rightBarButtonItem = addButton;
   [addButton release];
   
   if (self.isModal)
   {
      UIBarButtonItem* closeButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemDone target:self action:@selector(dismiss:)];
      self.navigationItem.leftBarButtonItem = closeButton;
      [closeButton release];
   }
   
   [super viewDidLoad];
}

// *****************************************
// dismiss
// *****************************************

-(void)dismiss:(id)sender
{
   [self dismissViewControllerAnimated:YES completion:^{}];
}

// *****************************************
// addYear
// *****************************************

- (void) addYear:(id)sender
{
   int currentYear= (int)[[NSCalendar currentCalendar] components:NSCalendarUnitYear fromDate:[NSDate date]].year;
   int selection= 0;
   NSMutableArray* values = [NSMutableArray array];
   
   for (int i= 2030; i >= 2000; i--)
   {
      BOOL have= FALSE;
      
      for (YearSummary* info in self.items)
      {
         if (info.year.intValue == i)
         {
            have = TRUE;
            break;
         }
      }
      
      if (!have)
      {
         if (i >= currentYear)
            selection= i;
         
         [values addObject:[NSString stringWithFormat:@"%d", i]];
      }
   }
   
   ActionPicker* picker= [[[ActionPicker alloc] initWithValues:values andSelection:[NSString stringWithFormat:@"%d", selection]] autorelease];
   
   picker.saveOnDismiss = TRUE;
   picker.valueChanged= ^(NSString* value)
   {
      int year = value.intValue;
      YearSummary* sum= [[Storage currentStorage] createYearSummary:year];
      
      if (sum)
         ;
      else
         [Service alert:NSLocalizedString(@"Error", nil) withText:NSLocalizedString(@"Failed to save data", nil) andError:nil forController:self completion:nil];
      
      [[Storage currentStorage] saveYear:sum completion:^(BOOL success)
       {
          [self.tableView reloadData];
       }];
   };
   
   [picker show];
}

// *****************************************
// setString
// *****************************************

-(void)setString:(NSString *)string
{
   self.selectedString= string;
}

#pragma mark - Table view data source

// *****************************************
// numberOfSectionsInTableView
// *****************************************

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
   return 1;
}

// *****************************************
// numberOfRowsInSection
// *****************************************

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
   return [self.items count];
}

// ************************************************************
// titleForHeaderInSection
// ************************************************************

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section 
{
   return NSLocalizedString(@"Select year to configure", nil);
}

// *****************************************
// cellForRowAtIndexPath
// *****************************************

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
   UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"Cell"];
   
   if (cell == nil) 
   {
      cell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleValue1 reuseIdentifier:@"Cell"] autorelease];
      [cell setAccessoryType:UITableViewCellAccessoryDisclosureIndicator];
      cell.backgroundColor= DARKTABLEBACKCOLOR;
      cell.textLabel.textColor= DARKTABLETEXTCOLOR;
   }
   
   YearSummary* info= [self.items objectAtIndex:indexPath.row];
   
   cell.textLabel.text = [NSString stringWithFormat:@"%@ %d", 
                          NSLocalizedString(@"Year", nil),
                          info.year.intValue];
   
   NSString* detailText= [Service niceDuration:info.amount_with_pools.doubleValue withCategory:nil];  // unit: 0 days, 1 hours
   
   cell.detailTextLabel.text = detailText;
   
   return cell;
}

#pragma mark - Table view delegate

// *****************************************
// didSelectRowAtIndexPath
// *****************************************

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
   AnnualLeaveController* dvc= [[[AnnualLeaveController alloc] init] autorelease];
   
   YearSummary* info= [self.items objectAtIndex:indexPath.row];

   dvc.myYear = info;
  
   [self.navigationController pushViewController:dvc animated:YES];
}

// ************************************************************
// editingStyleForRowAtIndexPath
// ************************************************************

- (UITableViewCellEditingStyle)tableView:(UITableView *)aTableView editingStyleForRowAtIndexPath:(NSIndexPath *)indexPath
{
   YearSummary* info= [self.items objectAtIndex:indexPath.row];

   if (info == [SessionManager currentYear])
      return UITableViewCellEditingStyleNone;
   
   return UITableViewCellEditingStyleDelete;
}

// ************************************************************
// commitEditingStyle
// ************************************************************

- (void)tableView:(UITableView *)aTableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath
{
   if (editingStyle == UITableViewCellEditingStyleDelete)
   {
      YearSummary* info= [self.items objectAtIndex:indexPath.row];

      UIAlertController* actionSheet= [UIAlertController alertControllerWithTitle:NSLocalizedString(@"Confirmation", nil) message:NSLocalizedString(@"Deleting a whole year deletes all records of that year too, This operation cannot be undone. Continue?", nil) preferredStyle:UIAlertControllerStyleActionSheet];
      
      [actionSheet addAction:[UIAlertAction actionWithTitle:NSLocalizedString(@"Delete year and all associated records", nil) style:UIAlertActionStyleDestructive handler:^(UIAlertAction* action)
                              {
                                 [[Storage currentStorage] deleteYear:info completion:^(BOOL success)
                                  {
                                     if (!success)
                                        [Service alert:NSLocalizedString(@"Error", nil) withText:NSLocalizedString(@"Failed to delete year", nil) andError:nil forController:self completion:nil];
                                     
                                     [self.tableView reloadData];
                                  }];
                              }]];
      
      [actionSheet addAction:[UIAlertAction actionWithTitle:NSLocalizedString(@"Cancel", nil) style:UIAlertActionStyleCancel handler:nil]];
      [self presentViewController:actionSheet animated:YES completion:nil];
      actionSheet.view.tintColor = MAINCOLORDARK;
   }
}

@end
