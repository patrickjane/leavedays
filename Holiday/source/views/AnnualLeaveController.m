//************************************************************
// AnnualLeaveController.m
// Annual Leave iPad
//************************************************************
// Created by Patrick Fial on 14.08.11.
// Copyright 2011-2014 Patrick Fial. All rights reserved.
//************************************************************

#import <CoreData/CoreData.h>

#import "AnnualLeaveController.h"
#import "Service.h"
#import "Settings.h"
#import "TextCell.h"
#import "Pool.h"
#import <QuartzCore/QuartzCore.h>
#import "Category.h"
#import "Calculation.h"
#import "YearSummary.h"
#import "User.h"
#import "SessionManager.h"

//************************************************************
// class AnnualLeaveController
//************************************************************

@implementation AnnualLeaveController

@synthesize myYear;
@synthesize editedIndex;
@synthesize tableView;
@synthesize toolBar;
@synthesize wizardMode;

#pragma mark - Lifecycle

// ************************************************************
// initWithStyle
// ************************************************************

- (id)init
{
   self = [super init];
   
   if (self) 
   {
      // Custom initialization
      
      noChanges = 1;
      
      self.myYear= nil;
      self.editedIndex= nil;
      self.wizardMode= NO;
      
      self.tableView= nil;
      self.toolBar= nil;
   }
   
   return self;
}

// ************************************************************
// dealloc
// ************************************************************

- (void)dealloc
{
   self.myYear= nil;
   self.editedIndex= nil;

   [super dealloc];
}

// ************************************************************
// loadView
// ************************************************************

- (void)loadView
{
   // container
   
   UIView* contentView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 320, 480)];
   contentView.autoresizesSubviews = YES;
   contentView.autoresizingMask = (UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight);
   contentView.backgroundColor = [UIColor clearColor];
  
   [self setView:contentView];
   [contentView release];
   
   // table
   
   self.tableView = [[[UITableView alloc] initWithFrame:CGRectMake(0, 0, 320, 480) style:UITableViewStyleGrouped] autorelease];
   
   [tableView setAutoresizesSubviews:YES];
   [tableView setAutoresizingMask:(UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight)];
   
   [self.tableView setDataSource:self];
   [self.tableView setDelegate:self];
   
   [[self view] addSubview:self.tableView];

}

#pragma mark - View lifecycle

// ************************************************************
// viewDidLoad
// ************************************************************

- (void)viewDidLoad
{
   [super viewDidLoad];
   
   self.tableView.backgroundColor= DARKTABLEBACKCOLOR;
   self.tableView.separatorColor= DARKTABLESEPARATORCOLOR;
   self.navigationItem.title = NSLocalizedString(@"Annual leave", nil);

   self.navigationItem.leftBarButtonItem= [[UIBarButtonItem alloc] initWithTitle:NSLocalizedString(@"Done", nil) style:UIBarButtonItemStylePlain target:self action:@selector(dismiss)];
   
   UIBarButtonItem* addButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemAdd target:self action:@selector(addPool)];
   self.navigationItem.rightBarButtonItem = addButton;
   [addButton release];
}

// ************************************************************
// viewDidUnload
// ************************************************************

-(void)dismiss
{
   if (noChanges)
   {
      [self.navigationController popViewControllerAnimated:YES];
      return;
   }

   [Calculation recalculateYearSummary:self.myYear withLastYearRemain:0.0 setRemain:false completion:^(BOOL success)
    {
       if (!success)
          [Service alert:NSLocalizedString(@"Error", nil) withText:NSLocalizedString(@"Failed to save data", nil) andError:nil forController:self completion:nil];

       [self.navigationController popViewControllerAnimated:YES];

       if (self.myYear == [SessionManager currentYear])
          [[NSNotificationCenter defaultCenter] postNotificationName:kYearChangedNotification object:self userInfo:nil];
    }];
}

#pragma mark - Table view data source

// ************************************************************
// numberOfSectionsInTableView
// ************************************************************

- (NSInteger)numberOfSectionsInTableView:(UITableView *)aTableView
{
   return 3;
}

// ************************************************************
// numberOfRowsInSection
// ************************************************************

- (NSInteger)tableView:(UITableView *)aTableView numberOfRowsInSection:(NSInteger)section
{
   if (section == 0 || section == 2)
      return 1;

   return self.myYear.pools.count;
}

// ************************************************************
// cellForRowAtIndexPath
// ************************************************************

- (UITableViewCell *)tableView:(UITableView *)aTableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
   // annual leave

   NSNumberFormatter* numberFormatter= [Service numberFormatter];

   if (indexPath.section == 2)
   {
      UITableViewCell* cell= [tableView dequeueReusableCellWithIdentifier:@"Cell"];
      
      if (cell == nil)
      {
         cell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleValue1 reuseIdentifier:@"Cell"] autorelease];
         cell.backgroundColor= DARKTABLEBACKCOLOR;
         cell.textLabel.textColor= DARKTABLETEXTCOLOR;
         cell.detailTextLabel.textColor= [UIColor colorNamed:@"cellSubText"];
      }
      
      double total= [self.myYear.amount_with_pools doubleValue];
      
      cell.textLabel.text = [Settings userSettingInt:skUnit] ? NSLocalizedString(@"Hours", nil) : NSLocalizedString(@"Days", nil);
      cell.detailTextLabel.text = [numberFormatter stringFromNumber:[NSNumber numberWithDouble:total]];
      
      return cell;
   }

   // pools and annual leave in edit mode
   
   TextCell* textCell = (TextCell*)[tableView dequeueReusableCellWithIdentifier:@"TextCell"];
   
   if (textCell == nil)
   {
      NSArray* nibContents = [[NSBundle mainBundle] loadNibNamed:@"TextCell_Small" owner:self options:nil];
      textCell = [nibContents lastObject]; 
      textCell.selectionStyle = UITableViewCellSelectionStyleNone;
      textCell.textField.delegate = self;
      textCell.textField.attributedPlaceholder = [[[NSAttributedString alloc] initWithString:NSLocalizedString(@"Enter amount", nil) attributes:@{NSForegroundColorAttributeName:[UIColor darkGrayColor]}] autorelease];
      
      textCell.backgroundColor= DARKTABLEBACKCOLOR;
      textCell.label.textColor= DARKTABLETEXTCOLOR;
   }

   textCell.textField.keyboardType= [Service keyboardTypeForType:[self typeForIndex:indexPath]];

   if (indexPath.section == 0)
   {
      // leave year's own pool

      textCell.label.text = [Settings userSettingInt:skUnit] ? NSLocalizedString(@"Hours per year", nil) : NSLocalizedString(@"Days per year", nil);
      textCell.textField.text = [numberFormatter stringFromNumber:myYear.days_per_year];
   }
   else if (indexPath.section == 1)
   {
      // pools
      
      Pool* pool= [self.myYear.pools objectAtIndex:indexPath.row];
      
      textCell.label.text = pool.category;
      textCell.textField.text = [numberFormatter stringFromNumber:pool.pool];
   }
   
   return textCell;
}

// ************************************************************
// typeForIndex
// ************************************************************

-(int)typeForIndex:(NSIndexPath *)idx
{
   return tpNumber;
}

// ************************************************************
// titleForHeaderInSection
// ************************************************************

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section 
{
   switch (section)
   {
      // annual leave
         
      case 0: return  [NSString stringWithFormat:@"%@ %d", NSLocalizedString(@"Annual leave", nil), self.myYear.year.intValue];
         
      // pools
         
      case 1: return NSLocalizedString(@"Categories", nil);
         
      // total
         
      case 2: return NSLocalizedString(@"Total", nil);
         
      default: break;
   }
   
   return nil;
}

// ************************************************************
// titleForFooterInSection
// ************************************************************

- (NSString *)tableView:(UITableView *)tableView titleForFooterInSection:(NSInteger)section 
{
   switch (section)
   {
      case 1: 
      {
         if (![self tableView:[self tableView] numberOfRowsInSection:1])
         {
            if ([Settings userSettingInt:skUnit])
               return NSLocalizedString(@"No additional hours configured yet. Tap the + button to add hours for a specific category.", nil);
            
            return NSLocalizedString(@"No additional days configured yet. Tap the + button to add days for a specific category.", nil);
         }
         
         break;
      }
         
      case 2: 
      {
         if (![Settings userSettingInt:skUnit])
            return NSLocalizedString(@"When adding leave, days will be substracted from available pools first, until pool remain reaches zero. After that, days are substracted from annual leave days", nil);
         
         return NSLocalizedString(@"When adding leave, hours will be substracted from available pools first, until pool remain reaches zero. After that, hours are substracted from annual leave hours", nil);
      }
         
      default: break;
   }
   
   return nil;
}

#pragma mark - Pools

// *****************************************
// add pool
// *****************************************

- (BOOL)addPool
{
   CategoryOverviewController* cat= [[[CategoryOverviewController alloc] init] autorelease];
   cat.mode= tpSelectPool;
   cat.colorMode = mdDark;
   cat.delegate= self;
   
   [self.navigationController pushViewController:cat animated:YES];
   noChanges = 0;
   
   return true;
}

#pragma mark - CategoryViewControllerDelegate

// ************************************************************
// setNewCategoryName
// ************************************************************

- (void)setNewCategory:(CategoryRef*)category
{
   noChanges = 0;
   
   Pool* pool= nil;

   if (!category)
      return;
   
   for (pool in self.myYear.pools)
      if ([pool.category isEqualToString:category.name])
         return;
   
   pool = [[[Pool alloc] init] autorelease];
   
   pool.pool= [NSNumber numberWithDouble:0.0];
   pool.spent= [NSNumber numberWithDouble:0.0];
   pool.expired= [NSNumber numberWithDouble:0.0];
   pool.remain=  [NSNumber numberWithDouble:0.0];
   pool.earned=  [NSNumber numberWithDouble:0.0];
   pool.year= self.myYear.year;
   pool.category= category.name;
   pool.internalName= category.internalName;
   
   [self.myYear.pools addObject:pool];
   
   [[self tableView] reloadData];
}

// ************************************************************
// setNewCategories (required by protocol but unused)
// ************************************************************

-(void)setNewCategories:(NSMutableArray *)categories
{
}

#pragma mark -
#pragma mark UITextField delegate

// ************************************************************
// textFieldShouldBeginEditing
// ************************************************************

-(BOOL)textFieldShouldBeginEditing:(UITextField *)textField
{
   noChanges = 0;
   
   id view = [textField superview];
   
   while (view && [view isKindOfClass:[UITableViewCell class]] == NO)
      view = [view superview];
   
   UITableViewCell* v = (UITableViewCell*)view;
   
   self.editedIndex = [[self tableView] indexPathForCell:v];
   
   if ([textField.text isEqualToString:@"0"])
      textField.text= nil;
   
   return YES;
}

// ************************************************************
// textFieldDidEndEditing
// ************************************************************

-(void)textFieldDidEndEditing:(UITextField *)textField
{
   if (!textField.text || !textField.text.length)
      textField.text= @"0";
}

// ************************************************************
// shouldChangeCharactersInRange
// ************************************************************

- (BOOL)textField:(UITextField *)aTextField shouldChangeCharactersInRange:(NSRange)range replacementString:(NSString *)string 
{
   return [Service textField:aTextField shouldChangeCharactersInRange:range replacementString:string andType:[self typeForIndex:self.editedIndex] andFormatter:[Service numberFormatter] andDelegate:self];
}

// ************************************************************
// textFieldShouldReturn
// ************************************************************

- (BOOL)textFieldShouldReturn:(UITextField *)field 
{
   double total= [self.myYear.days_per_year doubleValue];
   total += [[self.myYear.pools valueForKeyPath:@"@sum.pool"] doubleValue];
   
   [self.myYear setAmount_with_pools:[NSNumber numberWithDouble:total]];
   
   [[self tableView] reloadData];
   [field resignFirstResponder];
   
   return YES;
}

#pragma mark - TextInputCellDelegate

// ************************************************************
// saveText
// ************************************************************

-(void)saveText:(NSString *)newText fromTextField:(UITextField*)aTextField
{
   if (![newText length])
      return;

   if (self.editedIndex.section == 0)
   {
      self.myYear.days_per_year= [[Service numberFormatter] numberFromString:newText];
      
      double total= [myYear.days_per_year doubleValue];
      total += [[self.myYear.pools valueForKeyPath:@"@sum.pool"] doubleValue];

      self.myYear.amount_with_pools= [NSNumber numberWithDouble:total];
   }
   else
   {
      Pool* pool= [self.myYear.pools objectAtIndex:self.editedIndex.row];
      pool.pool= [[Service numberFormatter] numberFromString:newText];
   }
}

// ************************************************************
// editingStyleForRowAtIndexPath
// ************************************************************

- (UITableViewCellEditingStyle)tableView:(UITableView *)aTableView editingStyleForRowAtIndexPath:(NSIndexPath *)indexPath 
{
   // Detemine if it's in editing mode
   
   if (indexPath.section == 1)
      return UITableViewCellEditingStyleDelete;
   
   return UITableViewCellEditingStyleNone;
}

// ************************************************************
// commitEditingStyle
// ************************************************************

- (void)tableView:(UITableView *)aTableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath
{
   if (editingStyle == UITableViewCellEditingStyleDelete) 
   {
      noChanges = 0;
      
      // Delete the row from the data source
      
      [self.myYear.pools removeObjectAtIndex:indexPath.row];
      
      [tableView deleteRowsAtIndexPaths:[NSArray arrayWithObject:indexPath] withRowAnimation:UITableViewRowAnimationFade];
      
      double total= [self.myYear.days_per_year doubleValue];
      total += [[self.myYear.pools valueForKeyPath:@"@sum.pool"] doubleValue];
      
      [self.myYear setAmount_with_pools:[NSNumber numberWithDouble:total]];
      [self.tableView reloadData];
   }
   else if (editingStyle == UITableViewCellEditingStyleInsert) 
   {
      // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view
   }   
}

@end
