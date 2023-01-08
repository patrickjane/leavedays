//************************************************************
// BasePage.h
// Holliday
//************************************************************
// Created by Patrick Fial on 25.01.15.
// Copyright 2015-2015 Patrick Fial. All rights reserved.
//************************************************************

//************************************************************
// includes
//************************************************************

#import <UIKit/UIKit.h>

//************************************************************
// class BasePage
//************************************************************

@interface BasePage : UIViewController
{
   UIBarButtonItem *spacer, *menuItem, *addItem, *titleItem;
}

@property (nonatomic, retain) IBOutlet UIToolbar* toolbar;

-(void)update;
-(NSString*)pageTitle;

-(IBAction)menuButton:(id)sender;
-(IBAction)addButton:(id)sender;

@end
