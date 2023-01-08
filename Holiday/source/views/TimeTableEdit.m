//************************************************************
// TimeTableEdit.m
// Holiday
//************************************************************
// Created by Patrick Fial on 24.10.2011
// Copyright 2011-2015 Patrick Fial. All rights reserved.
//************************************************************

//************************************************************
// includes
//************************************************************

#import "TimeTableEdit.h"
#import "Timetable.h"
#import "TextCell.h"
#import "Storage.h"

@implementation TimeTableEdit

@synthesize timeTable;
@synthesize days;
@synthesize editedIndex;

#pragma mark - class TimeTableEdit

// ************************************************************
// initWithStyle
// ************************************************************

- (id)initWithStyle:(UITableViewStyle)style
{
   self = [super initWithStyle:UITableViewStyleGrouped];
   
   if (self) 
   {
      // Custom initialization
      
      self.timeTable= nil;
      self.days= nil;
      self.editedIndex= nil;
   }
   
   return self;
}

// ************************************************************
// dealloc
// ************************************************************

-(void)dealloc
{
   self.timeTable= nil;
   self.days= nil;
   self.editedIndex= nil;
   
   [super dealloc];
}

// ************************************************************
// getTotal
// ************************************************************

-(double)getTotal
{
   return [self.timeTable.day_0 doubleValue]
   + [self.timeTable.day_1 doubleValue]
   + [self.timeTable.day_2 doubleValue]
   + [self.timeTable.day_3 doubleValue]
   + [self.timeTable.day_4 doubleValue]
   + [self.timeTable.day_5 doubleValue]
   + [self.timeTable.day_6 doubleValue];
}

#pragma mark - View lifecycle

// ************************************************************
// viewWillDisappear
// ************************************************************

-(void)viewWillDisappear:(BOOL)animated
{
   [Storage saveTimetable:self.timeTable completion:nil];
   
   [super viewWillDisappear:animated];
}

// ************************************************************
// viewDidLoad
// ************************************************************

- (void)viewDidLoad
{
   [super viewDidLoad];
   
   [self.tableView setSeparatorStyle:UITableViewCellSeparatorStyleSingleLine];
   
   self.navigationItem.title = NSLocalizedString(@"Timetable", nil);
   
   self.tableView.backgroundColor= DARKTABLEBACKCOLOR;
   self.tableView.separatorColor= DARKTABLESEPARATORCOLOR;
   
   self.days = [[Service dateFormatter] weekdaySymbols];
}

#pragma mark - Table view data source

// ************************************************************
// clickedButtonAtIndex
// ************************************************************

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
   if (!self.timeTable)
      return 0;
   
   if (self.timeTable.internalname)
      return 3;
   
   return 4;
}

// ************************************************************
// numberOfRowsInSection
// ************************************************************

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
   if (section == 0 || section == 2 || section == 3)
      return 1;
   
   return 7;
}

// ************************************************************
// cellForRowAtIndexPath
// ************************************************************

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
   if (indexPath.section == 2)
   {
      // section 2, delete button only
      
      UITableViewCell* cell = [tableView dequeueReusableCellWithIdentifier:@"Cell"];
      
      if (cell == nil) 
         cell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleValue1 reuseIdentifier:@"Cell"] autorelease];
      
      cell.textLabel.text = NSLocalizedString(@"Hours per week", nil);
      cell.detailTextLabel.text = [[Service numberFormatter] stringFromNumber:[NSNumber numberWithDouble:[self getTotal]]];
      cell.backgroundColor= DARKTABLEBACKCOLOR;
      cell.textLabel.textColor= DARKTABLETEXTCOLOR;
      
      return cell;
   }

   else if (indexPath.section == 3)
   {
      // section 2, delete button only
      
      UITableViewCell* cell = [tableView dequeueReusableCellWithIdentifier:@"Cell2"];
      
      if (cell == nil) 
      {
         cell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"Cell2"] autorelease];
         [Service setRedCell:cell];       // add red backgrounds to cell
      }
      
      cell.textLabel.text = NSLocalizedString(@"Delete entry", nil);
      
      return cell;
   }
   
   TextCell* textCell = (TextCell*)[tableView dequeueReusableCellWithIdentifier:@"TextCell"];
   
   if (textCell == nil)
   {
      NSArray* nibContents = [[NSBundle mainBundle] loadNibNamed:@"TextCell_Small" owner:self options:nil];
      textCell = [nibContents lastObject]; 
      textCell.selectionStyle = UITableViewCellSelectionStyleNone;
      textCell.textField.delegate = self;
      textCell.backgroundColor= DARKTABLEBACKCOLOR;
      textCell.label.textColor= DARKTABLETEXTCOLOR;
   }
   
   textCell.textField.keyboardType= [Service keyboardTypeForType:[self typeForIndex:indexPath]];
   
   if (indexPath.section == 0)
   {
      textCell.label.text = NSLocalizedString(@"Name", nil);
      textCell.textField.text = self.timeTable.name;
      textCell.textField.attributedPlaceholder = [[[NSAttributedString alloc] initWithString:NSLocalizedString(@"Enter name", nil) attributes:@{NSForegroundColorAttributeName:[UIColor darkGrayColor]}] autorelease];
   }
   else
   {
      NSNumberFormatter* numberFormatter= [Service numberFormatter];
      
      textCell.textField.attributedPlaceholder = [[[NSAttributedString alloc] initWithString:NSLocalizedString(@"Enter amount of hours", nil) attributes:@{NSForegroundColorAttributeName:[UIColor darkGrayColor]}] autorelease];

      textCell.label.text = [self.days objectAtIndex:indexPath.row];
      
      switch (indexPath.row)
      {
         case 0: textCell.textField.text = [numberFormatter stringFromNumber:self.timeTable.day_0]; break;
         case 1: textCell.textField.text = [numberFormatter stringFromNumber:self.timeTable.day_1]; break;
         case 2: textCell.textField.text = [numberFormatter stringFromNumber:self.timeTable.day_2]; break;
         case 3: textCell.textField.text = [numberFormatter stringFromNumber:self.timeTable.day_3]; break;
         case 4: textCell.textField.text = [numberFormatter stringFromNumber:self.timeTable.day_4]; break;
         case 5: textCell.textField.text = [numberFormatter stringFromNumber:self.timeTable.day_5]; break;
         case 6: textCell.textField.text = [numberFormatter stringFromNumber:self.timeTable.day_6]; break;
            
         default: break;
      }
   }
   
   return textCell;
}

// ************************************************************
// titleForHeaderInSection
// ************************************************************

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section 
{
   if (section == 1)
      return NSLocalizedString(@"Weekdays", nil);
   
   if (section == 2)
      return NSLocalizedString(@"Total", nil);
   
   return nil;
}

#pragma mark - Table view delegate

// ************************************************************
// didSelectRowAtIndexPath
// ************************************************************

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
   if (indexPath.section == 3)
   {
      // delete button
      
      [Service alertQuestion:NSLocalizedString(@"Delete entry", nil) message:NSLocalizedString(@"Are you sure you want to delete this entry?", nil) cancelButtonTitle:NSLocalizedString(@"Cancel", nil) okButtonTitle:@"OK" action:^(UIAlertAction* action)
       {
          [Storage deleteTimetable:self.timeTable completion:^(BOOL success)
           {
              if (!success)
                 [Service alert:NSLocalizedString(@"Error", nil) withText:NSLocalizedString(@"Failed to save data", nil) andError:nil forController:self completion:nil];
              else
              {
                 self.timeTable= nil;
                 
                 [self.navigationController popViewControllerAnimated:YES];
              }
           }];
       }];
   }
}

// ************************************************************
// typeForIndex
// ************************************************************

-(int)typeForIndex:(NSIndexPath *)idx
{
   if (idx.section == 0)
      return tpText;
   
   // configure different types for text-cells (decimal, text, etc)
   
   return tpNumber;
}


#pragma mark -
#pragma mark UITextField delegate

// ************************************************************
// textFieldShouldBeginEditing
// ************************************************************

-(BOOL)textFieldShouldBeginEditing:(UITextField *)textField
{
   UITableViewCell* v = (UITableViewCell*)[[textField superview] superview];
   
   self.editedIndex = [[self tableView] indexPathForCell:v];
   return YES;
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
   [field resignFirstResponder];
   return YES;
}

#pragma mark -
#pragma mark TextInputCell delegate

// ************************************************************
// saveText
// ************************************************************

-(void)saveText:(NSString *)newText fromTextField:(UITextField*)aTextField
{
   if (self.editedIndex.section == 0)
   {
      self.timeTable.name = newText;
   }
   else
   {
      double oldTotal= [self getTotal];
      NSNumberFormatter* numberFormatter= [Service numberFormatter];

      switch (self.editedIndex.row)
      {
         case 0: self.timeTable.day_0 = [numberFormatter numberFromString:newText]; break;
         case 1: self.timeTable.day_1 = [numberFormatter numberFromString:newText]; break;
         case 2: self.timeTable.day_2 = [numberFormatter numberFromString:newText]; break;
         case 3: self.timeTable.day_3 = [numberFormatter numberFromString:newText]; break;
         case 4: self.timeTable.day_4 = [numberFormatter numberFromString:newText]; break;
         case 5: self.timeTable.day_5 = [numberFormatter numberFromString:newText]; break;
         case 6: self.timeTable.day_6 = [numberFormatter numberFromString:newText]; break;
            
         default: break;
      }

      double total= [self getTotal];
      
      self.timeTable.hours_total= [NSNumber numberWithDouble:total];
      
      if (oldTotal != total)
         [self.tableView reloadRowsAtIndexPaths:[NSArray arrayWithObject:[NSIndexPath indexPathForRow:0 inSection:2]] withRowAnimation:UITableViewRowAnimationAutomatic];
   }
}

@end
