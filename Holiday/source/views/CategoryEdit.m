//************************************************************
// CategoryEdit.m
// Annual Leave iPad
//************************************************************
// Created by Patrick Fial on 29.03.11.
// Copyright 2011-2014 Patrick Fial. All rights reserved.
//************************************************************

//************************************************************
// includes
//************************************************************

#import "CategoryEdit.h"
#import "Category.h"
#import "Service.h"
#import "LeaveInfo.h"
#import "Pool.h"
#import "Settings.h"
#include "Calculation.h"
#import "SessionManager.h"
#import "User.h"

static RowInfo** rowInfos= 0;
static SectionInfo** sectionInfos= 0;

enum RowDefs
{
   rowTitle,
   rowColor,
   rowUnit,
   
   rowAffects,
   rowSummarize,
   rowHonorFreeDays,
   
   rowDelete,
   
   cntRows
};


//************************************************************
// class CategoryEdit
//************************************************************

@implementation CategoryEdit

@synthesize categoryName;
@synthesize info;
@synthesize yearSummary;
@synthesize color;
@synthesize parent;

#pragma mark - Lifecycle

// ************************************************************
// initWithStyle
// ************************************************************

- (id)initWithStyle:(UITableViewStyle)style
{
   self = [super initWithStyle:UITableViewStyleGrouped];
   
   if (self) 
   {
      // Custom initialization
      
      self.categoryName= nil;
      self.yearSummary = nil;
      self.color=nil;
      self.parent= nil;

      savedAsHours= false;
      
      if (!rowInfos)
      {
         rowInfos= (RowInfo**)calloc(cntRows+1, sizeof(RowInfo*));
         rowInfos[rowTitle]=     rowInit(malloc(sizeof(RowInfo)), rowTitle,     0, 0, NSLocalizedString(@"Name", nil), nil);
         rowInfos[rowColor]=     rowInit(malloc(sizeof(RowInfo)), rowColor,     0, 1, NSLocalizedString(@"Color", nil), nil);
         rowInfos[rowUnit]=      rowInit(malloc(sizeof(RowInfo)), rowUnit,      0, 2, NSLocalizedString(@"Unit", nil), nil);
         
         rowInfos[rowAffects]=   rowInit(malloc(sizeof(RowInfo)), rowAffects,   1, 0, NSLocalizedString(@"Affects calculation", nil), nil);
         
         rowInfos[rowSummarize]= rowInit(malloc(sizeof(RowInfo)), rowSummarize, 2, 0, NSLocalizedString(@"Is summarized monthly", nil), nil);
         
         rowInfos[rowHonorFreeDays]= rowInit(malloc(sizeof(RowInfo)), rowHonorFreeDays, 3, 0, NSLocalizedString(@"Honor free days", nil), nil);
         
         rowInfos[rowDelete]=    rowInit(malloc(sizeof(RowInfo)), rowDelete,    4, 0, NSLocalizedString(@"Delete category", nil), nil);

         rowInfos[cntRows]= 0;
      }
      
      if (!sectionInfos)
      {
         sectionInfos= (SectionInfo**)calloc(4+1, sizeof(SectionInfo*));
         sectionInfos[0]= sectInit(malloc(sizeof(SectionInfo)), 3, NSLocalizedString(@"Details", nil), nil);
         sectionInfos[1]= sectInit(malloc(sizeof(SectionInfo)), 1, nil, NSLocalizedString(@"All leave of this category contributes to the leave year's calculation", nil));
         sectionInfos[2]= sectInit(malloc(sizeof(SectionInfo)), 1, nil, NSLocalizedString(@"All leave of this category is seperately summarized month by month", nil));
         sectionInfos[3]= sectInit(malloc(sizeof(SectionInfo)), 1, nil, NSLocalizedString(@"If enabled, calculation of leave duration honors the free days of the week and public holidays configured in calculation settings", nil));
         sectionInfos[4]= sectInit(malloc(sizeof(SectionInfo)), 1, NSLocalizedString(@"Delete", nil), nil);
         sectionInfos[5]= 0;
         
      }
   }
   
   return self;
}

// ************************************************************
// dealloc
// ************************************************************

- (void)dealloc
{
   self.info = nil;
   
   self.categoryName= nil;
   self.parent= nil;

   [super dealloc];
}

// ************************************************************
// viewDidLoad
// ************************************************************

- (void)viewDidLoad
{
   [super viewDidLoad];
   
   self.navigationItem.title = NSLocalizedString(@"Category", nil);
   self.tableView.backgroundColor= DARKTABLEBACKCOLOR;
   self.tableView.separatorColor= DARKTABLESEPARATORCOLOR;
   
   UIBarButtonItem* saveButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemSave target:self action:@selector(save)];
   self.navigationItem.rightBarButtonItem = saveButton;
   [saveButton release];
}

#pragma mark - fill, save, update, insert, delete

// ************************************************************
// fill
// ************************************************************

-(void) fill:(CategoryRef *)category
{
   if (!category)
   {
      // clear
      
      self.info = nil;
      deletable= YES;
      affectCalculation = NO;
      sumMonthly = NO;
      honorFreeDays= NO;
      savedAsHours = NO;
      self.categoryName = nil;
      self.color = [Service uiColor];
   }
   else
   {
      // copy values
   
      self.info = category;
      self.categoryName = category.name;
      self.color = [Service colorString:category.color];
      affectCalculation= [category.affectCalculation boolValue];
      sumMonthly = [category.sumMonthly boolValue];
      deletable= [category.deletable boolValue];
      savedAsHours = [category.savedAsHours boolValue];
      honorFreeDays= [category.honorFreeDays boolValue];
   }
   
   self.navigationItem.rightBarButtonItem.enabled = (self.categoryName != nil && [self.categoryName length]);
   
   [[self tableView] reloadData];
}

// ************************************************************
// setValues
// ************************************************************

-(void) setValues 
{
   if (!self.info)
      return;
   
   self.info.name = self.categoryName;
   
   self.info.affectCalculation = [NSNumber numberWithBool:affectCalculation];
   self.info.sumMonthly = [NSNumber numberWithBool:sumMonthly];
   self.info.deletable = [NSNumber numberWithBool:deletable];
   self.info.savedAsHours = [NSNumber numberWithBool:savedAsHours];
   self.info.color = [Service stringColor:self.color];
   self.info.honorFreeDays = [NSNumber numberWithBool:honorFreeDays];
}


// ************************************************************
// save (wrapper)
// ************************************************************

-(void)save
{
   [self save:NO];
}

// ************************************************************
// save
// ************************************************************

-(void)save:(bool)delete
{
   NSString* oldName= [NSString stringWithFormat:@"%@", self.info.name];
   
   // only allow unique names
   
   CategoryRef* cat= nil;
   
   if (oldName && ![oldName isEqualToString:self.categoryName])
      cat= [Storage categoryForName:self.categoryName ofUser:[SessionManager activeUser]];
   
   if (cat)
   {
      [Service message:NSLocalizedString(@"Error", nil) withText:NSLocalizedString(@"Category with the same name already exists. Choose different name.", nil) forController:nil completion:nil];
      return;
   }
   
   // copy values from member values to CategoryRef* object

   if (!delete)
   {
      if (!self.info)
         self.info= [Storage createCategory:[SessionManager activeUser]];
      
      [self setValues];
   }
   else
   {
      // remove from cache. will be auto-released
      
      User* owner= [[Storage currentStorage] userWithUUid:self.info.userid];
      
      for (LeaveInfo* leave in owner.leave)
      {
         if ([leave.category isEqualToString:self.info.name])
            leave.category= nil;
      }
      
      [Storage deleteCategory:self.info completion:nil];
   }
   
   [[SessionManager activeUser] saveDocument:^(BOOL success)
    {
       if (success)
       {
          [Calculation recalculateAllYears];
          [[self navigationController] popViewControllerAnimated:YES];
       }
       else
          [Service alert:NSLocalizedString(@"Error", nil) withText:NSLocalizedString(@"Failed to save data", nil) andError:nil forController:self completion:nil];
    }];
}

#pragma mark - Table view data source

// ************************************************************
// numberOfSectionsInTableView
// ************************************************************

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
   // no delete button when adding a category
   
   if (!self.info || ![self.info.deletable boolValue])
      return 4;
   
   return 5;
}

// ************************************************************
// numberOfRowsInSection
// ************************************************************

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
   return sectionInfos[section]->rows;
}

// ************************************************************
// cellForRowAtIndexPath
// ************************************************************

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
   int cellIndex= toCell(indexPath, rowInfos);

   switch (cellIndex)
   {
      case rowTitle:
      {
         TextCell* textCell= (TextCell*)[tableView dequeueReusableCellWithIdentifier:@"TextCell"];
         
         if (textCell == nil)
         {
            NSArray* nibContents = [[NSBundle mainBundle] loadNibNamed:@"TextCell_Small" owner:self options:nil];
            textCell = [nibContents lastObject];
            textCell.selectionStyle = UITableViewCellSelectionStyleNone;
            textCell.textField.delegate = self;
            textCell.textField.attributedPlaceholder = [[[NSAttributedString alloc] initWithString:NSLocalizedString(@"Enter name", nil) attributes:@{NSForegroundColorAttributeName:[UIColor darkGrayColor]}] autorelease];
            textCell.textField.keyboardType= [Service keyboardTypeForType:tpText];
            textCell.textField.textColor= [UIColor colorWithRed:0.556863 green:0.556863 blue:0.576471 alpha:1.0];
            textCell.backgroundColor= DARKTABLEBACKCOLOR;
            textCell.label.textColor= DARKTABLETEXTCOLOR;
            textCell.textField.textColor= DARKTABLETEXTCOLOR;
         }

         textCell.label.text = CELLTEXT;
         textCell.textField.text = self.categoryName;
         
         return textCell;
      }
      case rowColor:
      case rowUnit:
      {
         // color cell
         
         UITableViewCell *cell= [tableView dequeueReusableCellWithIdentifier:@"Cell2"];
         
         if (cell == nil)
         {
            cell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleValue1 reuseIdentifier:@"Cell2"] autorelease];
            cell.backgroundColor= DARKTABLEBACKCOLOR;
            cell.textLabel.textColor= DARKTABLETEXTCOLOR;
         }
         
         if (cellIndex == rowColor)
         {
            cell.detailTextLabel.textColor = self.color;
            cell.detailTextLabel.text = NSLocalizedString(@"Selected color", nil);
            
            if ([Service isColor:self.color of:0.0 and:0.0 and:0.0])
               cell.detailTextLabel.textColor= DARKTABLETEXTCOLOR;
         }
         else
         {
            cell.detailTextLabel.textColor= [UIColor colorWithRed:0.556863 green:0.556863 blue:0.576471 alpha:1.0];
            cell.detailTextLabel.text= !savedAsHours ? NSLocalizedString(@"Days", nil) : NSLocalizedString(@"Hours", nil);
         }

         cell.textLabel.text= CELLTEXT;
         
         return cell;
      }
      case rowAffects:
      case rowSummarize:
      case rowHonorFreeDays:
      {
         // affectCalculation, summarizeMonthly
         
         SwitchCell* switchCell= (SwitchCell*)[tableView dequeueReusableCellWithIdentifier:@"SwitchCell"];
         
         if (switchCell == nil)
         {
            NSArray* nibContents = [[NSBundle mainBundle] loadNibNamed:@"SwitchCell_Small" owner:self options:nil];
            switchCell= [nibContents lastObject];
            switchCell.backgroundColor= DARKTABLEBACKCOLOR;
            switchCell.label.textColor= DARKTABLETEXTCOLOR;
         }
         
         switchCell.label.text = CELLTEXT;
         switchCell.vSwitch.on = cellIndex == rowAffects ? affectCalculation : (cellIndex == rowSummarize ? sumMonthly : honorFreeDays);
         
         if (cellIndex == rowAffects)
         {
            switchCell.valueChanged= ^(BOOL value)
            {
               affectCalculation = value;
               
               if (affectCalculation && [Settings userSettingInt:skUnit] == uDays)
                  savedAsHours = NO;
               else if (affectCalculation && [Settings userSettingInt:skUnit] == uHours)
                  savedAsHours= YES;
               
               [self.tableView reloadData];
            };
         }
         else if (cellIndex == rowSummarize)
         {
            switchCell.valueChanged= ^(BOOL value) { sumMonthly = value; [self.tableView reloadData]; };
         }
         else
         {
            switchCell.valueChanged= ^(BOOL value) { honorFreeDays = value; [self.tableView reloadData]; };
         }

         return switchCell;
      }
      default:
         break;
   }

   // delete button

   UITableViewCell* cell= [tableView dequeueReusableCellWithIdentifier:@"Cell"];
   
   if (cell == nil)
   {
      cell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"Cell"] autorelease];
      cell.textLabel.textColor = [UIColor whiteColor];
      cell.textLabel.text= CELLTEXT;
      [Service setRedCell:cell];
   }
   
   return cell;
}

// ************************************************************
// titleForHeaderInSection
// ************************************************************

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section 
{
   return sectionInfos[section]->header;
}

// ************************************************************
// titleForFooterInSection
// ************************************************************

- (NSString *)tableView:(UITableView *)tableView titleForFooterInSection:(NSInteger)section 
{
   return sectionInfos[section]->footer;
}

#pragma mark - delegates

// ************************************************************
// saveText
// ************************************************************

-(void)saveText:(NSString *)newText fromTextField:(UITextField*)aTextField
{
   self.categoryName = newText;
   
   self.navigationItem.rightBarButtonItem.enabled = (newText != nil && [newText length]);
}

#pragma mark -
#pragma mark UITextField delegate

// ************************************************************
// shouldChangeCharactersInRange
// ************************************************************

- (BOOL)textField:(UITextField *)aTextField shouldChangeCharactersInRange:(NSRange)range replacementString:(NSString *)string 
{
   return [Service textField:aTextField shouldChangeCharactersInRange:range replacementString:string andType:tpText andFormatter:nil andDelegate:self];
}

// ************************************************************
// textFieldShouldReturn
// ************************************************************

- (BOOL)textFieldShouldReturn:(UITextField *)field 
{
   [field resignFirstResponder];
   return YES;
}

#pragma mark - Table view delegate

// ************************************************************
// didSelectRowAtIndexPath
// ************************************************************

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
   int cellIndex= toCell(indexPath, rowInfos);
   
   switch (cellIndex)
   {
      case rowColor:
      {
         // color
         
         ColorPickerController* dvc= [[ColorPickerController alloc] initWithColor:self.color fullColor:YES];
         dvc.delegate= self;
         
         [self.navigationController pushViewController:dvc animated:YES];
         [dvc release];
         
         break;
      }
      case rowUnit:
      {
         UIAlertController* actionSheet= [UIAlertController alertControllerWithTitle:NSLocalizedString(@"Select unit", nil) message:nil preferredStyle:UIAlertControllerStyleActionSheet];
         
         [actionSheet addAction:[UIAlertAction actionWithTitle:NSLocalizedString(@"Days", nil) style:UIAlertActionStyleDefault handler:^(UIAlertAction* action)
                                 {
                                    savedAsHours= NO;

                                    if (savedAsHours == ![Settings userSettingInt:skUnit])
                                    {
                                       SwitchCell* cell= (SwitchCell*)[[self tableView] cellForRowAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:1]];
                                       cell.vSwitch.on = NO;
                                       affectCalculation = NO;
                                    }

                                    [self.tableView reloadData];
                                 }]];

         [actionSheet addAction:[UIAlertAction actionWithTitle:NSLocalizedString(@"Hours", nil) style:UIAlertActionStyleDefault handler:^(UIAlertAction* action)
                                 {
                                    savedAsHours= YES;
                                    
                                    if (savedAsHours == ![Settings userSettingInt:skUnit])
                                    {
                                       SwitchCell* cell= (SwitchCell*)[[self tableView] cellForRowAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:1]];
                                       cell.vSwitch.on = NO;
                                       affectCalculation = NO;
                                    }

                                    [self.tableView reloadData];
                                 }]];
         
         [actionSheet addAction:[UIAlertAction actionWithTitle:NSLocalizedString(@"Cancel", nil) style:UIAlertActionStyleCancel handler:nil]];
         [self presentViewController:actionSheet animated:YES completion:nil];
         actionSheet.view.tintColor = MAINCOLORDARK;

         break;
      }
      case rowDelete:
      {
         // delete button
         
         [Service alertQuestion:NSLocalizedString(@"Delete category", nil) message:NSLocalizedString(@"Are you sure you want to delete this category? Note: All leave with this category will be reset to no category.", nil) cancelButtonTitle:NSLocalizedString(@"Cancel", nil)  okButtonTitle:@"OK" action:^(UIAlertAction* action)
          {
             [self save:YES];
             
             [[self navigationController] popViewControllerAnimated:YES];
             
          }];
         
         break;
      }

      default:
         break;
   }
}

#pragma mark - HRColorPickerViewControllerDelegate

// ************************************************************
// colorPickerViewController
// ************************************************************

-(void)setSelectedColor:(UIColor *)aColor
{
   self.color= aColor;
   
   [self.tableView reloadData];
}

@end
