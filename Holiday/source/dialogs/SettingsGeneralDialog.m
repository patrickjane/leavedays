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

#import "SettingsGeneralDialog.h"
#import "SessionManager.h"
#import "AppDelegate.h"
#import "Service.h"
#import "Settings.h"
#import "Calculation.h"
#import "EventService.h"
#import "BackupImporter.h"
#import "BackupExporter.h"
#import "User.h"
#import "Storage.h"
#import "YearSummary.h"
#import "CsvCreator.h"

#import <EventKitUI/EventKitUI.h>
#import <UserNotifications/UserNotifications.h>

//************************************************************
// row & table definitions
//************************************************************

enum RowDefs2
{
   rowStoreCalendar,
   rowSingleUser,
   rowBadgeCount,
   rowCalendarColor,
   rowImport,
   rowExport,
   
   cntRows2
};

enum SectionDefs
{
   sctGeneral,
   sctStorage,
   
   cntSections
};

static RowInfo** rowInfos= 0;
static SectionInfo** sectionInfos= 0;

//************************************************************
// class SettingsController
//************************************************************

@implementation SettingsGeneralDialog

#pragma mark - Lifecycle

//************************************************************
// initWithStyle
//************************************************************

- (id)initWithStyle:(UITableViewStyle)style
{
   self = [super initWithStyle:UITableViewStyleGrouped];
   
   if (self) 
   {
      self.importer= [[[BackupImporter alloc] init] autorelease];
      self.exporter= [[[BackupExporter alloc] init] autorelease];
      
      // row- and sectiondefs
      
      if (!rowInfos)
      {
         rowInfos= (RowInfo**)calloc(cntRows2+1, sizeof(RowInfo*));
         rowInfos[rowStoreCalendar]=      rowInit(malloc(sizeof(RowInfo)), rowStoreCalendar,      0, 0, NSLocalizedString(@"Save in calendar",   nil), nil);
         rowInfos[rowSingleUser]=         rowInit(malloc(sizeof(RowInfo)), rowSingleUser,         0, 1, NSLocalizedString(@"Single user mode",   nil), nil);
         rowInfos[rowBadgeCount]=         rowInit(malloc(sizeof(RowInfo)), rowBadgeCount,         0, 2, NSLocalizedString(@"Badge-Count",   nil), nil);
         rowInfos[rowCalendarColor]=      rowInit(malloc(sizeof(RowInfo)), rowCalendarColor,      0, 3, NSLocalizedString(@"Calendar color by category",   nil), nil);

         rowInfos[rowImport]=             rowInit(malloc(sizeof(RowInfo)), rowImport,             1, 0, NSLocalizedString(@"Import backup",   nil), nil);
         rowInfos[rowExport]=             rowInit(malloc(sizeof(RowInfo)), rowExport,             1, 1, NSLocalizedString(@"Create backup",   nil), nil);
         
         rowInfos[cntRows2]= 0;
      }
      
      if (!sectionInfos)
      {
         sectionInfos= (SectionInfo**)calloc(cntSections+1, sizeof(SectionInfo*));
         sectionInfos[sctGeneral]=    sectInit(malloc(sizeof(SectionInfo)),  4, NSLocalizedString(@"General", nil), nil);
         sectionInfos[sctStorage]=    sectInit(malloc(sizeof(SectionInfo)),  2, NSLocalizedString(@"Storage", nil), nil);
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
   self.importer= nil;
   self.exporter= nil;
   
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
   [[UIButton appearanceWhenContainedInInstancesOfClasses:[NSArray arrayWithObject:[UINavigationBar class]]] setTintColor:LIGHTTEXTCOLOR];

   if (needReset)
   {
      [Settings setUserSetting:skStoreInCalendar withBool:NO];
      [Settings setUserSetting:skStorageSource withObject:nil];
      [Settings setUserSetting:skStorageIdentifier withObject:nil];
      
      [EventService setStorageCalendar:nil];
   }
   
   [self.tableView reloadData];
   [super viewWillAppear:animated];
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
   int cellIndex= toCell(indexPath, rowInfos);
   
   switch (cellIndex)
   {
      case rowSingleUser:
      case rowBadgeCount:
      case rowCalendarColor:
      {
         SwitchCell* switchCell= (SwitchCell*)[tableView dequeueReusableCellWithIdentifier:@"SwitchCell"];
         
         if (switchCell == nil)
         {
            NSArray* nibContents= [[NSBundle mainBundle] loadNibNamed:@"SwitchCell_Small" owner:self options:nil];
            switchCell = [nibContents lastObject];
            switchCell.selectionStyle = UITableViewCellSelectionStyleNone;
         }
         
         switchCell.label.text= CELLTEXT;

         if (cellIndex == rowBadgeCount)
         {
            switchCell.vSwitch.on = [Settings globalSettingBool:skShowBadge];
            switchCell.valueChanged= ^(BOOL value)
            {
               [Settings setGlobalSetting:skShowBadge withBool:value];
               
               if (value)
               {
                  UNUserNotificationCenter* center = [UNUserNotificationCenter currentNotificationCenter];

                  [center requestAuthorizationWithOptions:UNAuthorizationOptionBadge completionHandler:^(BOOL granted, NSError* err)
                  {
                     if (granted)
                     {
                        NSLog(@"Access to badges WAS granted");
                        [UIApplication sharedApplication].applicationIconBadgeNumber = [SessionManager currentYear].amount_remain_with_pools.integerValue;
                     }
                     else
                        NSLog(@"Access to badges was NOT granted");
                  }];
               }
               else
                  [UIApplication sharedApplication].applicationIconBadgeNumber = 0;
            };
         }
         else if (cellIndex == rowCalendarColor)
         {
            switchCell.vSwitch.on = [Settings globalSettingBool:skCalendarColorByCategory];
            switchCell.valueChanged= ^(BOOL value)
            {
               [Settings setGlobalSetting:skCalendarColorByCategory withBool:value];
               [[NSNotificationCenter defaultCenter] postNotificationName:kLeaveChanged object:self];
            };
         }
         else
         {
            switchCell.vSwitch.on = [Settings globalSettingBool:skSingleUser];
            switchCell.valueChanged= ^(BOOL value)
            {
               [Settings setGlobalSetting:skSingleUser withBool:value];
            };
         }
         
         switchCell.backgroundColor= DARKTABLEBACKCOLOR;
         switchCell.label.textColor= DARKTABLETEXTCOLOR;
         
         return switchCell;
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

         switch (cellIndex)
         {
            case rowStoreCalendar:
            {
               if ([Settings userSettingBool:skStoreInCalendar])
                  cell.detailTextLabel.text = [[EventService storageCalendar] title];
               else
                  cell.detailTextLabel.text = NSLocalizedString(@"Disabled", nil);
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
      case rowStoreCalendar:
      {
         // store calendar name

         EKCalendarChooser* picker= [[[EKCalendarChooser alloc] initWithSelectionStyle:EKCalendarChooserSelectionStyleSingle displayStyle:EKCalendarChooserDisplayWritableCalendarsOnly eventStore:[EventService eventStore]] autorelease];
                
         picker.delegate= self;
         picker.selectedCalendars = [NSSet set];
         
         needReset= YES;
         
         [self.navigationController pushViewController:picker animated:YES];
         
         break;
      }
      case rowImport:
      {
         UIDocumentPickerViewController* dvc= [[[UIDocumentPickerViewController alloc] initWithDocumentTypes:[NSArray arrayWithObjects:@"de.s710.holiday.alb", @"de.s710.holiday.alb2", nil] inMode:UIDocumentPickerModeImport] autorelease];
         dvc.delegate= self;
         
         [[UINavigationBar appearance] setTintColor:nil];

         [self.navigationController presentViewController:dvc animated:YES completion:^()
          {
            [[UINavigationBar appearance] setTintColor:LIGHTTEXTCOLOR];
         }];

         break;
      }
      case rowExport:
      {
         UIAlertController* actionSheet= [UIAlertController alertControllerWithTitle:NSLocalizedString(@"Select user", nil) message:nil preferredStyle:UIAlertControllerStyleActionSheet];

         for (User* user in [Storage userlist])
         {
            [actionSheet addAction:[UIAlertAction actionWithTitle:user.name style:UIAlertActionStyleDefault handler:^(UIAlertAction* action)
                                    {
                                       [self.exporter exportUser:user];
                                    }]];
         }

         [actionSheet addAction:[UIAlertAction actionWithTitle:NSLocalizedString(@"Cancel", nil) style:UIAlertActionStyleCancel handler:nil]];
         [self presentViewController:actionSheet animated:YES completion:nil];
         actionSheet.view.tintColor = MAINCOLORDARK;
      }

      default:
         break;
   }
}

// ************************************************************
// calendarChooserSelectionDidChange
// ************************************************************

-(void)calendarChooserSelectionDidChange:(EKCalendarChooser*)calendarChooser
{
   needReset= NO;

   [self.navigationController popViewControllerAnimated:YES];

   EKCalendar* cal= [[calendarChooser.selectedCalendars allObjects] firstObject];
   
   if (!cal)
   {
      [Settings setUserSetting:skStoreInCalendar withBool:NO];
      [Settings setUserSetting:skStorageSource withObject:nil];
      [Settings setUserSetting:skStorageIdentifier withObject:nil];
      
      [EventService setStorageCalendar:nil];
      
      return;
   }
   
   [Settings setUserSetting:skStoreInCalendar withBool:YES];
   [Settings setUserSetting:skStorageIdentifier withObject:cal.calendarIdentifier];
   [Settings setUserSetting:skStorageSource withObject:cal.source.sourceIdentifier];
   
   [EventService setStorageCalendar:cal];
}

#pragma mark - UIDocumentPickerDelegate

// ************************************************************
// didPickDocumentAtURL
// ************************************************************
-(void)documentPicker:(UIDocumentPickerViewController *)controller didPickDocumentsAtURLs:(NSArray<NSURL *> *)urls
{
   if (!urls.count)
      return;
   
   NSURL* url = urls.firstObject;

   [[UIButton appearanceWhenContainedInInstancesOfClasses:[NSArray arrayWithObject:[UINavigationBar class]]] setTintColor:LIGHTTEXTCOLOR];
   
   [self.importer importFile:url completion:^(BOOL success)
    {
       [self.navigationController popToRootViewControllerAnimated:YES];
       AppDelegate* del= (AppDelegate*)[UIApplication sharedApplication].delegate;
       [del hideMenu];
    }];
}

// ************************************************************
// documentPickerWasCancelled
// ************************************************************

-(void)documentPickerWasCancelled:(UIDocumentPickerViewController *)controller
{
   [[UIButton appearanceWhenContainedInInstancesOfClasses:[NSArray arrayWithObject:[UINavigationBar class]]] setTintColor:LIGHTTEXTCOLOR];
}

@end
