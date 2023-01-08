//************************************************************
// FreedayEdit.m
// Holiday
//************************************************************
// Created by Patrick Fial on 28.11.202
// Copyright 202-202 Patrick Fial. All rights reserved.
//************************************************************

//************************************************************
// includes
//************************************************************

#import "FreedayEdit.h"
#import "Freeday.h"
#import "TextCell.h"
#import "Storage.h"
#import "ActionDate.h"
#import "DateCell.h"

@implementation FreedayEdit

@synthesize day, editedIndex;

#pragma mark - class FreedayEdit

// ************************************************************
// initWithStyle
// ************************************************************

- (id)initWithStyle:(UITableViewStyle)style
{
   self = [super initWithStyle:UITableViewStyleGrouped];
   
   if (self)
   {
      // Custom initialization
      
      self.day= nil;
      self.editedIndex= nil;
   }
   
   return self;
}

// ************************************************************
// dealloc
// ************************************************************

-(void)dealloc
{
   self.day= nil;
   self.editedIndex= nil;
   
   [super dealloc];
}

#pragma mark - View lifecycle

// ************************************************************
// viewWillDisappear
// ************************************************************

-(void)viewWillDisappear:(BOOL)animated
{
   if (!self.day)
      return;
   
   [Storage saveFreeday:self.day completion:nil];
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
}

#pragma mark - Table view data source

// ************************************************************
// clickedButtonAtIndex
// ************************************************************

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
   return 2;
}

// ************************************************************
// numberOfRowsInSection
// ************************************************************

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
   if (!section)
      return 2;
   
   return 1;
}

// ************************************************************
// cellForRowAtIndexPath
// ************************************************************

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
   if (indexPath.section == 1)
   {
      // section 2, delete button only
      
      UITableViewCell* cell = [tableView dequeueReusableCellWithIdentifier:@"Cell2"];
      
      if (cell == nil)
      {
         cell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"Cell2"] autorelease];
         [Service setRedCell:cell];       // add red backgrounds to cell
         cell.selectionStyle = UITableViewCellSelectionStyleNone;
      }
      
      cell.textLabel.text = NSLocalizedString(@"Delete entry", nil);
      
      return cell;
   }
   
   switch (indexPath.row)
   {
      case 0:
      {
         // title
         
         TextCell* textCell = (TextCell*)[tableView dequeueReusableCellWithIdentifier:@"TextCell"];
         
         if (textCell == nil)
         {
            NSArray* nibContents = [[NSBundle mainBundle] loadNibNamed:@"TextCell_Small" owner:self options:nil];
            textCell = [nibContents lastObject];
            textCell.selectionStyle = UITableViewCellSelectionStyleNone;
            textCell.textField.delegate = self;
            textCell.backgroundColor= DARKTABLEBACKCOLOR;
            textCell.label.textColor= DARKTABLETEXTCOLOR;
            textCell.textField.attributedPlaceholder = [[[NSAttributedString alloc] initWithString:NSLocalizedString(@"Enter name", nil) attributes:@{NSForegroundColorAttributeName:[UIColor darkGrayColor]}] autorelease];
            textCell.selectionStyle = UITableViewCellSelectionStyleNone;
            textCell.textField.textColor= UIColorFromRGB(0x8e8e93);
         }

         textCell.label.text = NSLocalizedString(@"Name", nil);
         textCell.textField.keyboardType= [Service keyboardTypeForType:tpText];
         textCell.textField.text = self.day.title;

         return textCell;
      }
      default:
         break;
   }
   
   // Date cell (2 variants, iOS 14, < iOS 14)

   NSInteger year = [[NSCalendar currentCalendar] component:NSCalendarUnitYear fromDate:[NSDate date]];
   NSDateComponents* comps = [[[NSDateComponents alloc] init] autorelease];
   comps.day = day.day.integerValue;
   comps.month = day.month.integerValue;
   comps.year = year;

   if (SYSTEM_VERSION_GREATER_THAN_OR_EQUAL_TO(@"14.0"))
   {
      DateCell* dateCell = (DateCell*)[tableView dequeueReusableCellWithIdentifier:@"DateCell"];

      if (dateCell == nil)
      {
         NSArray* nibContents= [[NSBundle mainBundle] loadNibNamed:@"DateCell" owner:self options:nil];

         dateCell = [nibContents lastObject];
         dateCell.selectionStyle = UITableViewCellSelectionStyleNone;
         dateCell.button.hidden = TRUE;
         dateCell.backgroundColor= DARKTABLEBACKCOLOR;
         dateCell.label.textColor= DARKTABLETEXTCOLOR;
      }
      
      dateCell.label.text = NSLocalizedString(@"Date", nil);
      dateCell.picker.date = [[NSCalendar currentCalendar] dateFromComponents:comps];
      
      dateCell.valueChanged = ^(NSDate* value)
      {
         NSDateComponents* comps = [[NSCalendar currentCalendar] components:NSCalendarUnitDay|NSCalendarUnitMonth fromDate:value];
         
         self.day.month = [NSNumber numberWithInteger:comps.month];
         self.day.day = [NSNumber numberWithInteger:comps.day];

         [self.tableView reloadData];
      };

      return dateCell;
   }

   // "lame" datepicker with ios < 14

   UITableViewCell* cell= [tableView dequeueReusableCellWithIdentifier:@"Cell2"];

   if (cell == nil)
   {
      cell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleValue1 reuseIdentifier:@"Cell2"] autorelease];
      cell.textLabel.textColor= DARKTABLETEXTCOLOR;
      cell.backgroundColor= DARKTABLEBACKCOLOR;
      cell.selectionStyle = UITableViewCellSelectionStyleNone;
   }

   cell.textLabel.text= NSLocalizedString(@"Date", nil);
   cell.detailTextLabel.text= [[Service dateFormatterFreeday] stringFromDate:[[NSCalendar currentCalendar] dateFromComponents:comps]];

   return cell;
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

#pragma mark - Table view delegate

// ************************************************************
// didSelectRowAtIndexPath
// ************************************************************

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
   if (indexPath.section == 1)
   {
      // delete button

      [Service alertQuestion:NSLocalizedString(@"Delete entry", nil) message:NSLocalizedString(@"Are you sure you want to delete this entry?", nil) cancelButtonTitle:NSLocalizedString(@"Cancel", nil) okButtonTitle:@"OK" action:^(UIAlertAction* action)
       {
          [Storage deleteFreeday:self.day completion:^(BOOL success)
           {
              if (!success)
                 [Service alert:NSLocalizedString(@"Error", nil) withText:NSLocalizedString(@"Failed to save data", nil) andError:nil forController:self completion:nil];
              else
              {
                 self.day= nil;

                 [self.navigationController popViewControllerAnimated:YES];
              }
           }];
       }];
      
      return;
   }
   
   if (indexPath.row == 1)
   {
      if (SYSTEM_VERSION_GREATER_THAN_OR_EQUAL_TO(@"14.0"))
         return;
      
      NSInteger year = [[NSCalendar currentCalendar] component:NSCalendarUnitYear fromDate:[NSDate date]];
      NSDateComponents* comps = [[[NSDateComponents alloc] init] autorelease];
      comps.day = day.day.integerValue;
      comps.month = day.month.integerValue;
      comps.year = year;
      
      ActionDate* picker= [[[ActionDate alloc] initWithDate:[[NSCalendar currentCalendar] dateFromComponents:comps] andHalfDay:-1] autorelease];
      
      picker.valueChanged= ^(NSDate* value, bool isHalfDay)
      {
         NSDateComponents* comps = [[NSCalendar currentCalendar] components:NSCalendarUnitDay|NSCalendarUnitMonth fromDate:value];
         
         self.day.month = [NSNumber numberWithInteger:comps.month];
         self.day.day = [NSNumber numberWithInteger:comps.day];

         [self.tableView reloadData];
      };
      
      [picker show];
   }
}

// *****************************************
// titleForFooterInSection
// *****************************************

- (NSString *)tableView:(UITableView *)tableView titleForFooterInSection:(NSInteger)section
{
   if (section)
      return nil;
   
   return NSLocalizedString(@"Free day will be taken into account every year, at the same day / month", nil);
}

#pragma mark - UITextField delegate

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
   return [Service textField:aTextField shouldChangeCharactersInRange:range replacementString:string andType:tpText andFormatter:[Service numberFormatter] andDelegate:self];
}

// ************************************************************
// textFieldShouldReturn
// ************************************************************

- (BOOL)textFieldShouldReturn:(UITextField *)field
{
   [field resignFirstResponder];
   return YES;
}

#pragma mark - TextInputCell delegate

// ************************************************************
// saveText
// ************************************************************

-(void)saveText:(NSString *)newText fromTextField:(UITextField*)aTextField
{
   self.day.title = newText;
}

@end
