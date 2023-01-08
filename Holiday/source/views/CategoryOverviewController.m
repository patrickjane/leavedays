//************************************************************
// CategoryOverviewController.m
// Annual Leave iPad
//************************************************************
// Created by Patrick Fial on 24.02.2011
// Copyright 2011-2012 Patrick Fial. All rights reserved.
//************************************************************

//************************************************************
// includes
//************************************************************

#import "CategoryOverviewController.h"
#import "Category.h"
#import "CategoryCell.h"
#import "Service.h"
#import "Settings.h"
#import "Storage.h"
#import "SessionManager.h"
#import "User.h"

@implementation CategoryOverviewController

@synthesize mode;
@synthesize categorySelection;
@synthesize delegate;
@synthesize lastSelection;
@synthesize categoryMultiSelection, chartPNG, sumPNG, colorMode;

#pragma mark - Lifecycle

// ************************************************************
// initWithStyle
// ************************************************************

- (id)initWithStyle:(UITableViewStyle)style 
{
   if ((self = [super initWithStyle:UITableViewStyleGrouped])) 
   {
      self.items= [SessionManager activeUser].categories;
      self.mode = tpEdit;
      self.colorMode = mdLight;
      self.categorySelection = nil;
      self.delegate = nil;
      self.lastSelection = nil;
      self.categoryMultiSelection= [[[NSMutableArray alloc] init] autorelease];
   }
   
   return self;
}

// ************************************************************
// dealloc
// ************************************************************

- (void)dealloc
{
   self.items= nil;
   self.categorySelection = nil;
   self.lastSelection = nil;
   self.categoryMultiSelection= nil;
   
   [super dealloc];
}

// ************************************************************
// viewDidLoad
// ************************************************************

- (void)viewDidLoad 
{
   [super viewDidLoad];

   if (mode == tpEdit || colorMode == mdDark)
   {
      self.tableView.backgroundColor= DARKTABLEBACKCOLOR;
      self.tableView.separatorColor= DARKTABLESEPARATORCOLOR;
      chartPNG = @"chart_w.png";
      sumPNG = @"sum_w.png";
   }
   else
   {
      chartPNG = @"chart.png";
      sumPNG = @"sum.png";
   }
   
   self.navigationItem.title = NSLocalizedString(@"Categories", nil);
}

// ************************************************************
// viewWillAppear
// ************************************************************

- (void) viewWillAppear:(BOOL)animated 
{
   if (self.mode == tpEdit)
   {
      // add/edit/remove categories
      
      UIBarButtonItem *addButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem: UIBarButtonSystemItemAdd target: self action: @selector(addCategory)];
      self.navigationItem.rightBarButtonItem = addButton;
      [addButton release];
      self.categorySelection = nil;
   }
   else if (self.mode != tpSelectPool && self.mode != tpMultiSelect)
   {
      // select categories only
      
      UIBarButtonItem* saveButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemSave target:self action:@selector(saveSelection)];
      self.navigationItem.rightBarButtonItem = saveButton;
      [saveButton release];
   }
   
   // need to force updates because in select/edit mode
   // cells have different behaviour
   
   [[self tableView] reloadData];
}

// ************************************************************
// viewWillDisappear
// ************************************************************

-(void) viewDidDisappear:(BOOL)animated 
{
   if (mode == tpEdit)
      [self.tableView deselectRowAtIndexPath:[self.tableView indexPathForSelectedRow] animated:NO];
}

#pragma mark -
#pragma mark interaction

// ************************************************************
// addCategory
// ************************************************************

-(void) addCategory 
{
   CategoryEdit* dvc= [[[CategoryEdit alloc] init] autorelease];

   [dvc fill:nil];
   
   [self.navigationController pushViewController:dvc animated:YES];
}

// ************************************************************
// saveSelection
// ************************************************************

-(void) saveSelection 
{
   if (self.delegate)
      [self.delegate setNewCategory:self.categorySelection];
   
   [[self navigationController] popViewControllerAnimated:YES];
}

#pragma mark -
#pragma mark Table view data source

// ************************************************************
// numberOfSectionsInTableView
// ************************************************************

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView 
{
   return mode == tpSelect ? 2 : 1;
}

// ************************************************************
// numberOfRowsInSection
// ************************************************************

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
   if (section == 1)
      return 1;
   
   return self.items.count;
}

// ************************************************************
// titleForHeaderInSection
// ************************************************************

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section 
{
   if (section == 0)
      return NSLocalizedString(@"Categories", nil);
   
   return nil;
}

// ************************************************************
// titleForHeaderInSection
// ************************************************************

- (NSString *)tableView:(UITableView *)tableView titleForFooterInSection:(NSInteger)section
{
   if (mode == tpSelect)
      return nil;
   
   return NSLocalizedString(@"When editing leave, you can set a category, which will affect how the leave is calculated and/or displayed.", nil);
}

// ************************************************************
// cellForRowAtIndexPath
// ************************************************************

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
   if (indexPath.section == 0)
   {
      CategoryCell* cell= (CategoryCell*)[tableView dequeueReusableCellWithIdentifier:@"CategoryCell"];
      CategoryRef* info = (CategoryRef*)[self.items objectAtIndex:indexPath.row];
      
      if (cell == nil)
      {
         NSArray* nibContents = [[NSBundle mainBundle] loadNibNamed:@"CategoryCell" owner:self options:nil];
         cell = [nibContents lastObject];
         cell.mainText.textColor = [Service colorString:info.color];
         
         if (mode == tpEdit || colorMode == mdDark)
         {
            cell.backgroundColor= DARKTABLEBACKCOLOR;
         
            if ([Service isStringColor:info.color of:0.0 and:0.0 and:0.0])
               cell.mainText.textColor= DARKTABLETEXTCOLOR;
            
            cell.textReadOnly.textColor= DARKTABLETEXTCOLOR;
         }
      }
      
      // Configure the cell...
      
      [self configureCell:cell atIndexPath:indexPath];
      
      if (mode == tpMultiSelect)
      {
         cell.selectionStyle= UITableViewCellSelectionStyleNone;
         
         if (self.categoryMultiSelection && [self.categoryMultiSelection containsObject:info])
            cell.accessoryType= UITableViewCellAccessoryCheckmark;
         else
            cell.accessoryType= UITableViewCellAccessoryNone;
      }
      else if (mode != tpEdit && self.categorySelection && [self.categorySelection.name isEqualToString:info.name])
      {
         self.lastSelection = indexPath;
         [tableView selectRowAtIndexPath:indexPath animated:NO scrollPosition:UITableViewScrollPositionNone];
         [self.navigationItem.rightBarButtonItem setEnabled:true];
      }
      
      return cell;
   }
   
   // none-section
   
   UITableViewCell* normalCell= nil;
   
   normalCell= [tableView dequeueReusableCellWithIdentifier:@"normalCell"];
   
   if (normalCell == nil)
      normalCell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleValue1 reuseIdentifier:@"normalCell"] autorelease];
   
   if (mode == tpSelect && !self.categorySelection)
      [tableView selectRowAtIndexPath:indexPath animated:NO scrollPosition:UITableViewScrollPositionNone];
   
   normalCell.textLabel.text= NSLocalizedString(@"None", nil);
   
   return normalCell;
}

// ************************************************************
// configureCell
// ************************************************************

-(void) configureCell:(CategoryCell*)cell atIndexPath:(NSIndexPath*)indexPath 
{
   CategoryRef* info = (CategoryRef*)[self.items objectAtIndex:indexPath.row];

   cell.firstImage.image = nil;
   cell.secondImage.image = nil;

   cell.mainText.text = info.name;
   cell.textReadOnly.text= nil;
}

#pragma -
#pragma interaction

// ************************************************************
// didSelectRowAtIndexPath
// ************************************************************

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath 
{
   CategoryRef* cat= nil;
   
   if (indexPath.section == 1)
   {
      // NONE selected
      
      ;
   }
   else
      cat= [self.items objectAtIndex:indexPath.row];
   
   if (mode == tpSelectPool)
   {
      if (self.delegate)
         [self.delegate setNewCategory:cat];

      if (self.navigationController)
         [self.navigationController popViewControllerAnimated:YES];
   }
   
   else if (mode == tpMultiSelect)
   {
      UITableViewCell* cell= [self.tableView cellForRowAtIndexPath:indexPath];
      
      if ([self.categoryMultiSelection containsObject:cat])
      {
         [self.categoryMultiSelection removeObject:cat];
         cell.accessoryType= UITableViewCellAccessoryNone;
      }
      else
      {
         [self.categoryMultiSelection addObject:cat];
         cell.accessoryType= UITableViewCellAccessoryCheckmark;
      }
      
      if (self.delegate)
         [self.delegate setNewCategories:self.categoryMultiSelection];
   }
   
   else if (mode != tpEdit)
   {
      // select/deselect category

      if (self.lastSelection && self.lastSelection.row == indexPath.row && self.lastSelection.section == indexPath.section)
      {
         self.categorySelection = nil;
      }
      else
      {
         self.categorySelection = cat;
      }
      
      if (self.delegate)
         [self.delegate setNewCategory:self.categorySelection];

      if (self.navigationController)
         [self.navigationController popViewControllerAnimated:YES];
   }
   else
   {
      // edit category
      
      CategoryEdit* dvc= [[[CategoryEdit alloc] init] autorelease];
      
      [dvc fill:cat];
      
      [self.navigationController pushViewController:dvc animated:YES];
   }
}


@end

