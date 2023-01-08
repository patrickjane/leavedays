//************************************************************
// Menu.m
// Holliday
//************************************************************
// Created by Patrick Fial on 01.09.13.
// Copyright 2013-2013 Patrick Fial. All rights reserved.
//************************************************************

//************************************************************
// includes
//************************************************************

#import "AppDelegate.h"
#import "Menu.h"
#import "SettingsDialog.h"
#import "SessionManager.h"

#import "OverviewController.h"

//************************************************************
// table definition
//************************************************************

enum RowDefs
{
   rowOverview,
   rowCalendar,
   rowMonthView,
   
   rowSettings,
   rowImportExport,
   
   rowLogout,
   
   cntRows
};

enum SectionDefs
{
   sctLeave,
   sctOptions,
   sctSession,
   
   cntSections
};

static RowInfo** rowInfos= 0;
static SectionInfo** sectionInfos= 0;

//************************************************************
// class MenuController
//************************************************************

@implementation Menu

#pragma mark - Lifecycle

//************************************************************
// initWithFrame
//************************************************************

- (id)initWithStyle:(UITableViewStyle)style
{
   self = [super initWithStyle:style];
   
   if (self)
   {
      // Custom initialization
      
      if (!rowInfos)
      {
         rowInfos= (RowInfo**)calloc(cntRows+1, sizeof(RowInfo*));
         
         rowInfos[rowOverview]=       rowInit(malloc(sizeof(RowInfo)),  rowOverview,      sctLeave,    0,  NSLocalizedString(@"Leave overview", nil), nil);
         rowInfos[rowCalendar]=       rowInit(malloc(sizeof(RowInfo)),  rowCalendar,      sctLeave,    1,  NSLocalizedString(@"Calendar", nil), nil);
         rowInfos[rowMonthView]=      rowInit(malloc(sizeof(RowInfo)),  rowMonthView,     sctLeave,    2,  NSLocalizedString(@"Monthly overview", nil), nil);
         rowInfos[rowSettings]=       rowInit(malloc(sizeof(RowInfo)),  rowSettings,      sctOptions,  0,  NSLocalizedString(@"Settings", nil), nil);
         rowInfos[rowImportExport]=   rowInit(malloc(sizeof(RowInfo)),  rowImportExport,  sctOptions,  1,  NSLocalizedString(@"Import/Export", nil), nil);
         rowInfos[rowLogout]=         rowInit(malloc(sizeof(RowInfo)),  rowLogout,        sctSession,  0,  NSLocalizedString(@"Logout", nil), nil);
         
         rowInfos[cntRows]= 0;
      }
      
      if (!sectionInfos)
      {
         sectionInfos= (SectionInfo**)calloc(cntSections+1, sizeof(SectionInfo*));
         
         sectionInfos[sctLeave]=    sectInit(malloc(sizeof(SectionInfo)),  3, NSLocalizedString(@"Leave", nil), nil);
         sectionInfos[sctOptions]=  sectInit(malloc(sizeof(SectionInfo)),  2, NSLocalizedString(@"Options", nil), nil);
         sectionInfos[sctSession]=  sectInit(malloc(sizeof(SectionInfo)),  1, NSLocalizedString(@"Session", nil), nil);
         
         sectionInfos[cntSections]= 0;
      }
   }
   
   return self;
}

-(void)loadView
{
   [super loadView];
   
}

//************************************************************
// viewDidLoad
//************************************************************

- (void)viewDidLoad
{
   [super viewDidLoad];
   
   //self.view.autoresizingMask= UIViewAutoresizingFlexibleHeight;
   
   self.navigationItem.leftBarButtonItem= nil;
   self.tableView.frame= CGRectMake(self.tableView.frame.origin.x, self.view.frame.origin.y + 20.0,
                                    self.tableView.frame.size.width - 1.0, self.tableView.frame.size.height);
   
   self.tableView.backgroundColor= UIColorFromRGB(0x414141);
   
   // Uncomment the following line to preserve selection between presentations.
   // self.clearsSelectionOnViewWillAppear = NO;
   
   // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
   
//   AppDelegate* app = [UIApplication sharedApplication].delegate;
//   ContainerController* container= app.container;

//   self.navigationItem.leftBarButtonItem= [[[UIBarButtonItem alloc] initWithTitle:NSLocalizedString(@"Done", nil) style:UIBarButtonItemStylePlain target:container action:@selector(hideMenu)] autorelease];
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
   static NSString *CellIdentifier = @"Cell";
   UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
   
   if (!cell)
   {
      cell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleValue1 reuseIdentifier: @"Cell"] autorelease];
      cell.backgroundColor= UIColorFromRGB(0x414141);
      cell.textLabel.textColor= [UIColor whiteColor];
      
   }
   
   // Configure the cell...
   
   cell.textLabel.text= CELLTEXT;
   
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

#pragma mark - Table view delegate

//************************************************************
// didSelectRowAtIndexPath
//************************************************************

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
   if (ISCELL(rowLogout))
   {
//      AppDelegate* app = [UIApplication sharedApplication].delegate;
//      ContainerController* container= app.container;
//
//      [container hideMenu];
      
      [[SessionManager session] logout];
   }
   else if (ISCELL(rowOverview))
   {
      // overview
      
      OverviewController* dvc= [[OverviewController alloc] initWithStyle:UITableViewStyleGrouped];
      
      [dvc load];
      [self.navigationController pushViewController:dvc animated:YES];
      
      [dvc release];
      
//      self.pushedOverviewPage= dvc;
   }
   else
   {
      SettingsDialog* dvc= [[[SettingsDialog alloc] initWithStyle:UITableViewStyleGrouped] autorelease];
      UINavigationController* nvc= [[[UINavigationController alloc] initWithRootViewController:dvc] autorelease];
      
      nvc.modalPresentationStyle= UIModalPresentationFormSheet;
      [self presentViewController:nvc animated:YES completion:nil];
   }
}

@end
