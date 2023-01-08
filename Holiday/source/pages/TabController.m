//************************************************************
// TabController.m
// Holliday
//************************************************************
// Created by Patrick Fial on 27.12.14.
// Copyright 2014-2015 Patrick Fial. All rights reserved.
//************************************************************

//************************************************************
// includes
//************************************************************

#import "TabController.h"
#import "JASidePanelController.h"
#import "BasePage.h"

//************************************************************
// class TabController
//************************************************************

@implementation TabController

#pragma mark - Lifecycle

//************************************************************
// includes
//************************************************************

-(id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
   self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
   
   if (self)
   {
      // stuff
      
      self.delegate= self;
   }
   
   return self;
}

-(UIStatusBarStyle)preferredStatusBarStyle{
   return UIStatusBarStyleLightContent;
}

//************************************************************
// dealloc
//************************************************************

-(void)dealloc
{
   [super dealloc];
}

#pragma mark - Menu

//************************************************************
// handleShowMenu
//************************************************************

-(void)handleShowMenu
{
   JASidePanelController* side= (JASidePanelController*)self.parentViewController;
   
   if (side.centerPanelHidden)
      [self hideMenu];
   else
      [self showMenu];
}

//************************************************************
// showMenu
//************************************************************

-(void)showMenu
{
   JASidePanelController* side= (JASidePanelController*)self.parentViewController;
   
   [side showLeftPanelAnimated:YES];
}

//************************************************************
// hideMenu
//************************************************************

-(void)hideMenu
{
   JASidePanelController* side= (JASidePanelController*)self.parentViewController;
   
   [side showCenterPanelAnimated:YES];
}

#pragma mark - UITabBarControllerDelegate

//************************************************************
// didSelectViewController
//************************************************************

-(void)tabBarController:(UITabBarController *)tabBarController didSelectViewController:(UIViewController *)viewController
{
   if (![viewController respondsToSelector:@selector(update)])
      return;
   
//   BasePage* page= (BasePage*)viewController;
//   
//   [page update];
}


@end
