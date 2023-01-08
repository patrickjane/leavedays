//************************************************************
// CsvCreator.m
// Holiday
//************************************************************
// Created by Patrick Fial on 08.03.2019.
// Copyright 2019-2019 Patrick Fial. All rights reserved.
//************************************************************

//************************************************************
// includes
//************************************************************

#import "CsvCreator.h"
#import "Service.h"
#import "SessionManager.h"
#import "YearSummary.h"
#import "User.h"
#import "LeaveInfo.h"
#import "Pool.h"
#import "Storage.h"
#import "Category.h"
#import "ActionPicker.h"
#import "CHCSVParser.h"

enum RowDefs
{
   rowFilename,
   rowTitle,
   rowYears,
   rowCategories,
   rowPlanned,
   rowUnknown,
   rowSummary,
   rowList,
   rowLeaveTitle,
   rowDate,
   rowDuration,
   rowCategory,
   rowDetailDays,
   
   cntRows
};

static RowInfo** rowInfos= 0;
static SectionInfo** sectionInfos= 0;

enum Options
{
   oPlanned=   0x00001,
   oUnknown=   0x00002,
   
   oSummary=   0x00004,
   oList=      0x00008,
   oDate=      0x00010,
   oDuration=  0x00020,
   oCategory=  0x00040,
   oTitle=     0x00080,
   oDetailDays=0x00100
};

//************************************************************
// class CsvCreator
//************************************************************

@implementation CsvCreator

@synthesize excludedCategories, editedIndex, documentTitle,fileName, csvData;

//************************************************************
// initWithStyle
//************************************************************

-(id)initWithStyle:(UITableViewStyle)style
{
   self = [super initWithStyle:style];
   
   if (self)
   {
      if (!rowInfos)
      {
         rowInfos= (RowInfo**)calloc(cntRows+1, sizeof(RowInfo*));
         rowInfos[rowFilename]=     rowInit(malloc(sizeof(RowInfo)), rowFilename,   0, 0, NSLocalizedString(@"Filename", nil), nil);
         rowInfos[rowTitle]=        rowInit(malloc(sizeof(RowInfo)), rowTitle,      0, 1, NSLocalizedString(@"Document title", nil), nil);
         rowInfos[rowYears]=        rowInit(malloc(sizeof(RowInfo)), rowYears,      0, 2, NSLocalizedString(@"Leave Year", nil), nil);
         rowInfos[rowCategories]=   rowInit(malloc(sizeof(RowInfo)), rowCategories, 0, 3, NSLocalizedString(@"Excluded categories", nil), nil);
         rowInfos[rowPlanned]=      rowInit(malloc(sizeof(RowInfo)), rowPlanned,    0, 4, NSLocalizedString(@"Include planned leave ", nil), nil);
         rowInfos[rowUnknown]=      rowInit(malloc(sizeof(RowInfo)), rowUnknown,    0, 5, NSLocalizedString(@"Include unkown date leave ", nil), nil);
         
         rowInfos[rowSummary]=      rowInit(malloc(sizeof(RowInfo)), rowSummary,    1, 0, NSLocalizedString(@"Add summary", nil), nil);
         rowInfos[rowList]=         rowInit(malloc(sizeof(RowInfo)), rowList,       1, 1, NSLocalizedString(@"Add leave list", nil), nil);
         rowInfos[rowLeaveTitle]=   rowInit(malloc(sizeof(RowInfo)), rowLeaveTitle, 1, 2, NSLocalizedString(@"Add title", nil), nil);
         rowInfos[rowDate]=         rowInit(malloc(sizeof(RowInfo)), rowDate,       1, 3, NSLocalizedString(@"Add date", nil), nil);
         rowInfos[rowDuration]=     rowInit(malloc(sizeof(RowInfo)), rowDuration,   1, 4, NSLocalizedString(@"Add duration", nil), nil);
         rowInfos[rowCategory]=     rowInit(malloc(sizeof(RowInfo)), rowCategory,   1, 5, NSLocalizedString(@"Add category name", nil), nil);
         rowInfos[rowDetailDays]=   rowInit(malloc(sizeof(RowInfo)), rowSummary,    1, 6, NSLocalizedString(@"Detailed days info", nil), nil);
         rowInfos[cntRows]= 0;
      }
      
      if (!sectionInfos)
      {
         sectionInfos= (SectionInfo**)calloc(2+1, sizeof(SectionInfo*));
         sectionInfos[0]= sectInit(malloc(sizeof(SectionInfo)), 6, NSLocalizedString(@"Select export options", nil), nil);
         sectionInfos[1]= sectInit(malloc(sizeof(SectionInfo)), 7, NSLocalizedString(@"Select file contents", nil), nil);
         sectionInfos[2]= 0;
      }
      
      leaveYear= [SessionManager currentYear].year.intValue;
      options= oSummary | oList | oDate | oDuration | oTitle;
      
      self.editedIndex= nil;
      self.documentTitle= NSLocalizedString(@"Leave summary", nil);
      self.fileName= NSLocalizedString(@"leavesummary.csv", nil);
      self.excludedCategories= [NSMutableArray array];
   }
   
   return self;
}

//************************************************************
// viewDidLoad
//************************************************************

- (void)viewDidLoad
{
    [super viewDidLoad];
    
   self.navigationItem.title= NSLocalizedString(@"Create CSV", nil);
   self.navigationItem.leftBarButtonItem= [[[UIBarButtonItem alloc]
                                             initWithBarButtonSystemItem:UIBarButtonSystemItemCancel
                                             target:self
                                             action:@selector(dismiss)] autorelease];
   
   self.navigationItem.rightBarButtonItem= [[[UIBarButtonItem alloc]
                                             initWithBarButtonSystemItem:UIBarButtonSystemItemAction
                                             target:self
                                             action:@selector(startExport)] autorelease];
   
   self.modalPresentationCapturesStatusBarAppearance = YES;
}

-(void)dismiss
{
   [self dismissViewControllerAnimated:YES completion:nil];
}
#pragma mark - Table view data source

//************************************************************
// numberOfSectionsInTableView
//************************************************************

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 2;
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
      case rowYears:
      case rowCategories:
      {
         UITableViewCell* cell = [tableView dequeueReusableCellWithIdentifier:@"Cell"];
         
         if (cell == nil)
         {
            if (ISCELL(rowCategories))
               cell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:@"Cell"] autorelease];
            else
               cell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleValue1 reuseIdentifier:@"Cell"] autorelease];
            
            cell.detailTextLabel.textColor= DETAILEXTCOLOR;
         }
         
         if (ISCELL(rowYears))
         {
            cell.detailTextLabel.text= [NSString stringWithFormat:@"%d", leaveYear];
         }
         else if (ISCELL(rowCategories))
         {
            // categories
            
            NSMutableString* string= [NSMutableString string];
            
            for (CategoryRef* cat in self.excludedCategories)
               [string appendFormat:(string.length ? @", %@" : @"%@"), cat.name];
            
            if (excludedCategories.count)
            {
               cell.detailTextLabel.text= string;
               cell.detailTextLabel.textColor= DETAILEXTCOLOR;
            }
            else
            {
               cell.detailTextLabel.text= NSLocalizedString(@"None", nil);
               cell.detailTextLabel.textColor= [UIColor lightGrayColor];
            }
         }

         cell.textLabel.text = CELLTEXT;
         return cell;
      }

      case rowPlanned:
      case rowUnknown:
      case rowSummary:
      case rowList:
      case rowLeaveTitle:
      case rowDate:
      case rowDuration:
      case rowCategory:
      case rowDetailDays:
      {
         SwitchCell* switchCell = (SwitchCell*)[tableView dequeueReusableCellWithIdentifier:@"SwitchCell_Small"];
         
         if (switchCell == nil)
         {
            NSArray* nibContents= [[NSBundle mainBundle] loadNibNamed:@"SwitchCell_Small" owner:self options:nil];
            switchCell = [nibContents lastObject];
            switchCell.selectionStyle = UITableViewCellSelectionStyleNone;
         }
         
         switchCell.label.text = CELLTEXT;
         
         switchCell.valueChanged= ^(BOOL value)
         {
            if (ISCELL(rowPlanned))         options= value ? (options | oPlanned)  : (options & ~oPlanned);
            else if (ISCELL(rowUnknown))    options= value ? (options | oUnknown)  : (options & ~oUnknown);
            else if (ISCELL(rowSummary))    options= value ? (options | oSummary)  : (options & ~oSummary);
            else if (ISCELL(rowList))       options= value ? (options | oList)     : (options & ~oList);
            else if (ISCELL(rowLeaveTitle)) options= value ? (options | oTitle)    : (options & ~oTitle);
            else if (ISCELL(rowDate))       options= value ? (options | oDate)     : (options & ~oDate);
            else if (ISCELL(rowDuration))   options= value ? (options | oDuration) : (options & ~oDuration);
            else if (ISCELL(rowCategory))   options= value ? (options | oCategory) : (options & ~oCategory);
            else if (ISCELL(rowDetailDays)) options= value ? (options | oDetailDays) : (options & ~oDetailDays);
         };
         
         bool on= false;
         
         if (ISCELL(rowPlanned))         on= (options & oPlanned);
         else if (ISCELL(rowUnknown))    on= (options & oUnknown);
         else if (ISCELL(rowSummary))    on= (options & oSummary);
         else if (ISCELL(rowList))       on= (options & oList);
         else if (ISCELL(rowLeaveTitle)) on= (options & oTitle);
         else if (ISCELL(rowDate))       on= (options & oDate);
         else if (ISCELL(rowDuration))   on= (options & oDuration);
         else if (ISCELL(rowCategory))   on= (options & oCategory);
         else if (ISCELL(rowDetailDays)) on= (options & oDetailDays);
         
         switchCell.vSwitch.on= on;

         return switchCell;
      }

      case rowFilename:
      case rowTitle:
      {
         TextCell* textCell = (TextCell*)[tableView dequeueReusableCellWithIdentifier:@"TextCell_Small"];
         
         if (textCell == nil)
         {
            NSArray* nibContents= [[NSBundle mainBundle] loadNibNamed:@"TextCell_Small" owner:self options:nil];
            
            textCell = [nibContents lastObject];
            textCell.selectionStyle = UITableViewCellSelectionStyleNone;
            textCell.textField.delegate = self;
            textCell.textField.textColor= [UIColor colorWithRed:0.556863 green:0.556863 blue:0.576471 alpha:1.0];
         }
 
         if (ISCELL(rowTitle))
         {
            textCell.textField.placeholder= NSLocalizedString(@"Enter document title", nil);
            textCell.textField.text= self.documentTitle;
         }
         else
         {
            textCell.textField.placeholder= NSLocalizedString(@"Enter filename", nil);
            textCell.textField.text= self.fileName;
         }
         
         textCell.label.text= CELLTEXT;
         
         return textCell;
      }
      default:
         break;
   }
   
   return nil;
}

#pragma mark - Tableview Delegate

//************************************************************
// didSelectRowAtIndexPath
//************************************************************

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
   int cellIndex= toCell(indexPath, rowInfos);

   if (ISCELL(rowYears))
   {
      NSMutableArray* years= [NSMutableArray array];
      
      for (YearSummary* sum in [SessionManager activeUser].years)
         [years addObject:[NSString stringWithFormat:@"%@", sum.year]];

      ActionPicker* picker= [[[ActionPicker alloc] initWithValues:years andSelection:[NSString stringWithFormat:@"%d", leaveYear]] autorelease];
      
      picker.saveOnDismiss = TRUE;
      picker.valueChanged= ^(NSString* value)
      {
         leaveYear = value.intValue;
         [self.tableView reloadRowsAtIndexPaths:[NSArray arrayWithObject:toIndexPath(cellIndex, rowInfos)] withRowAnimation:UITableViewRowAnimationAutomatic];
      };
      
      [picker show];
   }
   
   else if (ISCELL(rowCategories))
   {
      CategoryOverviewController* dvc= [[[CategoryOverviewController alloc] initWithStyle:UITableViewStyleGrouped] autorelease];
      dvc.mode= tpMultiSelect;
      dvc.delegate= self;
      dvc.categoryMultiSelection= self.excludedCategories;
      
      [self.navigationController pushViewController:dvc animated:YES];
   }
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

#pragma mark TextInputCellDelegate

// ************************************************************
// saveText
// ************************************************************

-(void)saveText:(NSString *)newText fromTextField:(UITextField*)aTextField
{
   if (isCell(rowTitle, self.editedIndex, rowInfos))
      self.documentTitle= newText;
   else
      self.fileName= newText;
}

#pragma mark - CategoryOverviewControllerDelegate

//************************************************************
// setNewCategory
//************************************************************

- (void)setNewCategory:(CategoryRef*)category
{
   
}

-(void)setNewCategories:(NSMutableArray*)categories
{
   self.excludedCategories= categories;
   [self.tableView reloadRowsAtIndexPaths:[NSArray arrayWithObject:[NSIndexPath indexPathForRow:rowInfos[rowCategories]->row inSection:rowInfos[rowCategories]->section]] withRowAnimation:UITableViewRowAnimationNone];
}

#pragma mark - CSV generation

//************************************************************
// startExport
//************************************************************

-(void)startExport
{
   if ([self createCsv] == TRUE)
   {
      NSArray* paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
      NSString* documentsDirectory = [paths objectAtIndex:0];
      NSError* error= nil;
      
      //make a file name to write the data to using the documents directory:
      
      NSString* localFilePath = nil;
      NSString* completeFileName = self.fileName;
      
      if (![completeFileName hasSuffix:@".csv"])
         completeFileName= [NSString stringWithFormat:@"%@.csv", self.fileName];
      
      localFilePath= [NSString stringWithFormat:@"%@/%@", documentsDirectory, completeFileName];
      
      NSURL* url = [NSURL fileURLWithPath:localFilePath isDirectory:NO];
      
      [self.csvData writeToURL:url options:0 error:&error];

      if (error)
      {
         [Service alert:@"Error" withText:NSLocalizedString(@"Failed to write file", nil) andError:error forController:self completion:nil];
         return;
      }
      
      UIActivityViewController* activity = [[[UIActivityViewController alloc] initWithActivityItems:[NSArray arrayWithObjects:url, nil] applicationActivities:nil] autorelease];
      
      activity.completionWithItemsHandler = ^(NSString *activityType, BOOL completed, NSArray *returnedItems, NSError *activityError) {
                   NSError* error= nil;
                   [[NSFileManager defaultManager] removeItemAtURL:url error:&error];
         
                   if (error)
                      [Service alert:@"Error" withText:NSLocalizedString(@"Failed to remove temporary file", nil) andError:error forController:self completion:nil];
      };
      
      [self presentViewController:activity animated:YES completion:nil];
   }
}

// ************************************************************
// createCsv
// ************************************************************

- (BOOL) createCsv
{
   NSOutputStream* outputStream = [[NSOutputStream alloc] initToMemory];
   [outputStream open];
   
   CHCSVWriter* writer = [[[CHCSVWriter alloc] initWithOutputStream:outputStream encoding:NSUTF8StringEncoding delimiter:';'] autorelease];
   User* currentUser= [SessionManager activeUser];
   YearSummary* sum= [[Storage currentStorage] getYear:leaveYear withUserId:currentUser.uuid];
   
   if (!sum)
   {
      NSLog(@"ERROR: no year summary for user %@ for year %d", currentUser.name, leaveYear);
      return NO;
   }
   
   // leave year first
   
   [writer writeField:NSLocalizedString(@"Leave year", nil)];
   [writer writeField:[NSNumber numberWithInt:leaveYear]];
   [writer finishLine];
   
   // summary, if configured
   
   if (options & oSummary)
   {
      NSArray* pools= nil;
      
      if (options & oDetailDays)
      {
         pools= sum.pools;
         [writer writeField:NSLocalizedString(@"Category", nil)];
      }
      
      [writer writeField:NSLocalizedString(@"Per year", nil)];
      [writer writeField:NSLocalizedString(@"Spent", nil)];
      [writer writeField:NSLocalizedString(@"Remaining", nil)];
      
      if (options & oDetailDays)
         [writer writeField:NSLocalizedString(@"Earned", nil)];
      
      [writer finishLine];
      
      if (!(options & oDetailDays))
      {
         [writer writeField:[Service niceDuration:sum.amount_with_pools.doubleValue withCategory:nil]];
         [writer writeField:[Service niceDuration:sum.amount_spent_with_pools.doubleValue withCategory:nil]];
         [writer writeField:[Service niceDuration:sum.amount_remain_with_pools.doubleValue withCategory:nil]];
         [writer finishLine];
      }
      else
      {
         [writer writeField:NSLocalizedString(@"Annual leave", nil)];
         [writer writeField:[Service niceDuration:sum.amount_with_pools.doubleValue withCategory:nil]];
         [writer writeField:[Service niceDuration:sum.amount_spent_with_pools.doubleValue withCategory:nil]];
         [writer writeField:[Service niceDuration:sum.amount_remain_with_pools.doubleValue withCategory:nil]];
         [writer writeField:@""];
         [writer finishLine];

         for (Pool* pool in pools)
         {
            CategoryRef* cat = [Storage categoryForName:pool.category ofUser:[SessionManager activeUser]];
            
            [writer writeField:pool.category];
            [writer writeField:[Service niceDuration:pool.pool.doubleValue withCategory:cat]];
            [writer writeField:[Service niceDuration:pool.spent.doubleValue withCategory:cat]];
            [writer writeField:[Service niceDuration:pool.remain.doubleValue withCategory:cat]];
            
            if (pool.earned.doubleValue > 0.0)
               [writer writeField:[Service niceDuration:pool.earned.doubleValue withCategory:cat]];
            else
               [writer writeField:@""];
            
            [writer finishLine];
            
            if ([pool.expired doubleValue] > 0.0)
            {
               [writer writeField:[NSString stringWithFormat:@"%@ (%@)", pool.category, NSLocalizedString(@"expired", nil)]];
               [writer writeField:[Service niceDuration:pool.expired.doubleValue withCategory:cat]];
               [writer writeField:@""];
               [writer writeField:@""];
               [writer writeField:@""];
               [writer finishLine];
            }
         }
      }

      [writer finishLine];
   }
   
   if (options & oList)
   {
      NSPredicate* pred= [NSPredicate predicateWithBlock:^(id obj, NSDictionary* bindings)
                          {
                             LeaveInfo* ifo= (LeaveInfo*)obj;
                             if (ifo.year.intValue == leaveYear) return YES;
                             return NO;
                          }];
      
      NSSortDescriptor* sort= [NSSortDescriptor sortDescriptorWithKey:@"begin" ascending:NO];
      NSArray* results= [[Storage currentStorage] getLeaveForUsers:[NSArray arrayWithObject:[SessionManager activeUser].uuid] withFilter:pred andSorting:[NSArray arrayWithObject:sort]];
      
      NSMutableArray* categories= [NSMutableArray array];
      
      for (CategoryRef* cat in self.excludedCategories)
         [categories addObject:cat.name];
      
      // header row
      
      if (options & oTitle)
         [writer writeField:NSLocalizedString(@"Title", nil)];
      
      if (options & oDate)
         [writer writeField:NSLocalizedString(@"Date", nil)];
      
      if (options & oDuration)
         [writer writeField:NSLocalizedString(@"Duration", nil)];
      
      if (options & oCategory)
         [writer writeField:NSLocalizedString(@"Category", nil)];

      [writer finishLine];
      
      for (LeaveInfo* info in results)
      {
         if (info.isUnknownDate.boolValue && !(options & oUnknown))
            continue;
         
         if ([info.status intValue] == 0 && (!(options & oPlanned)))
            continue;
         
         if ([categories containsObject:info.category])
            continue;
         
         if (options & oTitle)
            [writer writeField:info.title.length ? [info.title stringByReplacingOccurrencesOfString:@"\"" withString:@"\"\""] : @""];
         
         if (options & oDate)
            [writer writeField:info.isUnknownDate.boolValue ? @"" : [Service rangeStringForDate:info.begin end:info.end]];
         
         if (options & oDuration)
            [writer writeField:[Service niceDuration:info.duration.doubleValue withCategory:[Storage categoryForName:info.category ofUser:currentUser]]];
         
         if (options & oCategory)
            [writer writeField:info.category.length ? [info.category stringByReplacingOccurrencesOfString:@"\"" withString:@"\"\""] : @""];
         
         [writer finishLine];
      }
   }
   
   self.csvData = [outputStream propertyForKey:NSStreamDataWrittenToMemoryStreamKey];
   [outputStream close];
   
   return YES;
}

@end
