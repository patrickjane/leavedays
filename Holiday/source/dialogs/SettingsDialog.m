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

#import "SettingsDialog.h"
#import "SettingsCalculationDialog.h"
#import "SettingsGeneralDialog.h"
#import "MailPrefController.h"
#import "CategoryOverviewController.h"
#import "TimeTableList.h"
#import "MessageUI/MessageUI.h"
#import "EventService.h"
#import "AppDelegate.h"
#import "Service.h"
#import "Settings.h"
#include "SessionManager.h"
#include "Storage.h"
#import "JASidePanelController.h"
#import "User.h"
#import "UserEdit.h"
#import "UserList.h"
#import "DarkDisclosureIndicator.h"

//************************************************************
// row & table definitions
//************************************************************

enum RowDefs
{
   rowGeneral,
   rowCalculation,
   rowMailSettings,
   rowCategories,
   rowUsers,
   rowTimeTables,
   rowFeedback,

   rowLogout,
   
   rowWipe,
   
   cntRows
};

enum SectionDefs
{
   sctOptions,
   sctSession,
   sctWipe,
   
   cntSections
};

static RowInfo** rowInfos= 0;
static SectionInfo** sectionInfos= 0;

//************************************************************
// class SettingsController
//************************************************************

@implementation SettingsDialog

#pragma mark - Lifecycle

//************************************************************
// initWithStyle
//************************************************************

- (id)initWithStyle:(UITableViewStyle)style
{
   self = [super initWithStyle:UITableViewStyleGrouped];
   
   if (self) 
   {
      // row- and sectiondefs
      
      if (!rowInfos)
      {
         rowInfos= (RowInfo**)calloc(cntRows+1, sizeof(RowInfo*));
         
         rowInfos[rowGeneral]=            rowInit(malloc(sizeof(RowInfo)), rowGeneral,            0, 0, NSLocalizedString(@"General", nil), nil);
         rowInfos[rowCalculation]=        rowInit(malloc(sizeof(RowInfo)), rowCalculation,        0, 1, NSLocalizedString(@"Calculation", nil), nil);
         rowInfos[rowMailSettings]=       rowInit(malloc(sizeof(RowInfo)), rowMailSettings,       0, 2, NSLocalizedString(@"E-Mail template", nil), nil);
         rowInfos[rowCategories]=         rowInit(malloc(sizeof(RowInfo)), rowCategories,         0, 3, NSLocalizedString(@"Categories", nil), nil);
         rowInfos[rowTimeTables]=         rowInit(malloc(sizeof(RowInfo)), rowTimeTables,         0, 4, NSLocalizedString(@"Timetables", nil), nil);
         rowInfos[rowFeedback]=           rowInit(malloc(sizeof(RowInfo)), rowFeedback,           0, 5, NSLocalizedString(@"Feedback", nil), nil);
         rowInfos[rowUsers]=              rowInit(malloc(sizeof(RowInfo)), rowUsers,              0, 6, NSLocalizedString(@"User management", nil), nil);

         rowInfos[rowLogout]=             rowInit(malloc(sizeof(RowInfo)), rowLogout,             1, 0, NSLocalizedString(@"Logout", nil), nil);
         
         rowInfos[rowWipe]=               rowInit(malloc(sizeof(RowInfo)), rowWipe,               2, 0, NSLocalizedString(@"Wipe data", nil), nil);
         
         rowInfos[cntRows]= 0;
      }
      
      if (!sectionInfos)
      {
         NSString* appName= [[[NSBundle mainBundle] localizedInfoDictionary] objectForKey:@"CFBundleDisplayName"];

         sectionInfos= (SectionInfo**)calloc(cntSections+1, sizeof(SectionInfo*));
         
         sectionInfos[sctOptions]=    sectInit(malloc(sizeof(SectionInfo)),  7, NSLocalizedString(@"Options", nil), nil);
         sectionInfos[sctSession]=    sectInit(malloc(sizeof(SectionInfo)),  1, NSLocalizedString(@"Session", nil), nil);
         sectionInfos[sctWipe]=       sectInit(malloc(sizeof(SectionInfo)),  1, NSLocalizedString(@"Storage", nil), [NSString stringWithFormat:@"%@ v%@ (%@)",
                                                                                                                     appName,
                                                                                                                     [[[NSBundle mainBundle] infoDictionary] objectForKey:@"CFBundleShortVersionString"],
                                                                                                                     [[[NSBundle mainBundle] infoDictionary] objectForKey:@"CFBundleVersion"]]);
         
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
   
   UISwipeGestureRecognizer* rec= [[UISwipeGestureRecognizer alloc] initWithTarget:self action:@selector(didSwipe:)];
   [rec setDirection:UISwipeGestureRecognizerDirectionLeft];
   
   [self.tableView addGestureRecognizer:rec];
   
   self.navigationItem.title = NSLocalizedString(@"Settings", nil);
   self.navigationItem.leftBarButtonItem = [[[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"Menu.png"] style:UIBarButtonItemStylePlain target:self action:@selector(dismiss)] autorelease];

   self.tableView.backgroundColor= DARKTABLEBACKCOLOR;
   self.tableView.separatorColor= DARKTABLESEPARATORCOLOR;
}

//************************************************************
// viewWillAppear
//************************************************************

-(void)viewWillAppear:(BOOL)animated
{
   [self.tableView reloadData];
}

//************************************************************
// didSwipe
//************************************************************

-(void)didSwipe:(UISwipeGestureRecognizer *)recognizer
{
   CGPoint point= [recognizer locationInView:self.view];
   
   if (point.x < 300)
      return;

   [self dismiss];
}

//************************************************************
// viewDidUnload
//************************************************************

-(void)dismiss
{
   JASidePanelController* side= (JASidePanelController*)[UIApplication sharedApplication].delegate.window.rootViewController;
   [side showCenterPanelAnimated:YES];
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
   if (section == sctOptions && [Settings globalSettingBool:skSingleUser])
      return sectionInfos[section]->rows-1;
      
   if (section == sctSession && [Settings globalSettingBool:skSingleUser])
      return sectionInfos[section]->rows-1;
   
   return sectionInfos[section]->rows;
}

//************************************************************
// cellForRowAtIndexPath
//************************************************************

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
   int cellIndex= toCell(indexPath, rowInfos);

   if (cellIndex == rowWipe)
   {
      UITableViewCell* cell= [tableView dequeueReusableCellWithIdentifier:@"CellWipe"];
      
      if (!cell)
         cell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier: @"CellWipe"] autorelease];
      
      cell.textLabel.textColor= [UIColor whiteColor];
      cell.textLabel.text= CELLTEXT;
      cell.textLabel.textAlignment= NSTextAlignmentCenter;
      
      [Service setRedCell:cell];
      
      return cell;
   }
   
   UITableViewCell* cell= [tableView dequeueReusableCellWithIdentifier:@"Cell"];
   
   if (!cell)
   {
      cell= [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleValue1 reuseIdentifier: @"Cell"] autorelease];
      cell.backgroundColor= DARKTABLEBACKCOLOR;
      cell.textLabel.textColor= DARKTABLETEXTCOLOR;
   }
   
   cell.textLabel.text= CELLTEXT;
   
   if (cellIndex == rowLogout || cellIndex == rowFeedback)
      cell.accessoryType= UITableViewCellAccessoryNone;
   else
      [cell setAccessoryView:[DarkDisclosureIndicator indicatorWithColor:[UIColor grayColor] forCell:cell]];
//      [cell setAccessoryType:UITableViewCellAccessoryDisclosureIndicator];
   
   return cell;
}

// ************************************************************
// titleForHeaderInSection
// ************************************************************

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
   if (section == sctSession && [Settings globalSettingBool:skSingleUser])
      return nil;

   return sectionInfos[section]->header;
}

// ************************************************************
// titleForFooterInSection
// ************************************************************

- (NSString *)tableView:(UITableView *)tableView titleForFooterInSection:(NSInteger)section 
{
   return sectionInfos[section]->footer;
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
      case rowGeneral:
      {
         SettingsGeneralDialog* dvc= [[[SettingsGeneralDialog alloc] initWithStyle:UITableViewStyleGrouped] autorelease];
         [self.navigationController pushViewController:dvc animated:YES];
         break;
      }
      case rowCalculation:
      {
         SettingsCalculationDialog* dvc= [[[SettingsCalculationDialog alloc] initWithStyle:UITableViewStyleGrouped] autorelease];
         [self.navigationController pushViewController:dvc animated:YES];
         break;
      }
      case rowMailSettings:
      {
         // mail settings
         
         MailPrefController* dvc = [[[MailPrefController alloc] init] autorelease];
         
         [dvc fill];
         
         [self.navigationController pushViewController:dvc animated:YES];
         
         break;
      }
      case rowCategories:
      {
         // categories
         
         CategoryOverviewController* dvc = [[[CategoryOverviewController alloc] initWithStyle:UITableViewStylePlain] autorelease];
         dvc.mode = tpEdit;
         
         [self.navigationController pushViewController:dvc animated:YES];
         break;
      }
      case rowUsers:
      {
         // user management
         
         if (!([[SessionManager activeUser].rights intValue] & rightAdmin))
         {
            // we're no admin, only show THIS user
            
            UserEdit* dvc = [[[UserEdit alloc] initWithStyle:UITableViewStyleGrouped] autorelease];
            [dvc fill:[SessionManager activeUser]];
            dvc.isRestrictedMode= YES;
            
            [self.navigationController pushViewController:dvc animated:YES];
         }
         else
         {
            // we're admin, show userlist
            
            UserList* dvc = [[[UserList alloc] initWithStyle:UITableViewStyleGrouped] autorelease];
            [self.navigationController pushViewController:dvc animated:YES];
         }
         
         break;
      }
      case rowTimeTables:
      {
         // timetables (only visible if unit == hours
         
         TimeTableList* dvc = [[[TimeTableList alloc] initWithStyle:UITableViewStyleGrouped] autorelease];
         
         [self.navigationController pushViewController:dvc animated:YES];
         break;
      }
      case rowFeedback:
      {
         [self sendMailWithSubject:@"App Feedback"];
         break;
      }
      case rowLogout:
      {
         [self dismiss];
         [[SessionManager session] logout];
         
         break;
      }
      case rowWipe:
      {
         // wipe data button
         
         UIAlertController* alert= [UIAlertController alertControllerWithTitle:NSLocalizedString(@"Wipe data", nil) message:NSLocalizedString(@"Are you sure you want to erase all data? This operation can not be undone.", nil) preferredStyle:UIAlertControllerStyleAlert];
         
         [alert addAction:[UIAlertAction actionWithTitle:@"Okay" style:UIAlertActionStyleDefault handler:^(UIAlertAction* action)
                           {
                              [[Storage currentStorage] wipeData:[Settings globalSettingBool:skSingleUser] completionHandler:^(BOOL success)
                               {
                                  [[SessionManager session] logout];
         
                                  AppDelegate* del= (AppDelegate*)[UIApplication sharedApplication].delegate;
                                  UIAlertController* confirmation= [UIAlertController alertControllerWithTitle:NSLocalizedString(@"Wipe data", nil) message:NSLocalizedString(@"Data successfully wiped.", nil) preferredStyle:UIAlertControllerStyleAlert];

                                  [confirmation addAction:[UIAlertAction actionWithTitle:NSLocalizedString(@"Okay", nil) style:UIAlertActionStyleCancel handler:nil]];
                                  confirmation.view.tintColor = MAINCOLORDARK;
                                  [self presentViewController:confirmation animated:YES completion:^(){
                                     [del hideMenu];
                                  }];
                               }];                              
                           }]];

         [alert addAction:[UIAlertAction actionWithTitle:NSLocalizedString(@"Cancel", nil) style:UIAlertActionStyleCancel handler:^(UIAlertAction* action)
                           {
                              [self.tableView reloadData];
                           }]];
         
         alert.view.tintColor = MAINCOLORDARK;
         [self presentViewController:alert animated:YES completion:nil];
         
         break;
      }
      default:
         break;
   }
}

#pragma mark - UINavigationControllerDelegate

// ************************************************************
// willShowViewController
// ************************************************************

- (void)navigationController:(UINavigationController *)navigationController willShowViewController:(UIViewController *)viewController animated:(BOOL)animated
{
   [viewController viewWillAppear:animated];
}

#pragma mark - mail stuff

// ************************************************************
// willShowViewController
// ************************************************************

- (void)sendMailWithSubject:(NSString*)subject
{
   MFMailComposeViewController* picker = [[[MFMailComposeViewController alloc] init] autorelease];
   
   if (![MFMailComposeViewController canSendMail] || picker == nil)
   {
      [Service alert:NSLocalizedString(@"Can't send mail", nil) withText:NSLocalizedString(@"Can't send mails because this device is not configured to send mails.", nil) andError:nil forController:self completion:nil];
      return;
   }
   
   UIDevice* dev= [UIDevice currentDevice];
   NSString* osVersion= [dev systemVersion];
   NSString* appName= [[[NSBundle mainBundle] localizedInfoDictionary] objectForKey:@"CFBundleDisplayName"];
   
   if (appName == nil)
      appName= [[[NSBundle mainBundle] infoDictionary] objectForKey:@"CFBundleDisplayName"];
   
   NSString* config= [NSString stringWithFormat:@"App configuration\n-----------------\nFree days: 0x%x\nCalendar storage: %d\nStore calendar name: %@\nPublic holiday calendar: %d\nPublic holiday calendar name: '%@'\nLeave Year: %@\nUnit: %d\n-----------------",
                      [Settings userSettingInt:skFreeDays], [Settings userSettingBool:skStoreInCalendar], [EventService storageCalendar].title, [Settings userSettingBool:skUsePublicHolidayCalendar], [EventService publicHolidayCalendar].title, [[Service dateFormatter] stringFromDate:[Settings userSettingObject:skYearBegin]], [Settings userSettingInt:skUnit]];
   
   NSString* body= [NSString stringWithFormat:@"\n\n\n-----------------\nDevice Info\n-----------------\nDevice: %@\niOS version: %@\nApp version: %@ %@ (%@)\n-----------------\n%@",
                    deviceName(), osVersion, appName, [[[NSBundle mainBundle] infoDictionary] objectForKey:@"CFBundleShortVersionString"], [[[NSBundle mainBundle] infoDictionary] objectForKey:@"CFBundleVersion"], config];
   
   picker.mailComposeDelegate = self;
   picker.navigationBar.barStyle = UIBarStyleDefault;
   
   NSArray* rcpt= [[[NSArray alloc] initWithObjects:@"leavedays@posteo.de", nil] autorelease];
   
   [picker setToRecipients:rcpt];
   
   if ([subject length])
      [picker setSubject:subject];
   
   [picker setMessageBody:body isHTML:NO];
   
   [self presentViewController:picker animated:YES completion:nil];
}

- (void)mailComposeController:(MFMailComposeViewController*)controller didFinishWithResult:(MFMailComposeResult)result error:(NSError*)error
{
   // Notifies users about errors associated with the interface
   
   switch (result)
   {
      case MFMailComposeResultCancelled: break;
      case MFMailComposeResultSaved:     break;
      case MFMailComposeResultSent:      break;

      case MFMailComposeResultFailed:
      default:
      {
         NSString* errorText= error ? [error localizedDescription] : @"Unknown error";
         
         [Service alert:@"Email Error" withText:errorText andError:error forController:self completion:nil];
         break;
      }
   }

   [controller dismissViewControllerAnimated:YES completion:nil];
}

@end
