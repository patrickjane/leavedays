//************************************************************
// LocationController.h
// Holiday
//************************************************************
// Created by Patrick Fial on 01.01.2015
// Copyright 2015-2015 Patrick Fial. All rights reserved.
//************************************************************

//************************************************************
// includes
//************************************************************

#import <UIKit/UIKit.h>
#import "ILGeoNamesLookup.h"

@class LocationController;

//************************************************************
// protocol ILGeoNamesSearchControllerDelegate
//************************************************************

@protocol LocationControllerDelegate

@required
/** Called by the search controller to obtain the user ID for use in the search query
 
 The delegate must return a string containing a valid user ID obtained from geonames.org.
 @param controller The search controller.
 @return The user ID.
 */
- (NSString*)geoNamesUserIDForSearchController:(LocationController*)controller;

/** Called by the search controller when the user taps a search result or cancels the search.
 
 When this method is called the geolocation selected by the user will be contained in _result_.
 If the user taps the "Cancel" button the _result_ will be `nil`.
 @param controller The search controller.
 @param result The result of the user action.
 */
- (void)geoNamesSearchController:(LocationController*)controller didFinishWithResult:(NSDictionary*)result;

@optional
- (void)geoNamesLookup:(ILGeoNamesLookup*)handler didFailWithError:(NSError *)error;

@end

//************************************************************
// class LocationController
//************************************************************

@interface LocationController : UITableViewController <UISearchResultsUpdating, UISearchBarDelegate, ILGeoNamesLookupDelegate>
{
@private
	id <LocationControllerDelegate> delegate;
	NSMutableArray	*searchResults;
	ILGeoNamesLookup	*geoNamesSearch;
}

@property(nonatomic, assign) id <LocationControllerDelegate> delegate;
@property (nonatomic, retain) UISearchController* searchController;

@property BOOL searchControllerWasActive;
@property BOOL searchControllerSearchFieldWasFirstResponder;

@property (nonatomic, retain) NSMutableArray *searchResults;
@property (nonatomic, retain) ILGeoNamesLookup* geoNamesSearch;

-(void)delayedSearch:(NSString*)searchString;

@end
