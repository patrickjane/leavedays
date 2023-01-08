//************************************************************
// SettingsController.m
// Holiday
//************************************************************
// Created by Patrick Fial on 06.01.12.
// Copyright 2012-2014 Patrick Fial. All rights reserved.
//************************************************************

//************************************************************
// includes
//************************************************************

#import "SettingsCalculationDialog.h"
#import "Service.h"
#import "Settings.h"
#import "Calculation.h"
#import "EventService.h"
#import "SessionManager.h"
#import "AnnualLeaveListController.h"
#import "ActionTable.h"
#import "ActionDate.h"
#import "ActionPicker.h"
#import "PublicHoliday.h"
#import "DateCell.h"
#import "DarkDisclosureIndicator.h"
#import "FreedaysList.h"

#import "YearSummary.h"
#import "User.h"
#import "Category.h"
#import "Pool.h"

#import <EventKitUI/EventKitUI.h>

//************************************************************
// row & table definitions
//************************************************************

enum RowDefs
{
   rowConfigAnnualLeave,
   rowResidualExpire,
   rowYearBegin,
   rowExpireDate,
   rowWorkweek,
   rowFreeDays,
   rowPublicHoliday,
   rowUnit,
   rowCalcPlanned,

   cntRows
};

enum SectionDefs
{
   sctCalculate,
   
   cntSections
};

static RowInfo** rowInfos= 0;
static SectionInfo** sectionInfos= 0;

//************************************************************
// class SettingsController
//************************************************************

@implementation SettingsCalculationDialog

#pragma mark - Lifecycle

//************************************************************
// initWithStyle
//************************************************************

- (id)initWithStyle:(UITableViewStyle)style
{
   self = [super initWithStyle:UITableViewStyleGrouped];
   
   if (self) 
   {
      // Custom initialization

      tempUnit= 0;

      // row- and sectiondefs

      if (!rowInfos)
      {
         rowInfos= (RowInfo**)calloc(cntRows+1, sizeof(RowInfo*));
         
         rowInfos[rowConfigAnnualLeave]=  rowInit(malloc(sizeof(RowInfo)), rowConfigAnnualLeave,  0, 0, NSLocalizedString(@"Annual leave", nil), nil);
         rowInfos[rowResidualExpire]=     rowInit(malloc(sizeof(RowInfo)), rowResidualExpire,     0, 1, NSLocalizedString(@"Residual leave expires", nil), nil);
         rowInfos[rowExpireDate]=         rowInit(malloc(sizeof(RowInfo)), rowExpireDate,         0, 2, NSLocalizedString(@"Expiration", nil), nil);
         rowInfos[rowWorkweek]=           rowInit(malloc(sizeof(RowInfo)), rowWorkweek,           0, 3, NSLocalizedString(@"Weekend", nil), nil);
         rowInfos[rowFreeDays]=           rowInit(malloc(sizeof(RowInfo)), rowFreeDays,           0, 4, NSLocalizedString(@"Free days", nil), nil);
         rowInfos[rowPublicHoliday]=      rowInit(malloc(sizeof(RowInfo)), rowPublicHoliday,      0, 5, NSLocalizedString(@"Holidays", nil), nil);
         rowInfos[rowYearBegin]=          rowInit(malloc(sizeof(RowInfo)), rowYearBegin,          0, 6, NSLocalizedString(@"Beginning of leave year", nil), nil);
         rowInfos[rowUnit]=               rowInit(malloc(sizeof(RowInfo)), rowUnit,               0, 7, NSLocalizedString(@"Unit", nil), nil);
         rowInfos[rowCalcPlanned]=        rowInit(malloc(sizeof(RowInfo)), rowCalcPlanned,        0, 8, NSLocalizedString(@"Calculate planned leave", nil), nil);
         
         rowInfos[cntRows]= 0;
      }
      
      if (!sectionInfos)
      {
         sectionInfos= (SectionInfo**)calloc(cntSections+1, sizeof(SectionInfo*));
         
         sectionInfos[sctCalculate]=  sectInit(malloc(sizeof(SectionInfo)),  9, NSLocalizedString(@"Calculation", nil), nil);
         
         sectionInfos[cntSections]= 0;
      }
   }
   
   return self;
}

//************************************************************
// dealloc
//************************************************************

-(void)dealloc
{
   [super dealloc];
}

//************************************************************
// viewDidLoad
//************************************************************

- (void)viewDidLoad
{
   [super viewDidLoad];
   
   self.navigationItem.title = NSLocalizedString(@"Settings", nil);
   self.navigationItem.leftBarButtonItem= self.navigationItem.backBarButtonItem;
   self.tableView.backgroundColor= DARKTABLEBACKCOLOR;
   self.tableView.separatorColor= DARKTABLESEPARATORCOLOR;
}

//************************************************************
// viewWillAppear
//************************************************************

-(void)viewWillAppear:(BOOL)animated
{
   if (editPublicHoliday)
   {
      [Settings setUserSetting:skUsePublicHolidayCalendar withBool:NO];
      [Settings setUserSetting:skPublicHolidayCountry withObject:nil];
      [Settings setUserSetting:skPublicHolidayIndentifier withObject:nil];
      
      [EventService setPublicHolidayCalendar:nil];
      editPublicHoliday = NO;
   }
   
   [self.tableView reloadData];
}

#pragma mark - Table view data source

//************************************************************
// numberOfSectionsInTableView
//************************************************************

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
   return cntSections;
}

//************************************************************
// numberOfRowsInSection
//************************************************************

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
   return sectionInfos[section]->rows;
}

//************************************************************
// cellForRowAtIndexPath
//************************************************************

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
   NSArray* nibContents= nil;
   int cellIndex= toCell(indexPath, rowInfos);
   
   switch (cellIndex)
   {
      case rowCalcPlanned:
      case rowResidualExpire:
      {
         SwitchCell* switchCell= (SwitchCell*)[tableView dequeueReusableCellWithIdentifier:@"SwitchCell"];
         
         if (switchCell == nil)
         {
            nibContents= [[NSBundle mainBundle] loadNibNamed:@"SwitchCell_Small" owner:self options:nil];
            switchCell = [nibContents lastObject];
            switchCell.selectionStyle = UITableViewCellSelectionStyleNone;
            switchCell.backgroundColor= DARKTABLEBACKCOLOR;
            switchCell.label.textColor= DARKTABLETEXTCOLOR;
         }
         
         switchCell.label.text= CELLTEXT;
         
         if (cellIndex == rowCalcPlanned)
         {
            switchCell.vSwitch.on = [Settings userSettingBool:skCalculatePlanned];
            switchCell.valueChanged= ^(BOOL value) { [Settings setUserSetting:skCalculatePlanned withBool:value]; [Calculation recalculateAllYears]; };
         }
         else if (cellIndex == rowResidualExpire)
         {
            switchCell.vSwitch.on = [Settings userSettingBool:skLeaveExpires];
            switchCell.valueChanged= ^(BOOL value)
            {
               [Settings setUserSetting:skLeaveExpires withBool:value];
               [Calculation recalculateYear:[SessionManager currentYear].year.intValue withLastYearRemain:0.0 setRemain:false completion:nil];
            };
         }

         return switchCell;
      }
      case rowExpireDate:
      {
         // "cool" datepicker with iOS 14
         
         if (SYSTEM_VERSION_GREATER_THAN_OR_EQUAL_TO(@"14.0"))
         {
            DateCell* dateCell = (DateCell*)[tableView dequeueReusableCellWithIdentifier:@"DateCell"];

            if (dateCell == nil)
            {
               NSArray* nibContents= [[NSBundle mainBundle] loadNibNamed:@"DateCell" owner:self options:nil];

               dateCell = [nibContents lastObject];
               dateCell.selectionStyle = UITableViewCellSelectionStyleNone;
               dateCell.label.textColor= DARKTABLETEXTCOLOR;
               dateCell.backgroundColor= DARKTABLEBACKCOLOR;
            }

            dateCell.label.text = cellTextFromIndex(cellIndex, rowInfos);
            dateCell.picker.date = [Settings userSettingObject:skResidualExpiration];
            dateCell.button.hidden = TRUE;
            dateCell.valueChanged = ^(NSDate* value)
            {
               [Settings setUserSetting:skResidualExpiration withObject:value];
               [Calculation recalculateYear:[SessionManager currentYear].year.intValue withLastYearRemain:0.0 setRemain:false completion:nil];
               [self.tableView reloadRowsAtIndexPaths:[NSArray arrayWithObject:toIndexPath(cellIndex, rowInfos)] withRowAnimation:UITableViewRowAnimationAutomatic];
            };

            return dateCell;
         }
         
         // "lame" datepicker with ios < 14
         
         UITableViewCell* cell= [tableView dequeueReusableCellWithIdentifier:@"Cell"];
         
         if (!cell)
         {
            cell= [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleValue1 reuseIdentifier: @"Cell"] autorelease];
            cell.backgroundColor= DARKTABLEBACKCOLOR;
            cell.textLabel.textColor= DARKTABLETEXTCOLOR;
            cell.detailTextLabel.textColor= UIColorFromRGB(0x8e8e93);
         }
         
         cell.textLabel.text= CELLTEXT;
         cell.detailTextLabel.text= nil;
         cell.selectionStyle= UITableViewCellSelectionStyleBlue;
         cell.detailTextLabel.text = [[Service dateFormatter] stringFromDate:[Settings userSettingObject:skResidualExpiration]];

         return cell;
      }
      default:
      {
         UITableViewCell* cell= [tableView dequeueReusableCellWithIdentifier:@"Cell"];
         
         if (!cell)
         {
            cell= [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleValue1 reuseIdentifier: @"Cell"] autorelease];
            cell.backgroundColor= DARKTABLEBACKCOLOR;
            cell.textLabel.textColor= DARKTABLETEXTCOLOR;
            cell.detailTextLabel.textColor= UIColorFromRGB(0x8e8e93);
         }
         
         cell.textLabel.text= CELLTEXT;
         cell.detailTextLabel.text= nil;
         cell.selectionStyle= UITableViewCellSelectionStyleBlue;
         
         switch (cellIndex)
         {
            case rowFreeDays:
            case rowConfigAnnualLeave:
            {
               [cell setAccessoryView:[DarkDisclosureIndicator indicatorWithColor:[UIColor grayColor] forCell:cell]];
               break;
            }
            default:
            {
               cell.accessoryType= UITableViewCellAccessoryNone;
               break;
            }
         }
         
         switch (cellIndex)
         {
            case rowConfigAnnualLeave:
            {
               if ([SessionManager currentYear])
                  cell.detailTextLabel.text= [Service niceDuration:[SessionManager currentYear].amount_with_pools.doubleValue withCategory:nil];
               else
                  cell.detailTextLabel.text= nil;
               break;
            }
            case rowWorkweek:
            {
               cell.detailTextLabel.text = [Service stringForDays:[Settings userSettingInt:skFreeDays] withFormatter:[Service dateFormatter]];
               break;
            }
            case rowFreeDays:
            {
               cell.detailTextLabel.text= [Service niceDays:[Storage freedaysList].allKeys.count];
               break;
            }
            case rowPublicHoliday:
            {
               if ([Settings userSettingBool:skUsePublicHolidayCalendar])
                  cell.detailTextLabel.text = [[EventService publicHolidayCalendar] title];
               else
                  cell.detailTextLabel.text = NSLocalizedString(@"Disabled", nil);
               
               break;
            }
            case rowYearBegin:
            {
               NSArray* values= [Service dateFormatter].monthSymbols;
               int month = [Settings userSettingInt:skYearBegin]-1;
               
               if (month < 0 || month >= values.count)
                  month = 0;

               cell.detailTextLabel.text = [values objectAtIndex:month];
               break;
            }
            case rowUnit:
            {
               static NSArray* values= nil;
               
               if (!values)
                  values= [[NSArray alloc] initWithObjects:NSLocalizedString(@"Days", nil), NSLocalizedString(@"Hours", nil), nil];
               
               cell.detailTextLabel.text= values[[Settings userSettingInt:skUnit]];
               break;
            }

            default:
               break;
         }

         return cell;
      }
   }
   
   return nil;
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

// ************************************************************
// typeForIndex
// ************************************************************

-(int)typeForIndex:(NSIndexPath*)indexPath
{
   return tpDecimal;
}

#pragma mark - Table view delegate

//************************************************************
// didSelectRowAtIndexPath
//************************************************************

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
   int cellIndex= toCell(indexPath, rowInfos);
   
   // general section
   
   switch (cellIndex)
   {
      case rowConfigAnnualLeave:
      {
         // year info section

         AnnualLeaveListController* dvc= [[[AnnualLeaveListController alloc] initWithStyle:UITableViewStyleGrouped andYears:[SessionManager activeUser].years] autorelease];

         [self.navigationController pushViewController:dvc animated:YES];
         break;
      }
      case rowExpireDate:
      {
         if (SYSTEM_VERSION_GREATER_THAN_OR_EQUAL_TO(@"14.0"))
            return;

         // date picker for the "Expires at" cell
         
         ActionDate* picker= [[[ActionDate alloc] initWithDate:cellIndex == rowExpireDate ? [Settings userSettingObject:skResidualExpiration] : [Settings userSettingObject:skYearBegin]] autorelease];
         
         picker.valueChanged= ^(NSDate* value, bool isHalfDay)
         {
            [Settings setUserSetting:skResidualExpiration withObject:value];
            [Calculation recalculateYear:[SessionManager currentYear].year.intValue withLastYearRemain:0.0 setRemain:false completion:nil];
            [self.tableView reloadRowsAtIndexPaths:[NSArray arrayWithObject:toIndexPath(cellIndex, rowInfos)] withRowAnimation:UITableViewRowAnimationAutomatic];
         };

         [picker show];
         break;
      }
      case rowYearBegin:
      {
         // date picker for the "Expires at" cell
         
         UIAlertController* picker= [UIAlertController alertControllerWithTitle:nil message:nil preferredStyle:UIAlertControllerStyleActionSheet];
         NSArray* values= [Service dateFormatter].monthSymbols;
         
         for (int i = 0; i < values.count; i++)
         {
            [picker addAction:[UIAlertAction actionWithTitle:[values objectAtIndex:i] style:UIAlertActionStyleDefault handler:^(UIAlertAction* action)
                               {
                                  [Settings setUserSetting:skYearBegin withInt:i+1];
                                  [self.tableView reloadRowsAtIndexPaths:[NSArray arrayWithObject:toIndexPath(cellIndex, rowInfos)] withRowAnimation:UITableViewRowAnimationAutomatic];
                                  [[NSNotificationCenter defaultCenter] postNotificationName:kYearChangedNotification object:self userInfo:nil];
                               }]];
         }
         
         [picker addAction:[UIAlertAction actionWithTitle:NSLocalizedString(@"Cancel", nil) style:UIAlertActionStyleCancel handler:nil]];
         [self presentViewController:picker animated:YES completion:nil];
         picker.view.tintColor = MAINCOLORDARK;

         break;
      }
      case rowWorkweek:
      {
         // free days

         int days= [Settings userSettingInt:skFreeDays];
         bitarray selection;
         memset(selection, 0, sizeof(bitarray));
         
         for (int i = 0; i < 7; i++)
            if ((days & (1 << i)))
               BITOP(selection, i, |=);
         
         ActionTable* table= [[ActionTable alloc] initWithValues:[Service dateFormatter].weekdaySymbols andSelection:&selection];
         [table show];
         
         table.selectionChanged= ^(bitarray* newSelection)
         {
            int days= 0;
            
            for (int i = 0; i < 7; i++)
               if (BITOP(*newSelection, i, &))
                  days |= (1 << i);
            
            [Settings setUserSetting:skFreeDays withInt:days];
            [self.tableView reloadRowsAtIndexPaths:[NSArray arrayWithObject:toIndexPath(cellIndex, rowInfos)] withRowAnimation:UITableViewRowAnimationAutomatic];
         };

         break;
      }
      case rowFreeDays:
      {
         FreedaysList* dvc = [[[FreedaysList alloc] initWithStyle:UITableViewStyleGrouped] autorelease];
         
         [self.navigationController pushViewController:dvc animated:YES];
         break;
      }
      case rowPublicHoliday:
      {
         // feiertage
         
         EKCalendarChooser* picker= [[[EKCalendarChooser alloc] initWithSelectionStyle:EKCalendarChooserSelectionStyleSingle displayStyle:EKCalendarChooserDisplayAllCalendars entityType:EKEntityTypeEvent eventStore:[EventService eventStore]] autorelease];

         picker.delegate= self;
         picker.selectedCalendars = [NSSet set];

         [self.navigationController pushViewController:picker animated:YES];
         editPublicHoliday= YES;

         break;
      }
      case rowUnit:
      {
         UIAlertController* actionSheet= [UIAlertController alertControllerWithTitle:nil message:nil preferredStyle:UIAlertControllerStyleActionSheet];
         NSArray* values= nil;

         if (!values)
            values= [NSArray arrayWithObjects:NSLocalizedString(@"Days", nil), NSLocalizedString(@"Hours", nil), nil];

         for (int i= 0; i < 2; i++)
         {
            [actionSheet addAction:[UIAlertAction actionWithTitle:values[i] style:UIAlertActionStyleDefault handler:^(UIAlertAction* action)
                                    {
                                       NSString* message= [NSString stringWithFormat:@"%@\n\n%@\n%@\n\n%@",
                                                           NSLocalizedString(@"Warning: Changing the unit will:", nil),
                                                           NSLocalizedString(@"- Delete all leave pools with different unit added under 'settings/configure annual leave'", nil),
                                                           NSLocalizedString(@"- Possibly change custom categories (disable affects calculation)", nil),
                                                           NSLocalizedString(@"Continue?", nil)];
                                       
                                       [Service alertQuestion:NSLocalizedString(@"Change unit", nil) message:message cancelButtonTitle:NSLocalizedString(@"Cancel", nil) okButtonTitle:@"OK" action:^(UIAlertAction* action)
                                        {
                                           [Settings setUserSetting:skUnit withInt:i];
                                           [self patchCategoriesAndPools];
                                           
                                           [[self tableView] reloadData];
                                        }];
                                    }]];
         }
         
         [actionSheet addAction:[UIAlertAction actionWithTitle:NSLocalizedString(@"Cancel", nil) style:UIAlertActionStyleCancel handler:nil]];
         [self presentViewController:actionSheet animated:YES completion:nil];
         actionSheet.view.tintColor = MAINCOLORDARK;

         break;
         
      }
      default:
         break;
   }
}

#pragma mark -
#pragma mark TableSelectDelegate

// ************************************************************
// setNewString
// ************************************************************

- (void)setNewString:(NSString*)newString 
{
}

// ************************************************************
// setNewInt
// ************************************************************

- (void)setNewInt:(int)newInt 
{
   NSLog(@"Free days before: (%d)", [Settings userSettingInt:skFreeDays]);
   [Settings setUserSetting:skFreeDays withInt:newInt];
   [self.tableView reloadData];
   
   NSLog(@"Free days after: (%d)", [Settings userSettingInt:skFreeDays]);
}

#pragma mark - EKCalendarChooserDelegate

// ************************************************************
// calendarChooserSelectionDidChange
// ************************************************************

-(void)calendarChooserSelectionDidChange:(EKCalendarChooser*)calendarChooser
{
   [self.navigationController popViewControllerAnimated:YES];
   
   EKCalendar* cal= [[calendarChooser.selectedCalendars allObjects] firstObject];
   
   if (!cal)
   {
      [Settings setUserSetting:skUsePublicHolidayCalendar withBool:NO];
      [Settings setUserSetting:skPublicHolidayCountry withObject:nil];
      [Settings setUserSetting:skPublicHolidayIndentifier withObject:nil];
      
      [EventService setPublicHolidayCalendar:nil];
      [[PublicHoliday instance] clearCache];

      return;
   }
   
   [Settings setUserSetting:skUsePublicHolidayCalendar withBool:YES];
   [Settings setUserSetting:skPublicHolidayIndentifier withObject:cal.calendarIdentifier];
   [Settings setUserSetting:skPublicHolidaySource withObject:cal.source.sourceIdentifier];
   
   [EventService setPublicHolidayCalendar:cal];
   [[PublicHoliday instance] reloadEntries];

   editPublicHoliday = NO;
}

#pragma mark - UIDocumentPickerDelegate

#pragma mark - categories

// ************************************************************
// patchCategories
// ************************************************************

- (void)patchCategoriesAndPools
{
   CategoryRef* cat= nil;
   NSPredicate* predicate = [NSPredicate predicateWithFormat:@"(affectCalculation == 1 && savedAsHours == %d) || internalName == %@ || internalName == %@",
                             [Settings userSettingInt:skUnit] ? 0 : 1, @"residualleave", @"specialleave"];
   
   NSArray* filteredCategories= [[SessionManager activeUser].categories filteredArrayUsingPredicate:predicate];
   
   for (int i = 0; i < filteredCategories.count; i++)
   {
      cat= [filteredCategories objectAtIndex:i];
      
      if ([cat.internalName isEqualToString:@"residualleave"] || [cat.internalName isEqualToString:@"specialleave"])
      {
         // switch unit for mandatory categories
         
         cat.savedAsHours = [NSNumber numberWithInt:[Settings userSettingInt:skUnit]];
      }
      else
      {
         // switch affects calculation for all others
         
         cat.affectCalculation= [NSNumber numberWithBool:false];
      }
   }
   
   // now patch pools (delete pools with different unit)
   
   for (YearSummary* sum in [SessionManager activeUser].years)
   {
      for (Pool* pool in sum.pools)
      {
         cat= [Storage categoryForName:pool.category ofUser:[SessionManager activeUser]];
         
         if (cat && [cat.savedAsHours boolValue] != [Settings userSettingInt:skUnit])
            [[Storage currentStorage] deletePool:pool completion:nil];
      }
   }
   
   [[SessionManager activeUser] saveDocument:nil];
}

@end
