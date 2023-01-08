//************************************************************
// CategoryOverviewController.h
// Annual Leave iPad
//************************************************************
// Created by Patrick Fial on 24.02.2011
// Copyright 2011-2012 Patrick Fial. All rights reserved.
//************************************************************

//************************************************************
// includes
//************************************************************

#import <UIKit/UIKit.h>
#import <CoreData/CoreData.h>
#import "CategoryEdit.h"

@class CategoryCell;

enum CatMode
{
   tpEdit,
   tpSelect,
   tpSelectPool,
   tpMultiSelect,
   tpSelectDark
};

enum CGColorSpaceMode
{
   mdDark,
   mdLight
};

//************************************************************
// protocol CategoryOverviewControllerDelegate
//************************************************************

@protocol CategoryOverviewControllerDelegate <NSObject>
@required
- (void)setNewCategory:(CategoryRef*)category;
-(void)setNewCategories:(NSMutableArray*)categories;
@end

//************************************************************
// class CategoryOverviewController
//************************************************************

@interface CategoryOverviewController : UITableViewController
{
}

@property (nonatomic, retain) NSArray* items;
@property (nonatomic, assign) int mode;
@property (nonatomic, assign) int colorMode;
@property (nonatomic, retain) CategoryRef* categorySelection;
@property (nonatomic, retain) id<CategoryOverviewControllerDelegate> delegate;
@property (nonatomic, retain) NSIndexPath* lastSelection;
@property (nonatomic, retain) NSMutableArray* categoryMultiSelection;
@property (nonatomic, retain) NSString* chartPNG;
@property (nonatomic, retain) NSString* sumPNG;

-(void) configureCell:(CategoryCell*)cell atIndexPath:(NSIndexPath*)indexPath;
-(void) addCategory;

@end
