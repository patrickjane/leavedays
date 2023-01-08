//************************************************************
// LocationController.m
// Holiday
//************************************************************
// Created by Patrick Fial on 01.01.2015
// Copyright 2015-2015 Patrick Fial. All rights reserved.
//************************************************************

//************************************************************
// includes
//************************************************************

#import "LocationController.h"

//************************************************************
// class LocationController
//************************************************************

@implementation LocationController

@synthesize searchResults;
@synthesize delegate;
@synthesize geoNamesSearch;
@synthesize searchController;

#pragma mark - View lifecycle

//************************************************************
// init
//************************************************************

- (id)init
{
   self = [super initWithStyle:UITableViewStylePlain];
   
   if (self)
   {
      self.searchResults= [NSMutableArray array];
   }
   
   return self;
}

//************************************************************
// dealloc
//************************************************************

-(void)dealloc
{
   self.geoNamesSearch.delegate = nil;
   self.geoNamesSearch= nil;
   self.searchResults= nil;
   [super dealloc];
}

//************************************************************
// viewDidLoad
//************************************************************

- (void)viewDidLoad
{
   [super viewDidLoad];
   
   if (!geoNamesSearch)
   {
      NSString* userID = [self.delegate geoNamesUserIDForSearchController:self];
      self.geoNamesSearch= [[ILGeoNamesLookup alloc] initWithUserID:userID];
      [self.geoNamesSearch release];
   }
   
   self.geoNamesSearch.delegate = self;
   
   self.searchController = [[UISearchController alloc] initWithSearchResultsController:nil];
   self.searchController.searchResultsUpdater = self;
   [self.searchController.searchBar sizeToFit];
   self.tableView.tableHeaderView = self.searchController.searchBar;
   
   self.searchController.obscuresBackgroundDuringPresentation = NO; // default is YES
   self.searchController.searchBar.delegate = self; // so we can monitor text changes + others
   
   self.definesPresentationContext = YES;  // know where you want UISearchController to be displayed
   self.navigationItem.title= NSLocalizedString(@"Search location", nil);
   self.navigationItem.leftBarButtonItem= [[[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemCancel target:self action:@selector(dismiss)] autorelease];
}

#pragma mark - Interaction

//************************************************************
// dismiss
//************************************************************

-(void)dismiss
{
   [self dismissViewControllerAnimated:YES completion:nil];
}

//************************************************************
// dismiss
//************************************************************

-(void)delayedSearch:(NSString*)searchString
{
   [self.geoNamesSearch cancel];
   [self.geoNamesSearch search:searchString maxRows:20 startRow:0 language:nil];
}

#pragma mark - Delegates
#pragma mark - Table view data source

//************************************************************
// numberOfSectionsInTableView
//************************************************************

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
   return 1;
}

//************************************************************
// numberOfRowsInSection
//************************************************************

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
   return self.searchResults.count;
}

//************************************************************
// cellForRowAtIndexPath
//************************************************************

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
   static NSString *CellIdentifier = @"Cell";
   
   UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
   
   if (cell == nil)
      cell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:CellIdentifier] autorelease];
   
   // Configure the cell...
   
   NSDictionary* geoname = [self.searchResults objectAtIndex:indexPath.row];
   
   if (geoname)
   {
      NSString	*name = [geoname objectForKey:kILGeoNamesNameKey];
      cell.textLabel.text = name;
      NSString	*subString = [geoname objectForKey:kILGeoNamesCountryNameKey];
      
      if(subString && ![subString isEqualToString:@""])
      {
         NSString	*admin1 = [geoname objectForKey:kILGeoNamesAdminName1Key];
         
         if (admin1 && ![admin1 isEqualToString:@""])
         {
            subString = [admin1 stringByAppendingFormat:@", %@", subString];
            NSString *admin2 = [geoname objectForKey:kILGeoNamesAdminName2Key];
            
            if(admin2 && ![admin2 isEqualToString:@""])
               subString = [admin2 stringByAppendingFormat:@", %@", subString];
         }
      }
      else
         subString = [geoname objectForKey:kILGeoNamesFeatureClassNameKey];
      
      cell.detailTextLabel.text = subString;
      cell.accessibilityLabel = [NSString stringWithFormat:@"%@, %@", name, subString];
   }
   
   return cell;
}

#pragma mark - Table view delegate

//************************************************************
// didSelectRowAtIndexPath
//************************************************************

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
   [NSObject cancelPreviousPerformRequestsWithTarget:self];
   [self.geoNamesSearch cancel];
   self.geoNamesSearch.delegate = nil;
   
   if (indexPath.row < self.searchResults.count-1)
      [self.delegate geoNamesSearchController:self didFinishWithResult:[self.searchResults objectAtIndex:indexPath.row]];
   
   [self dismissViewControllerAnimated:NO completion:^(void)
    {
       [self dismiss];
    }];
}

#pragma mark - Search bar delegate

//************************************************************
// searchBarCancelButtonClicked
//************************************************************

- (void)searchBarCancelButtonClicked:(UISearchBar *) searchBar
{
   [NSObject cancelPreviousPerformRequestsWithTarget:self];
   [self.geoNamesSearch cancel];
   self.geoNamesSearch.delegate = nil;
   
   [self.searchResults removeAllObjects];
   [self.tableView reloadData];
   
   if (self.delegate)
      [self.delegate geoNamesSearchController:self didFinishWithResult:nil];
}

//************************************************************
// updateSearchResultsForSearchController
//************************************************************

-(void)updateSearchResultsForSearchController:(UISearchController *)_searchController
{
   [self.searchResults removeAllObjects];
   
   [NSObject cancelPreviousPerformRequestsWithTarget:self];
   
   [self performSelector:@selector(delayedSearch:) withObject:_searchController.searchBar.text afterDelay:1.0];
}

#pragma mark - ILGeoNamesLookupDelegate

//************************************************************
// didFindGeoNames
//************************************************************

- (void)geoNamesLookup:(ILGeoNamesLookup *)handler didFindGeoNames:(NSArray *)geoNames totalFound:(NSUInteger)total
{
//   NSLog(@"didFindPlaceName: %@", geoNames);
   
   // Grab the results
   if ([geoNames count])
      [self.searchResults setArray:geoNames];
   else
      [self.searchResults removeAllObjects];
   
   [self.tableView reloadData];
}

//************************************************************
// didFailWithError
//************************************************************

- (void)geoNamesLookup:(ILGeoNamesLookup *)handler didFailWithError:(NSError *)error
{
   if (self.delegate)
      [self.delegate geoNamesLookup:handler didFailWithError:error];
}

@end

