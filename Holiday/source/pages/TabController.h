//************************************************************
// TabController.h
// Holliday
//************************************************************
// Created by Patrick Fial on 27.12.14.
// Copyright 2014-2015 Patrick Fial. All rights reserved.
//************************************************************

//************************************************************
// includes
//************************************************************

#import <UIKit/UIKit.h>

//************************************************************
// class TabController
//************************************************************

@interface TabController : UITabBarController<UITabBarControllerDelegate>

-(void)showMenu;
-(void)handleShowMenu;
-(void)hideMenu;

@end
