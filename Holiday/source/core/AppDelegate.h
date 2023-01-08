//************************************************************
// AppDelegate.h
// Holiday
//************************************************************
// Created by Patrick Fial on 26.08.2013
// Copyright 2010-2013 Patrick Fial. All rights reserved.
//************************************************************

//************************************************************
// includes
//************************************************************

#import <UIKit/UIKit.h>

@class Storage;
@class SessionManager;
@class PublicHoliday;
@class EKEventStore;

//************************************************************
// class AppDelegate
//************************************************************

@interface AppDelegate : UIResponder <UIApplicationDelegate>

@property (strong, nonatomic) UIWindow *window;
@property (nonatomic, retain) Storage* storage;
@property (nonatomic, retain) SessionManager* sessionManager;
@property (nonatomic, retain) PublicHoliday* ph;
@property (nonatomic, retain) UIView* iCloudWaitView;

-(void)showMenu;
-(void)hideMenu;
+(NSURL*)localDocumentsDirectoryURL;

- (NSURL *)applicationDocumentsDirectory;

@end
