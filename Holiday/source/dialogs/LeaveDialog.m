//************************************************************
// AddPage.m
// Annual Leave iPad
//************************************************************
// Created by Patrick Fial on 12.01.2012
// Copyright 2012-2012 Patrick Fial. All rights reserved.
//************************************************************

//************************************************************
// includes
//************************************************************

#import "LeaveDialog.h"
#import "CategoryOverviewController.h"

#import "Settings.h"
#import "Service.h"
#import "EventService.h"
#import "Calculation.h"

#import "TextCell.h"
#import "TextInputMultilineCell.h"
#import "TimeTableSelection.h"
#import "SessionManager.h"
#import "ActionDate.h"
#import "DateCell.h"

#import "Category.h"
#import "Timetable.h"
#import "Pool.h"
#import "LeaveInfo.h"
#import "User.h"
#import "YearSummary.h"
#import "Storage.h"

static RowInfo** rowInfos= 0;
static SectionInfo** sectionInfos= 0;

//************************************************************
// class AddPage
//************************************************************

@implementation LeaveDialog

@synthesize beginDate;
@synthesize endDate;
@synthesize leaveInfo;
@synthesize leaveTitle;
@synthesize comment;
@synthesize rootViewController;
@synthesize availableYears;
@synthesize categoryName;
@synthesize editedIndex;
@synthesize timeTables;
@synthesize leaveYear;
@synthesize owner;
@synthesize location;
@synthesize completionHandler;

#pragma mark - lifecycle

// ************************************************************
// initWithStyle
// ************************************************************

- (id)initWithStyle:(UITableViewStyle)style
{
   self = [super initWithStyle:style];
   
   if (self) 
   {
      if (!rowInfos)
      {
         rowInfos= (RowInfo**)calloc(cntRows+1, sizeof(RowInfo*));
         rowInfos[rowTitle]=     rowInit(malloc(sizeof(RowInfo)), rowTitle,     0, 0, NSLocalizedString(@"Title", nil), nil); 
         rowInfos[rowBegin]=     rowInit(malloc(sizeof(RowInfo)), rowBegin,     0, 1, NSLocalizedString(@"Begin", nil), nil);
         rowInfos[rowEnd]=       rowInit(malloc(sizeof(RowInfo)), rowEnd,       0, 2, NSLocalizedString(@"End", nil), nil);
         
         rowInfos[rowDuration]=  rowInit(malloc(sizeof(RowInfo)), rowDuration,  1, 0, NSLocalizedString(@"Duration", nil), nil);
         rowInfos[rowEarnSpend]= rowInit(malloc(sizeof(RowInfo)), rowEarnSpend, 1, 1, NSLocalizedString(@"Mode", nil), nil);

         rowInfos[rowCategory]=  rowInit(malloc(sizeof(RowInfo)), rowCategory,  2, 0, NSLocalizedString(@"Category", nil), nil);
         rowInfos[rowTimetable]= rowInit(malloc(sizeof(RowInfo)), rowTimetable, 2, 1, NSLocalizedString(@"Timetable", nil), nil);
         rowInfos[rowYear]=      rowInit(malloc(sizeof(RowInfo)), rowYear,      2, 2, NSLocalizedString(@"Leave year", nil), nil);
         rowInfos[rowLocation]=  rowInit(malloc(sizeof(RowInfo)), rowLocation,  2, 3, NSLocalizedString(@"Location", nil), nil);
         rowInfos[rowState]=     rowInit(malloc(sizeof(RowInfo)), rowState,     2, 4, NSLocalizedString(@"Status", nil), nil);
         rowInfos[rowComment]=   rowInit(malloc(sizeof(RowInfo)), rowComment,   2, 5, NSLocalizedString(@"Comment", nil), nil);
         rowInfos[rowMail]=      rowInit(malloc(sizeof(RowInfo)), rowMail,      2, 6, NSLocalizedString(@"Send mail request", nil), nil);
         rowInfos[rowUnknown]=   rowInit(malloc(sizeof(RowInfo)), rowUnknown,   2, 7, NSLocalizedString(@"Unknown date", nil), nil);
         rowInfos[rowCalc]=      rowInit(malloc(sizeof(RowInfo)), rowCalc,      2, 8, NSLocalizedString(@"Calculate duration", nil), nil);
         rowInfos[cntRows]= 0;
      }

      if (!sectionInfos)
      {
         sectionInfos= (SectionInfo**)calloc(4+1, sizeof(SectionInfo*));
         sectionInfos[0]= sectInit(malloc(sizeof(SectionInfo)), 3, NSLocalizedString(@"Details", nil), nil);
         sectionInfos[1]= sectInit(malloc(sizeof(SectionInfo)), 2, NSLocalizedString(@"Duration", nil), nil);
         sectionInfos[2]= sectInit(malloc(sizeof(SectionInfo)), 10, NSLocalizedString(@"Options", nil), nil);
         sectionInfos[3]= sectInit(malloc(sizeof(SectionInfo)), 1, nil, nil);
         sectionInfos[4]= 0;
      }
      
      activeTextField= nil;
      activeTextView= nil;

      self.completionHandler= nil;
      self.location= nil;
      self.owner= [SessionManager activeUser].uuid;
      self.beginDate= [Service trunc:[NSDate date]];
      self.endDate= [Service trunc:[NSDate date]];
      self.leaveInfo = nil;
      self.leaveTitle = @"<Empty>";
      self.comment = @"<Empty>";
      self.categoryName = nil;
      duration = 0.0;
      beginHalfDay = NO;
      endHalfDay = NO;
      editBegin = NO;
      sendMail = NO;
      calculateDuration= YES;
      leaveYear= 0;
      needsHourInput= NO;
      self.editedIndex = nil;
      isUnknownDate= false;
      self.timeTables= nil;
      durationChanged= false;
      
      self.availableYears= [Storage getYearNumberList];
      
      memset(enabledOptions, 0, sizeof(enabledOptions));
   }

   return self;
}

// ************************************************************
// dealoc
// ************************************************************

- (void)dealloc 
{
   self.location= nil;
   self.leaveInfo = nil;
   self.editedIndex = nil;
   self.timeTables= nil;
   self.availableYears= nil;
   
   [super dealloc];
}

#pragma mark - View lifecycle

// ************************************************************
// viewDidLoad
// ************************************************************

- (void)viewDidLoad
{
   [super viewDidLoad];
   
   self.navigationItem.title = NSLocalizedString(@"Leave", nil);
   self.navigationItem.leftBarButtonItem = self.navigationItem.backBarButtonItem;
   
   UIBarButtonItem* saveButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemSave target:self action:@selector(saveRecord)];
   self.navigationItem.rightBarButtonItem = saveButton;
   [saveButton release];
   
   UIBarButtonItem* cancelButton= [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemCancel target:self action:@selector(cancel)];
   self.navigationItem.leftBarButtonItem = cancelButton;
   [cancelButton release];
   
   self.modalPresentationCapturesStatusBarAppearance = YES;
}

// ************************************************************
// viewWillAppear
// ************************************************************

- (void)viewWillAppear:(BOOL)animated
{
   [self recalculate];
   
   [[self tableView] reloadData];
   
   [super viewWillAppear:animated];
}

// ************************************************************
// disablesAutomaticKeyboardDismissal
// ************************************************************

- (BOOL)disablesAutomaticKeyboardDismissal
{
   return NO;
}

#pragma mark - Options handling

// ************************************************************
// nOptions
// ************************************************************

-(int)nOptions
{
   int nOptions= 0;
   
   for (int i= nOptFirst; i < cntRows; i++)
      if (enabledOptions[i-nOptFirst])
         nOptions++;
   
   return nOptions;
}

// ************************************************************
// optionIndex
// ************************************************************

-(int)optionIndex:(NSIndexPath*)index
{
   return [self optionIndexForRow:(int)index.row enabled:YES];
}

-(int)optionIndexForRow:(int)row enabled:(BOOL)enabled
{
   int opt= row;
   
   for (int i= nOptFirst; i < cntRows; i++)
   {
      if (enabledOptions[i-nOptFirst] == enabled)
      {
         if (!(opt--))
            return i;
      }
   }
   
   return addOption;
}

// ************************************************************
// indexPathForOption
// ************************************************************

-(NSIndexPath*)indexPathForOption:(int)index
{
   int row= 0;
   
   for (int i= nOptFirst; i < cntRows; i++)
   {
      if (enabledOptions[i-nOptFirst] == 1)
      {
         if (i == index)
            break;
         
         row++;
      }
   }
   
   return [NSIndexPath indexPathForRow:row inSection:2];
}

// ************************************************************
// removeDataForOption
// ************************************************************

-(void)removeDataForOption:(int)option
{
   switch (option)
   {
      case rowCategory:  self.categoryName = nil; break;
      case rowTimetable: [self.timeTables removeAllObjects]; break;
      case rowYear:      leaveYear = (int)[[NSCalendar currentCalendar] components:NSCalendarUnitYear fromDate:self.beginDate].year; break;
      case rowLocation:  self.location = nil; break;
      case rowState:     status = [Settings userSettingInt:skDefaultState]; break;
      case rowComment:   self.comment = nil; break;
      case rowMail:      sendMail = false; break;
      case rowUnknown:   {
         self.beginDate= [NSDate date];
         self.endDate= [NSDate date];

         isUnknownDate = false;
         break;
      }
      case rowCalc:
      {
         calculateDuration = true;
         [self recalculate];
         break;
      }
         
//      case rowOwner:     self.owner = [SessionManager displayUser].uuid; break;
         
      default: break;
   }
}

#pragma mark - Table view data source

// ************************************************************
// numberOfSectionsInTableView
// ************************************************************

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
   int sections= 4;
   
   if (!self.leaveInfo)
      sections--;
   
   return sections;
}

// ************************************************************
// numberOfRowsInSection
// ************************************************************

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
   if (section == 3)
      return 1;
   
   if (section == 1)
   {
      if (self.categoryName && self.categoryName.length)
         return sectionInfos[section]->rows;
      
      return sectionInfos[section]->rows-1;
   }

   if (section == 0)
      return sectionInfos[section]->rows;
   
   int n= [self nOptions];
   int max= cntRows - nSectSec -1;
   
   return n ? (n == max ? n : n + 1) : 1;
}

// ************************************************************
// heightForRowAtIndexPath
// ************************************************************

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
   int cellIndex= indexPath.section != 2 ? toCell(indexPath, rowInfos) : [self optionIndex:indexPath];

   if (indexPath.section == rowInfos[rowComment]->section && cellIndex == rowComment)
   {
      // comments-box
      return 210;
   }
   
   // default
   
   return tableView.rowHeight;
}

// ************************************************************
// cellForRowAtIndexPath
// ************************************************************

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
   SwitchCell* switchCell = nil;
   TextCell* textCell = nil;
   TextInputMultilineCell* textMultilineCell = nil;
   UITableViewCell* cell = nil;
   SegmentCell* segmentCell = nil;
   
   int cellIndex= indexPath.section != 2 ? toCell(indexPath, rowInfos) : [self optionIndex:indexPath];
   
   switch (cellIndex)
   {
      case rowCategory:
      case rowYear:
      case rowState:
      case rowTimetable:
      case rowLocation:
      case addOption:                   // "Add option..." button in the end of section 2
      {
         cell= [tableView dequeueReusableCellWithIdentifier:@"Cell2"];
         
         if (cell == nil)
            cell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleValue1 reuseIdentifier:@"Cell2"] autorelease];
         
         if (cellIndex == addOption)
            cell.textLabel.textColor= [UIColor colorNamed:@"cellMainText"];
         else
         {
            cell.textLabel.textColor= [UIColor colorNamed:@"cellMainText"];
            cell.textLabel.text=  cellTextFromIndex(cellIndex, rowInfos);
         }
         
         switch (cellIndex)
         {
            case addOption:
            {
               cell.textLabel.text= NSLocalizedString(@"Add option", nil);
               cell.detailTextLabel.text = @"+";
               cell.userInteractionEnabled= true;
               break;
            }
            case rowYear:
            {
               cell.detailTextLabel.text = [NSString stringWithFormat:@"%d", leaveYear];
               break;
            }
            case rowLocation:
            {
               cell.detailTextLabel.text= [self cityName];
               
               if (self.location)
                  cell.detailTextLabel.textColor = MAINCOLORDARK;

               break;
            }
            case rowState:
            {
               cell.selectionStyle = UITableViewCellSelectionStyleNone;
               cell.detailTextLabel.text = [Service titleForStatus:status];
               cell.detailTextLabel.textColor = [Service colorForState:status];
               break;
            }
            case rowCategory:
            {
               if (!self.categoryName)
               {
                  cell.detailTextLabel.text = NSLocalizedString(@"None", nil);
                  cell.detailTextLabel.textColor= DETAILEXTCOLOR;
               }
               else
               {
                  CategoryRef* c= [Storage categoryForName:self.categoryName ofUser:[[Storage currentStorage] userWithUUid:self.owner]];
                  
                  if (!c)
                  {
                     NSLog(@"FATAL: no category in cache for name '%@' and user '%@'", self.categoryName, self.owner);
                     cell.detailTextLabel.textColor = DETAILEXTCOLOR;
                  }
                  else
                  {
                     cell.detailTextLabel.textColor = [Service colorString:c.color];
                  }
                  
                  cell.detailTextLabel.text = self.categoryName;
               }
               
               break;
            }
            case rowTimetable:
            {
               NSString* tables= [Service stringForTimeTables:self.timeTables];
               
               cell.detailTextLabel.text = tables;
               cell.detailTextLabel.textColor= DETAILEXTCOLOR;
               break;
            }
         }

         return cell;
      }
      case rowMail:
      case rowUnknown:
      case rowCalc:
      {
         switchCell = (SwitchCell*)[tableView dequeueReusableCellWithIdentifier:@"SwitchCell_Small"];
         
         if (switchCell == nil)
         {
            NSArray* nibContents= [[NSBundle mainBundle] loadNibNamed:@"SwitchCell_Small" owner:self options:nil];
            switchCell = [nibContents lastObject];
            switchCell.selectionStyle = UITableViewCellSelectionStyleNone;
         }
         
         switchCell.label.text = cellTextFromIndex(cellIndex, rowInfos);
         
         if (cellIndex == rowMail)
         {
            switchCell.vSwitch.on = sendMail;
            switchCell.valueChanged= ^(BOOL value) { sendMail = value; };
         }
         else if (cellIndex == rowUnknown)
         {
            switchCell.vSwitch.on= isUnknownDate;
            switchCell.valueChanged= ^(BOOL value)
            {
               NSArray* idxes= [NSArray arrayWithObjects:
                                [NSIndexPath indexPathForRow:rowInfos[rowBegin]->row inSection:rowInfos[rowBegin]->section],
                                [NSIndexPath indexPathForRow:rowInfos[rowEnd]->row inSection:rowInfos[rowEnd]->section],
                                nil];
            
               isUnknownDate= value;
               
               if (value)
               {
                  self.beginDate= nil;
                  self.endDate= nil;
                  beginHalfDay= false;
                  endHalfDay= false;
               }
               else
               {
                  if (!self.beginDate)
                     self.beginDate= [NSDate date];
                  
                  if (!self.endDate)
                     self.endDate= [NSDate date];
                  
                  [self recalculate];
               }
               
               [[self tableView] reloadRowsAtIndexPaths:idxes withRowAnimation:NO];
            };
         }
         else
         {
            switchCell.vSwitch.on= calculateDuration;
            switchCell.valueChanged= ^(BOOL value) { calculateDuration= value;  if (value) [self recalculate];};
         }
         
         return switchCell;
      }
      case rowComment:
      {
         // comment
         
         textMultilineCell = (TextInputMultilineCell*)[tableView dequeueReusableCellWithIdentifier:@"TextInputMultilineCell"];
         
         if (textMultilineCell == nil)
         {
            NSArray* nibContents = [[NSBundle mainBundle] loadNibNamed:@"TextInputMultilineCell" owner:self options:nil];
            textMultilineCell = [nibContents lastObject];
            textMultilineCell.selectionStyle = UITableViewCellSelectionStyleNone;
            textMultilineCell.textView.delegate = self;
         }
         
         textMultilineCell.mainText.text = cellTextFromIndex(cellIndex, rowInfos);
         textMultilineCell.textView.text = self.comment;
         
         return textMultilineCell;
      }
      case rowDuration:
      case rowTitle:
      {
         textCell = (TextCell*)[tableView dequeueReusableCellWithIdentifier:@"TextCell_Small"];
         
         if (textCell == nil)
         {
            NSArray* nibContents= [[NSBundle mainBundle] loadNibNamed:@"TextCell_Small" owner:self options:nil];
            textCell = [nibContents lastObject];
            textCell.selectionStyle = UITableViewCellSelectionStyleNone;
            textCell.textField.delegate = self;
            textCell.textField.textColor= [UIColor colorNamed:@"cellSubText"];
            
            if (cellIndex == rowTitle)
            {
               textCell.textField.placeholder= NSLocalizedString(@"Enter title", nil);
               textCell.textField.keyboardType= UIKeyboardTypeDefault;
            }
            else
            {
               textCell.textField.placeholder= nil;
               textCell.textField.keyboardType= UIKeyboardTypeDecimalPad;
            }
         }

         textCell.label.text= cellTextFromIndex(cellIndex, rowInfos);
         textCell.textField.keyboardType= [Service keyboardTypeForType:[self typeForIndex:indexPath]];
         
         if (cellIndex == rowTitle)
         {
            textCell.textField.text = self.leaveTitle;
         }
         else if (needsHourInput || [Settings userSettingInt:skUnit])
         {
            // leave saved as hours
            
            textCell.label.text = NSLocalizedString(@"Hours", nil);
            
            NSInteger oldMax= [[Service numberFormatter] maximumFractionDigits];
            
            [[Service numberFormatter] setMaximumFractionDigits:2];
            
            textCell.textField.text = [[Service numberFormatter] stringFromNumber:[NSNumber numberWithDouble:duration]];
            
            [[Service numberFormatter] setMaximumFractionDigits:oldMax];
         }
         else
         {
            // leave saved as days
            
            textCell.label.text = NSLocalizedString(@"Days", nil);
            textCell.textField.text = [[Service numberFormatter] stringFromNumber:[NSNumber numberWithDouble:duration]];
         }
         
         return textCell;
      }
      case rowEarnSpend:
      {
         segmentCell = (SegmentCell*)[tableView dequeueReusableCellWithIdentifier:@"SegmentCell_Small"];

         if (segmentCell == nil)
         {
            NSArray* nibContents= [[NSBundle mainBundle] loadNibNamed:@"SegmentCell_Small" owner:self options:nil];

            segmentCell = [nibContents lastObject];
            segmentCell.selectionStyle = UITableViewCellSelectionStyleNone;

            [segmentCell.segment setTitle:NSLocalizedString(@"Spend", nil) forSegmentAtIndex:0];
            [segmentCell.segment setTitle:NSLocalizedString(@"Earn", nil) forSegmentAtIndex:1];
            [segmentCell.segment removeSegmentAtIndex:2 animated:FALSE];
            
            [segmentCell.segment addTarget:self action:@selector(leaveModeChanged:) forControlEvents:UIControlEventValueChanged];
         }

         segmentCell.label.text = cellTextFromIndex(cellIndex, rowInfos);
         segmentCell.segment.selectedSegmentIndex = self.leaveMode;

         return segmentCell;
      }
      case rowBegin:
      case rowEnd:
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
            }

            dateCell.label.text = cellTextFromIndex(cellIndex, rowInfos);
            dateCell.picker.date = cellIndex == rowBegin ? self.beginDate : self.endDate;
            dateCell.picker.hidden = isUnknownDate;
            dateCell.userInteractionEnabled= !isUnknownDate;
            
            if (cellIndex == rowBegin)
               [dateCell.button setTitle:beginHalfDay ? @"½" : @"1" forState:UIControlStateNormal];
            else
               [dateCell.button setTitle:endHalfDay ? @"½" : @"1" forState:UIControlStateNormal];
            
            dateCell.valueChanged = ^(NSDate* value)
            {
               NSIndexPath* otherIndex= nil;

               if (cellIndex == rowBegin)
               {
                  self.beginDate= value;
                  leaveYear= [Service getLeaveYearForDate:self.beginDate];

                  if ([self.beginDate timeIntervalSinceDate:self.endDate] > 0)
                  {
                     self.endDate= value;
                     otherIndex= toIndexPath(rowEnd, rowInfos);
                  }
               }
               else
               {
                  self.endDate= value;
                  
                  if ([self.endDate timeIntervalSinceDate:self.beginDate] < 0)
                  {
                     self.beginDate= value;
                     leaveYear= [Service getLeaveYearForDate:self.beginDate];
                     otherIndex= toIndexPath(rowBegin, rowInfos);
                  }
               }
               
               [[self tableView] reloadRowsAtIndexPaths:[NSArray arrayWithObject:indexPath] withRowAnimation:NO];
               
               if (otherIndex)
                  [[self tableView] reloadRowsAtIndexPaths:[NSArray arrayWithObject:otherIndex] withRowAnimation:NO];
               
               [self recalculate];
            };
            
            dateCell.halfDayValueChanged = ^(void)
            {
               if (cellIndex == rowBegin)
               {
                  beginHalfDay = !beginHalfDay;
                  [dateCell.button setTitle:beginHalfDay ? @"½" : @"1" forState:UIControlStateNormal];
               }
               else
               {
                  endHalfDay = !endHalfDay;
                  [dateCell.button setTitle:endHalfDay ? @"½" : @"1" forState:UIControlStateNormal];
               }
               
               [self recalculate];
            };

            return dateCell;
         }
         
         // "lame" datepicker with ios < 14
         
         cell= [tableView dequeueReusableCellWithIdentifier:@"Cell2"];
         
         if (cell == nil)
            cell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleValue1 reuseIdentifier:@"Cell2"] autorelease];
         
         if (cellIndex == addOption)
            cell.textLabel.textColor= [UIColor colorNamed:@"cellMainText"];
         else
         {
            cell.textLabel.textColor= [UIColor colorNamed:@"cellMainText"];
            cell.textLabel.text=  cellTextFromIndex(cellIndex, rowInfos);
         }
         
         if (isUnknownDate)
         {
            cell.detailTextLabel.text= NSLocalizedString(@"Unknown", nil);
         }
         else
         {
            if (cellIndex == rowBegin)
               cell.detailTextLabel.text= [NSString stringWithFormat:@"%@%@", [[Service dateFormatter] stringFromDate:self.beginDate], beginHalfDay ? @"  ½" : @""];
            else
               cell.detailTextLabel.text= [NSString stringWithFormat:@"%@%@", [[Service dateFormatter] stringFromDate:self.endDate], endHalfDay ? @"  ½" : @""];
         }
         
         cell.detailTextLabel.textColor= GREYINPUTCOLOR;
         cell.userInteractionEnabled= !isUnknownDate;
         
         return cell;
      }
      default:
      {
         // section 2, delete button only
         
         cell = [tableView dequeueReusableCellWithIdentifier:@"Cell"];
         
         if (cell == nil)
         {
            cell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"Cell"] autorelease];
            cell.textLabel.textColor= [UIColor whiteColor];
            [Service setRedCell:cell];       // add red backgrounds to cell
         }
         
         cell.textLabel.text = NSLocalizedString(@"Delete entry", nil);
         
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
   switch (section)
   {
      case 1: 
      {
         if (self.categoryName && self.leaveMode == lmSpend)
         {
            YearSummary* sum= [[Storage currentStorage] getYear:self.leaveYear];
            CategoryRef* cat= [Storage categoryForName:self.categoryName ofUser:[[Storage currentStorage] userWithUUid:self.owner]];
            Pool* pool= sum && cat ? [Storage poolOfArray:sum.pools withName:self.categoryName] : nil;
            
            if (pool && pool.remain.doubleValue <= 0.0)
               return [NSString stringWithFormat:NSLocalizedString(@"No remaining %@ for category '%@'. Using annual leave.", nil), NSLocalizedString(cat.savedAsHours.boolValue ? @"hours" : @"days", nil), self.categoryName];
            
            return nil;
         }
      }
         
      default: break;
   }
   
   return nil;
}

#pragma mark - Table view delegate

// ************************************************************
// didSelectRowAtIndexPath
// ************************************************************

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
   int cellIndex= indexPath.section != 2 ? toCell(indexPath, rowInfos) : [self optionIndex:indexPath];
   
   if (activeTextField)
   {
      [activeTextField resignFirstResponder];
      activeTextField= nil;
   }
   
   if (activeTextView)
   {
      [activeTextView resignFirstResponder];
      activeTextView= nil;
   }
   
   switch (cellIndex)
   {
      case addOption:
      {
         UIAlertController* actionSheet= [UIAlertController alertControllerWithTitle:NSLocalizedString(@"Add option", nil) message:nil preferredStyle:UIAlertControllerStyleActionSheet];
         
         for (int i= nOptFirst; i < cntRows; i++)
            if (!enabledOptions[i-nOptFirst])
               [actionSheet addAction:[UIAlertAction actionWithTitle:cellTextFromIndex(i, rowInfos) style:UIAlertActionStyleDefault handler:^(UIAlertAction* action)
                                       {
                                          enabledOptions[i-nOptFirst]= 1;
                                          
                                          switch (i)
                                          {
                                             case rowMail:    sendMail= !sendMail; break;
                                             case rowUnknown: isUnknownDate= !isUnknownDate; break;
                                             case rowCalc:    calculateDuration= !calculateDuration; break;
                                             case rowState:   status = !status; break;

                                             default: break;
                                          }

                                          [self.tableView reloadData];
                                          [self.tableView scrollToRowAtIndexPath:[NSIndexPath indexPathForRow:[self tableView:self.tableView numberOfRowsInSection:2]-1 inSection:2] atScrollPosition:UITableViewScrollPositionBottom animated:YES];
                                          
                                          switch (i)
                                          {
                                             case rowCategory:
                                             case rowTimetable:
                                             case rowYear:
                                             case rowLocation:  [self tableView:tableView didSelectRowAtIndexPath:[self indexPathForOption:i]];
                                             default: break;
                                          }                                          
                                       }]];
         
         [actionSheet addAction:[UIAlertAction actionWithTitle:NSLocalizedString(@"Cancel", nil) style:UIAlertActionStyleCancel handler:nil]];
         [self presentViewController:actionSheet animated:YES completion:nil];
         actionSheet.view.tintColor = MAINCOLORDARK;

         break;
      }
      case rowBegin:
      case rowEnd:
      {
         if (SYSTEM_VERSION_GREATER_THAN_OR_EQUAL_TO(@"14.0"))
            break;

         ActionDate* picker= [[[ActionDate alloc] initWithDate:cellIndex == rowBegin ? self.beginDate : self.endDate andHalfDay:(cellIndex == rowBegin ? beginHalfDay : endHalfDay)] autorelease];
         
         picker.valueChanged= ^(NSDate* value, bool isHalfDay)
         {
            NSIndexPath* otherIndex= nil;

            if (cellIndex == rowBegin)
            {
               beginHalfDay = isHalfDay;
               self.beginDate= value;
               leaveYear= [Service getLeaveYearForDate:self.beginDate];

               if ([self.beginDate timeIntervalSinceDate:self.endDate] > 0)
               {
                  self.endDate= value;
                  otherIndex= toIndexPath(rowEnd, rowInfos);
               }
            }
            else
            {
               endHalfDay = isHalfDay;
               self.endDate= value;
               
               if ([self.endDate timeIntervalSinceDate:self.beginDate] < 0)
               {
                  self.beginDate= value;
                  leaveYear= [Service getLeaveYearForDate:self.beginDate];
                  otherIndex= toIndexPath(rowBegin, rowInfos);
               }
            }
            
            [[self tableView] reloadRowsAtIndexPaths:[NSArray arrayWithObject:indexPath] withRowAnimation:NO];
            
            if (otherIndex)
               [[self tableView] reloadRowsAtIndexPaths:[NSArray arrayWithObject:otherIndex] withRowAnimation:NO];
            
            [self recalculate];
         };
         
         [picker show];
         
         break;
      }
      case rowCategory:
      {
         CategoryOverviewController* dvc= [[[CategoryOverviewController alloc] initWithStyle:UITableViewStyleGrouped] autorelease];

         dvc.mode = tpSelect;
         dvc.delegate= self;
         dvc.preferredContentSize= CGSizeMake(320.0, 360.0);
         dvc.categorySelection = [Storage categoryForName:self.categoryName ofUser:[[Storage currentStorage] userWithUUid:self.owner]];

         [self.navigationController pushViewController:dvc animated:YES];

         break;
      }
      case rowTimetable:
      {
         TimeTableSelection* dvc= [[[TimeTableSelection alloc] initWithStyle:UITableViewStyleGrouped] autorelease];

         dvc.timeTables= self.timeTables;
         dvc.preferredContentSize= CGSizeMake(320.0, 360.0);

         [self.navigationController pushViewController:dvc animated:YES];

         break;
      }
      case rowYear:
      {
         int range= 8;
         int currentYear= (int)[[NSCalendar currentCalendar] components:NSCalendarUnitYear fromDate:[NSDate date]].year;
         currentYear -= range/2;
         
         UIAlertController* actionSheet= [UIAlertController alertControllerWithTitle:NSLocalizedString(@"Select year", nil) message:nil preferredStyle:UIAlertControllerStyleActionSheet];
         
         for (int i= currentYear; i < currentYear + range; i++)
         {
            [actionSheet addAction:[UIAlertAction actionWithTitle:[NSString stringWithFormat:@"%d", i] style:UIAlertActionStyleDefault handler:^(UIAlertAction* action)
                                    {
                                       leaveYear= i;
                                       [self.tableView reloadRowsAtIndexPaths:[NSArray arrayWithObject:[self indexPathForOption:rowYear]] withRowAnimation:UITableViewRowAnimationAutomatic];
                                    }]];
         }
         
         [actionSheet addAction:[UIAlertAction actionWithTitle:NSLocalizedString(@"Cancel", nil) style:UIAlertActionStyleCancel handler:nil]];
         [self presentViewController:actionSheet animated:YES completion:nil];
         actionSheet.view.tintColor = MAINCOLORDARK;

         break;
      }
      case rowState:
      {
         status = !status;
         UITableViewCell* cell = [[self tableView] cellForRowAtIndexPath:indexPath];
         
         cell.detailTextLabel.text = [Service titleForStatus:status];
         cell.detailTextLabel.textColor = [Service colorForState:status];
         break;
      }
      case rowLocation:
      {
         LocationController* dvc = [[[LocationController alloc] init] autorelease];
         UINavigationController* nvc= [[[UINavigationController alloc] initWithRootViewController:dvc] autorelease];
         dvc.delegate = self;
         
         [self presentViewController:nvc animated:YES completion:nil];
         
         break;
      }
         
      default:
         break;
   }
   
   if (indexPath.section == 3)
   {
      // delete button
      
      UIAlertController* actionSheet= [UIAlertController alertControllerWithTitle:NSLocalizedString(@"Delete entry", nil) message:NSLocalizedString(@"Are you sure you want to delete this entry?", nil) preferredStyle:UIAlertControllerStyleActionSheet];
      
      [actionSheet addAction:[UIAlertAction actionWithTitle:NSLocalizedString(@"Continue", nil) style:UIAlertActionStyleDestructive handler:^(UIAlertAction* action)
                              {
                                 [self deleteRecord:^(BOOL success)
                                  {
                                     if (!success)
                                        [Service alert:NSLocalizedString(@"Error", nil) withText:NSLocalizedString(@"Failed to save data", nil) andError:nil forController:self completion:nil];
                                     
                                     [self closeDialog];
                                  }];
                              }]];
      
      [actionSheet addAction:[UIAlertAction actionWithTitle:NSLocalizedString(@"Cancel", nil) style:UIAlertActionStyleCancel handler:^(UIAlertAction* action)
                              {
                                 [self.tableView reloadData];
                              }]];
      [self presentViewController:actionSheet animated:YES completion:nil];
      actionSheet.view.tintColor = MAINCOLORDARK;
   }
}

// ************************************************************
// typeForIndex
// ************************************************************

-(int)typeForIndex:(NSIndexPath *)idx
{
   // configure different types for text-cells (decimal, text, etc)
   
   if (isCell(rowTimetable, idx, rowInfos))
       return tpText;
       
   if (isCell(rowDuration, idx, rowInfos))
   {
      // date (from, to, half days)
      // OR: duration (if saved as hours)
      
      if (needsHourInput)
         return tpNumber;
      else
         return  tpDecimal;
   }
   
   return tpText;
}

// ************************************************************
// cityName
// ************************************************************

-(NSString*)cityName
{
   if (!self.location)
      return NSLocalizedString(@" None", nil);
   
   NSArray* alternateNames= [self.location objectForKey:@"alternateNames"];
   
   if (!alternateNames)
      return [self.location objectForKey:@"name"];
   
   NSString* countryCode= [[[NSLocale currentLocale] localeIdentifier] substringToIndex:2];

   for (NSDictionary* dict in alternateNames)
   {
      if ([[dict valueForKey:@"lang"] isEqualToString:countryCode])
         return [dict valueForKey:@"name"];
   }
   
   return [self.location objectForKey:@"name"];
}

#pragma mark - Table view editing

// ************************************************************
// valueChanged
// ************************************************************

-(BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath
{
   if (indexPath.section != 2)
      return NO;
   
   if (indexPath.row == [self tableView:self.tableView numberOfRowsInSection:2]-1)
      return NO;
   
   return YES;
}

// ************************************************************
// valueChanged
// ************************************************************

// ************************************************************
// trailingSwipeActionsConfigurationForRowAtIndexPath
// ************************************************************

- (UISwipeActionsConfiguration *)tableView:(UITableView *)tableView trailingSwipeActionsConfigurationForRowAtIndexPath:(NSIndexPath *)indexPath
{
   UIContextualAction* act = [UIContextualAction contextualActionWithStyle:UIContextualActionStyleDestructive title:NSLocalizedString(@"Remove", nil) handler:^(UIContextualAction* action, UIView *sourceView, void (^completionHandler)(BOOL actionPerformed))
   {
      // show UIActionSheet
      
      int cellIndex= [self optionIndex:indexPath];
      
      enabledOptions[cellIndex-nOptFirst]= 0;
      
      if (cellIndex == rowCategory)
         self.navigationItem.title= NSLocalizedString(@"Leave", nil);
      
      [self removeDataForOption:cellIndex];
      
      [self.tableView reloadData];
      completionHandler(YES);
   }];
   
   return [UISwipeActionsConfiguration configurationWithActions:[NSArray arrayWithObject: act]];
}

// ************************************************************
// valueChanged
// ************************************************************

- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath
{
   // No statement or algorithm is needed in here. Just the implementation
}

#pragma mark UITextField delegate

// ************************************************************
// textFieldShouldBeginEditing
// ************************************************************

-(BOOL)textFieldShouldBeginEditing:(UITextField *)textField
{
   UITableViewCell* v = (UITableViewCell*)[[textField superview] superview];
   
   self.editedIndex = [[self tableView] indexPathForCell:v];
   
   if (self.editedIndex.section == 1)
      durationChanged= false;
   
   activeTextField= textField;
   activeTextView= nil;
   
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
   
   if (isCell(rowDuration, self.editedIndex, rowInfos))
   {
      if (durationChanged && calculateDuration)
      {
         calculateDuration= NO;
         enabledOptions[rowCalc-nOptFirst] = 1;
         
         [self.tableView reloadData];
      }
   }
   
   return YES;
}

#pragma mark TextInputCellDelegate

// ************************************************************
// saveText
// ************************************************************

-(void)saveText:(NSString *)newText  fromTextField:(UITextField*)aTextField
{
   if (isCell(rowTitle, self.editedIndex, rowInfos))
   {
      self.leaveTitle = newText;
   }
   else if (isCell(rowDuration, self.editedIndex, rowInfos))
   {
      durationChanged= true;
      
      if (needsHourInput)
         duration = [[[Service numberFormatter] numberFromString:newText] doubleValue];
      else
         duration = [[[Service numberFormatter] numberFromString:newText] doubleValue];
   }
}

#pragma mark UITextView delegate

// ************************************************************
// textViewDidChange
// ************************************************************

-(void)textViewDidBeginEditing:(UITextView *)textView
{
   activeTextField= nil;
   activeTextView= textView;
}

- (void)textViewDidChange:(UITextView *)aTextView 
{
   self.comment = aTextView.text;
}

// ************************************************************
// setNewCategoryName
// ************************************************************

-(void) setNewCategory:(CategoryRef*)category
{
   if (category)
   {
      self.categoryName = category.name;
      self.navigationItem.title = category.name;
      
      if ([category.savedAsHours boolValue])
      {
         if (!self.timeTables)
            self.timeTables= [NSMutableArray arrayWithObject:[[[Storage currentStorage] userWithUUid:self.owner].timetables firstObject]];
         
         beginHalfDay= false;
         endHalfDay= false;
      }
      else
         needsHourInput= NO;
   }
   else
   {
      self.leaveMode= 0;
      self.categoryName = nil;
      self.navigationItem.title = NSLocalizedString(@"Leave", nil);
   }

   [self.tableView reloadData];
}

-(void)setNewCategories:(NSMutableArray*)categories { }

#pragma mark - UISegmentedControl
// ************************************************************
// setLeaveMode
// ************************************************************

-(void)leaveModeChanged:(id)sender
{
   UISegmentedControl* seg = sender;
   
   self.leaveMode = (int)seg.selectedSegmentIndex;
   
   [self.tableView reloadData];
}

#pragma mark - ILGeoNamesSearchControllerDelegate

// ************************************************************
// geoNamesUserIDForSearchController
// ************************************************************

- (NSString*)geoNamesUserIDForSearchController:(LocationController*)controller
{
   return @"annualleave";
}

// ************************************************************
// geoNamesSearchController
// ************************************************************

- (void)geoNamesSearchController:(LocationController*)controller didFinishWithResult:(NSDictionary*)result
{
   self.location= result;
   
   [self.tableView reloadRowsAtIndexPaths:[NSArray arrayWithObject:[self indexPathForOption:rowLocation]] withRowAnimation:UITableViewRowAnimationNone];
}

// ************************************************************
// geoNamesLookup
// ************************************************************

-(void)geoNamesLookup:(ILGeoNamesLookup *)handler didFailWithError:(NSError *)error
{
   NSLog(@"Geo-lookup has failed: %@", [error localizedDescription]);
}

#pragma mark - data storage

// ************************************************************
// fill
// ************************************************************

-(void)fill 
{
   self.completionHandler= nil;
   
   sendMail= false;
   durationChanged= false;
   
   if (self.leaveInfo)
   {
      if (self.leaveInfo.__version == 1)
         [self migrateEntry:self.leaveInfo];

      [self loadRecord];
      initial= false;
      leaveYear= [self.leaveInfo.year intValue];
   }
   else 
   {
      User* ownerUser = [[Storage currentStorage] userWithUUid:self.owner];
      NSArray* userTTs = ownerUser && ownerUser.timetables ? ownerUser.timetables : nil;
      
      self.location= nil;
      self.timeTables= userTTs && userTTs.count ? [NSMutableArray arrayWithObject:[userTTs firstObject]] : nil;
      duration = 0.0;
      beginHalfDay = NO;
      endHalfDay = NO;
      calculateDuration= YES;
      editBegin = NO;
      self.beginDate= [Service trunc:[NSDate date]];
      self.endDate= [Service trunc:[NSDate date]];
      self.leaveTitle = nil;
      self.comment = nil;
      self.categoryName = nil;
      status = [Settings userSettingInt:skDefaultState];
      leaveYear= [Service getLeaveYearForDate:self.beginDate];
      isUnknownDate= false;
      self.leaveMode = lmSpend;

      NSData* lastOptions = [Settings userSettingObject:skLastLeaveOptions];
      
      if (lastOptions && lastOptions.length)
         [lastOptions getBytes:enabledOptions length:sizeof(enabledOptions)];
      
      Pool* pool= [Storage poolOfArray:[SessionManager currentYear].pools withInternalName:@"residualleave"];
      
      if (pool && [pool.remain doubleValue] > 0.0)
      {
         self.categoryName= pool.category;
         enabledOptions[rowCategory-nOptFirst] = 1;
      }

      [[self tableView] reloadData];
      
      initial= true;
   }
}

// ************************************************************
// loadRecord
// ************************************************************

-(bool) loadRecord
{
   self.beginDate = self.leaveInfo.begin;
   self.endDate = self.leaveInfo.end;
   self.leaveTitle = self.leaveInfo.title;
   self.comment = self.leaveInfo.comment;
   self.categoryName = self.leaveInfo.category;
   beginHalfDay = [self.leaveInfo.begin_half_day boolValue];
   endHalfDay = [self.leaveInfo.end_half_day boolValue];
   duration = [self.leaveInfo.duration doubleValue];
   status = [self.leaveInfo.status intValue];
   leaveYear= [self.leaveInfo.year intValue];
   isUnknownDate= [self.leaveInfo.isUnknownDate boolValue];
   calculateDuration= [self.leaveInfo.calculateDuration boolValue];
   self.owner= self.leaveInfo.userid;
   self.location= self.leaveInfo.location;
   self.leaveMode = self.leaveInfo.mode.intValue;
   
   // fetch timetable
   
   NSArray* uuids= [self.leaveInfo.timeTable componentsSeparatedByString:@","];
   NSString* uuid= nil;
   Timetable* tt= nil;
   
   self.timeTables= nil;
   self.timeTables= [[[NSMutableArray alloc] initWithCapacity:uuids.count] autorelease];
   
   for (int i= 0; i < uuids.count; i++)
   {
      uuid= [uuids objectAtIndex:i];
      
      tt= [Storage getTimeTable:uuid];
      
      if (tt)
         [self.timeTables addObject:tt];
   }
   
   if (!self.timeTables.count)
   {
      User* ownerUser = [[Storage currentStorage] userWithUUid:self.owner];
      
      if (ownerUser.timetables && ownerUser.timetables.count)
         [self.timeTables addObject:[ownerUser.timetables firstObject]];
   }
   
   CategoryRef* c= [Storage categoryForName:self.categoryName ofUser:[[Storage currentStorage] userWithUUid:self.owner]];
   
   needsHourInput= c && [c.savedAsHours boolValue];

   if (self.leaveInfo.options && self.leaveInfo.options.length)
      [self.leaveInfo.options getBytes:enabledOptions length:sizeof(enabledOptions)];

   if (c)
   {
      self.categoryName= c.name;
      enabledOptions[rowCategory-nOptFirst] = 1;
   }
   
   if (!status)
      enabledOptions[rowState-nOptFirst] = 1;
   
   return YES;
}

// ************************************************************
// setValues
// ************************************************************

-(void) setValues 
{
   self.leaveInfo.begin = self.beginDate;
   self.leaveInfo.end = self.endDate;
   self.leaveInfo.title = self.leaveTitle;
   self.leaveInfo.comment = self.comment;
   self.leaveInfo.begin_half_day = [NSNumber numberWithBool:beginHalfDay];
   self.leaveInfo.end_half_day = [NSNumber numberWithBool:endHalfDay];
   self.leaveInfo.duration = [NSNumber numberWithDouble:duration];
   self.leaveInfo.year = [NSNumber numberWithInt:leaveYear];
   self.leaveInfo.month= [NSNumber numberWithInt:(int)[[NSCalendar currentCalendar] components:NSCalendarUnitMonth fromDate:self.beginDate].month];
   self.leaveInfo.status = [NSNumber numberWithInt:status];
   self.leaveInfo.userid = self.owner;
   self.leaveInfo.isUnknownDate = [NSNumber numberWithBool:isUnknownDate];
   self.leaveInfo.location= self.location;
   self.leaveInfo.timeTable= [Service stringFromUUIDsForTimeTables:self.timeTables];
   self.leaveInfo.calculateDuration= [NSNumber numberWithBool:calculateDuration];
   self.leaveInfo.category = self.categoryName;
   self.leaveInfo.mode = [NSNumber numberWithInt:self.leaveMode];
   
   CategoryRef* c= [Storage categoryForName:self.categoryName ofUser:[[Storage currentStorage] userWithUUid:self.owner]];
   
   if (c)
   {
      self.leaveInfo.affectsCalculation = c.affectCalculation;
      self.leaveInfo.sumMonthly = c.sumMonthly;
   }
   else
   {
      self.leaveInfo.affectsCalculation = [NSNumber numberWithDouble:1.0];
      self.leaveInfo.sumMonthly = [NSNumber numberWithDouble:0.0];
   }

   self.leaveInfo.savedAsHours = [NSNumber numberWithBool:needsHourInput];
   self.leaveInfo.options= [NSData dataWithBytes:enabledOptions length:sizeof(enabledOptions)];

   [Settings setUserSettingUnsaved:skLastLeaveOptions withObject:self.leaveInfo.options];
}

#pragma mark - cancel

// ************************************************************
// cancel
// ************************************************************

-(void) cancel
{
   [self closeDialog];
}

#pragma mark - Generic dialog close

// ************************************************************
// close dialog
// ************************************************************

-(void)closeDialog
{
   [self dismissViewControllerAnimated:YES completion:^(void)
    {
       if (self.completionHandler)
          self.completionHandler();
       
       self.leaveInfo= nil;
    }];
}

#pragma mark -
#pragma mark save a record

// ************************************************************
// saveRecord
// ************************************************************

-(void)saveRecord
{
   // new? create new document
   // exists? delete from calendard (+ insert again = update)

   if (!self.leaveInfo)
      self.leaveInfo= [[Storage currentStorage] createLeaveForOwnerUUID:self.owner];
   else
      [Storage deleteLeaveFromCalendar:self.leaveInfo];
   
   int oldLeaveYear = self.leaveInfo.year.intValue;
   
   [self setValues];
   
   [Storage saveLeaveInCalendar:self.leaveInfo];
   
   void (^_done)(BOOL) = ^(BOOL success)
   {
      if (!success)
         [Service alert:NSLocalizedString(@"Error", nil) withText:NSLocalizedString(@"Failed to save data", nil) andError:nil forController:self completion:nil];
      else
      {
         if (sendMail)
            [self sendMailWithInfo:self.leaveInfo];
         else
            [self closeDialog];
      }
   };
   
   [Storage saveLeave:self.leaveInfo completion:^(BOOL success)
    {
       if (success && oldLeaveYear != self.leaveInfo.year.intValue)
          [Calculation recalculateYear:oldLeaveYear withLastYearRemain:0.0 setRemain:false completion:_done];
       else
          _done(success);
    }];
}

// ************************************************************
// deleteRecord
// ************************************************************

-(void)deleteRecord:(void (^)(BOOL success))aCompletionHandler
{
   [[Storage currentStorage] deleteLeave:self.leaveInfo completion:^(BOOL success)
    {
       // delete event from calendar
       
       if (aCompletionHandler)
          aCompletionHandler(success);
    }];
}

#pragma mark -
#pragma mark calculation

// ************************************************************
// recalculate
// ************************************************************

- (void)recalculate
{
   if (!calculateDuration)
      return;
   
   double oldDuration= duration;
   
   CategoryRef* c= [Storage categoryForName:self.categoryName ofUser:[[Storage currentStorage] userWithUUid:self.owner]];
   
   if (c)
      needsHourInput= [c.savedAsHours boolValue];
   else
      needsHourInput= [Settings userSettingInt:skUnit];
   
   bool honorFreeDays= c ? [c.honorFreeDays boolValue] : YES;

   if (!isUnknownDate)
   {
      duration= [Calculation calculateLeaveDuration:self.beginDate 
                                                _in:self.endDate
                                                _in:beginHalfDay
                                                _in:endHalfDay
                                                _in:(bool)needsHourInput
                                                _in:(bool)honorFreeDays
                                                _in:self.timeTables
                                                _in:na
                                                _in:na];
   }

   if (oldDuration != duration)
      [self.tableView reloadData];
}

#pragma mark - Versioning
// ************************************************************
// migrateEntry
// ************************************************************

-(void)migrateEntry:(LeaveInfo*)info
{
   NSLog(@"Migrating info from version %d", info.__version);
   
   if (info.__version == 1)
   {
      // migrate options from version 1 to version 2 here
      
      if (info.options.length < cntRows)
         return;
      
      int* leaveOpts= (int*)info.options.bytes;
      int newOptions[cntRows];
      memset(newOptions, 0, sizeof(newOptions));
      
      for (int i = nSectSec; i < cntRows; i++)
      {
         if (leaveOpts[i] && (i-nSectSec >= 0) && (i-nSectSec < cntRows-nOptFirst))
            newOptions[i-nSectSec] = 1;
      }

      info.options = [NSData dataWithBytes:newOptions length:sizeof(newOptions)];
   }
}

#pragma mark -utility
// ************************************************************
// sendMailWithInfo
// ************************************************************

-(void)sendMailWithInfo:(LeaveInfo*)info
{
   MFMailComposeViewController* picker = [[MFMailComposeViewController alloc] init];
   
   if (![MFMailComposeViewController canSendMail] || picker == nil)
   {
      [Service message:NSLocalizedString(@"Can't send mail", nil) withText:NSLocalizedString(@"Can't send mails because this device is not configured to send mails.", nil) forController:nil completion:nil];
      [picker release];
      return;
   }
   
   picker.mailComposeDelegate = self;  
   picker.navigationBar.barStyle = UIBarStyleDefault;
   
//   [picker.navigationBar setBarTintColor:MAINCOLORDARK];
//   [picker.navigationBar setTintColor:LIGHTTEXTCOLOR];
//   [picker.navigationBar setTitleTextAttributes:@{NSForegroundColorAttributeName : LIGHTTEXTCOLOR}];
   
   NSString* beginString = [[Service dateFormatter] stringFromDate:info.begin];
   NSString* endString = [[Service dateFormatter] stringFromDate:info.end];
   NSString* durationString = [Service niceDuration:[info.duration doubleValue] withCategory:[Storage categoryForName:self.categoryName ofUser:[[Storage currentStorage] userWithUUid:self.owner]]];
   
   if ([info.begin_half_day boolValue])
      beginString = [NSString stringWithFormat:@"%@ (%@)", beginString, NSLocalizedString(@"half day", nil)];
   
   if ([info.end_half_day boolValue])
      endString = [NSString stringWithFormat:@"%@ (%@)", endString, NSLocalizedString(@"half day", nil)];
   
   NSString* subject= nil;
   
   if ([[Settings userSettingObject:skMailSubject] length])
   {
      subject = [[Settings userSettingObject:skMailSubject] stringByReplacingOccurrencesOfString:@"$begin" withString:beginString];
      subject = [subject stringByReplacingOccurrencesOfString:@"$end" withString:endString];
      subject = [subject stringByReplacingOccurrencesOfString:@"$duration" withString:durationString];
      
      if ([info.title length])
         subject = [subject stringByReplacingOccurrencesOfString:@"$title" withString:info.title];
      
      if ([info.comment length])
         subject = [subject stringByReplacingOccurrencesOfString:@"$comment" withString:info.comment];
   }
   
   NSString* body= nil;
   
   if ([[Settings userSettingObject:skMailBody] length])
   {
      body = [[Settings userSettingObject:skMailBody] stringByReplacingOccurrencesOfString:@"$begin" withString:beginString];
      body = [body stringByReplacingOccurrencesOfString:@"$end" withString:endString];
      body = [body stringByReplacingOccurrencesOfString:@"$duration" withString:durationString];
      
      if ([info.title length])
         body = [body stringByReplacingOccurrencesOfString:@"$title" withString:info.title];
      
      if ([info.comment length])      
         body = [body stringByReplacingOccurrencesOfString:@"$comment" withString:info.comment];
   }
   
   if ([[Settings userSettingObject:skMailTo] length])
      [picker setToRecipients:[[Settings userSettingObject:skMailTo] componentsSeparatedByString:@","]];
   
   if ([[Settings userSettingObject:skMailCc] length])
      [picker setCcRecipients:[[Settings userSettingObject:skMailCc] componentsSeparatedByString:@","]];
   
   if ([[Settings userSettingObject:skMailBcc] length])
      [picker setBccRecipients:[[Settings userSettingObject:skMailBcc] componentsSeparatedByString:@","]];
   
   [picker setSubject:subject];
   [picker setMessageBody:body isHTML:NO];
   
   picker.modalTransitionStyle= UIModalPresentationNone;
   
   [self presentViewController:picker animated:YES completion:^{}];
   [picker release];
}

// ************************************************************
// mailComposeController didFinishWithResult
// ************************************************************

- (void)mailComposeController:(MFMailComposeViewController*)controller didFinishWithResult:(MFMailComposeResult)result error:(NSError*)error
{ 
   switch (result)
   {
      case MFMailComposeResultCancelled: break;
      case MFMailComposeResultSaved:     break;
      case MFMailComposeResultSent:      break;
         
      case MFMailComposeResultFailed:
      default:
      {
         [Service alert:NSLocalizedString(@"Error", nil) withText:nil andError:error forController:self completion:nil];
         break;
      }
   }
   
   [self dismissViewControllerAnimated:YES completion:^{
      [self closeDialog];
   }];
}

@end
