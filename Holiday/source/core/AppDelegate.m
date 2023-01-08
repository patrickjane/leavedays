//************************************************************
// AppDelegate.m
// Holiday
//************************************************************
// Created by Patrick Fial on 26.08.2013
// Copyright 2010-2013 Patrick Fial. All rights reserved.
//************************************************************

#import <EventKit/EventKit.h>
#import <EventKitUI/EventKitUI.h>

#import "AppDelegate.h"
#import "JASidePanelController.h"

#import "CalendarPage.h"
#import "TabController.h"
#import "OverviewPage.h"
#import "SettingsDialog.h"
#import "LeavePage.h"
#import "MapController.h"

#import "Storage.h"
#import "Settings.h"
#import "SessionManager.h"
#import "PublicHoliday.h"
#import "EventService.h"
#import "iCloudWaitPage.h"
#import "User.h"

//************************************************************
// AppDelegate
//************************************************************

@implementation AppDelegate

@synthesize storage, sessionManager, iCloudWaitView, ph;

#pragma mark - Application Lifecycle

//************************************************************
// stub handler
//************************************************************

- (BOOL)application:(UIApplication *)app
            openURL:(NSURL *)url
            options:(NSDictionary<UIApplicationOpenURLOptionsKey, id> *)options
{
   return YES;
}

//************************************************************
// didFinishLaunchingWithOptions
//************************************************************

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
   // color layout

   [[UISegmentedControl appearance] setTintColor:MAINCOLORDARK];
   [[UITabBar appearance] setTintColor:MAINCOLORDARK];
   
   [[UISearchBar appearance] setTintColor:MAINCOLORDARK];
   [[UIWindow appearance] setTintColor:MAINCOLORDARK];
   [[UIView appearanceWhenContainedInInstancesOfClasses:[NSArray arrayWithObject:[UIAlertController class]]] setTintColor:MAINCOLORDARK];
   
   [[UITableViewCell appearance] setTintColor:MAINCOLORDARK];
   
   [[UIButton appearance] setTintColor:MAINCOLORDARK];
//   [[UIBarButtonItem appearance] setTintColor:LIGHTTEXTCOLOR];
   
   [[UIButton appearanceWhenContainedInInstancesOfClasses:[NSArray arrayWithObject:[UIToolbar class]]] setTintColor:LIGHTTEXTCOLOR];
   [[UIButton appearanceWhenContainedInInstancesOfClasses:[NSArray arrayWithObject:[UINavigationBar class]]] setTintColor:LIGHTTEXTCOLOR];
   
   [[UINavigationBar appearance] setBarTintColor:MAINCOLORDARK];
   [[UINavigationBar appearance] setTintColor:LIGHTTEXTCOLOR];
   [[UINavigationBar appearance] setTitleTextAttributes:@{NSForegroundColorAttributeName : LIGHTTEXTCOLOR}];
   
   [[UIToolbar appearance] setBarTintColor:MAINCOLORDARK];
   [[UIToolbar appearance] setTintColor:LIGHTTEXTCOLOR];
   [[UIToolbar appearance] setTranslucent:NO];

   [[UISwitch appearance] setOnTintColor:MAINCOLORDARK];
   [[UITextField appearance] setTintColor:MAINCOLORDARK];
   
   // init public holiday
   
   self.ph= [[PublicHoliday alloc] init];

   // settings
   
   [Settings init];
   
   // iCloud availability
   
//   NSURL* ubiq= [[NSFileManager defaultManager] URLForUbiquityContainerIdentifier:nil];
//
//   if (ubiq)
//   {
//      NSLog(@"iCloud access at %@", ubiq);
//      [Settings setGlobalSetting:skICloudAvailable withBool:YES];
//   }
//   else
//   {
//      NSLog(@"No iCloud access");
      [Settings setGlobalSetting:skUseICloud withBool:NO];
      [Settings setGlobalSetting:skICloudAvailable withBool:NO];
//   }   

   // eventstore
   
   EKEventStore* store = [[[EKEventStore alloc] init] autorelease];
   
   [EventService setEventStore:store];
   
   // build interface
   
   self.sessionManager= [[[SessionManager alloc] init] autorelease];
   self.storage= [[[Storage alloc] init] autorelease];
   self.window = [[UIWindow alloc] initWithFrame:[[UIScreen mainScreen] bounds]];
   CGRect bounds = [[UIScreen mainScreen] bounds];

   TabController* tab= [[[TabController alloc] initWithNibName:@"TabController" bundle:[NSBundle mainBundle]] autorelease];
   SettingsDialog* settings= [[[SettingsDialog alloc] initWithStyle:UITableViewStyleGrouped] autorelease];
   JASidePanelController* sidepanels= [[JASidePanelController alloc] init];
   UINavigationController* nvc= [[[UINavigationController alloc] initWithRootViewController:settings] autorelease];
   nvc.delegate= settings;
   nvc.navigationBar.barStyle = UIStatusBarStyleLightContent;
   
   sidepanels.leftPanel = nvc;
   sidepanels.centerPanel = tab;
   sidepanels.rightPanel= nil;
   sidepanels.leftFixedWidth= bounds.size.width;
   sidepanels.allowLeftOverpan= NO;
   sidepanels.allowRightOverpan= NO;
   sidepanels.recognizesPanGesture= NO;
   
   NSArray* controllers;
   
   if (SYSTEM_VERSION_LESS_THAN(@"11.0"))
   {
      controllers= [NSArray arrayWithObjects:
                    [[[OverviewPage alloc] initWithNibName:@"OverviewPage_iPhone_ios10" bundle:[NSBundle mainBundle]] autorelease],
                    [[[CalendarPage alloc] initWithNibName:@"CalendarPage_iPhone_ios10" bundle:[NSBundle mainBundle]] autorelease],
                    [[[LeavePage alloc] initWithNibName:@"LeavePage_iPhone_ios10" bundle:[NSBundle mainBundle]] autorelease],
                    [[[MapController alloc] initWithNibName:@"MapController_iPhone_ios10" bundle:[NSBundle mainBundle]] autorelease],
                    nil];
   }
   else
   {
      controllers= [NSArray arrayWithObjects:
                    [[[OverviewPage alloc] initWithNibName:@"OverviewPage_iPhone" bundle:[NSBundle mainBundle]] autorelease],
                    [[[CalendarPage alloc] initWithNibName:@"CalendarPage_iPhone" bundle:[NSBundle mainBundle]] autorelease],
                    [[[LeavePage alloc] initWithNibName:@"LeavePage_iPhone" bundle:[NSBundle mainBundle]] autorelease],
                    [[[MapController alloc] initWithNibName:@"MapController_iPhone" bundle:[NSBundle mainBundle]] autorelease],
                    nil];
   }

   [tab setViewControllers:controllers];

   self.window.rootViewController = sidepanels;
   [self.window makeKeyAndVisible];
   
   [Service message:NSLocalizedString(@"App will be removed from app store", nil) withText:NSLocalizedString(@"After 10 years I am no longer able to maintain this app. As a result, it will be removed from the app store soon. Once the app is no longer available on the app store, it can still be used on the phone, however it can no longer be installed again. This means, that when reinstalling your iPhone, you will no longer have access to your leave data since the app can not be installed. I therefore advise you to export your data using the CSV export (arrow-button on the top right). Thanks for using the app throughout the years!", nil) forController:sidepanels completion:nil];
   

   [store requestAccessToEntityType:EKEntityTypeEvent completion:^(BOOL granted, NSError *error)
    {
       [EventService setHaveCalendarAccess:granted];
       
       [self performSelectorOnMainThread:@selector(initUI) withObject:nil waitUntilDone:NO];
    }];

   return YES;
}

//************************************************************
// initUI
//************************************************************

-(void)initUI
{
   // must be done AFTER user was asked for permission of calendars
   // and calendar access must be asked AFTER main window is created
   
   // initially load users
   
   if ([Settings globalSettingBool:skFirstRun])
   {
      UIStoryboard *storyboard = [UIStoryboard storyboardWithName:@"Main_iPhone" bundle:nil];
      UIViewController *vc = [storyboard instantiateViewControllerWithIdentifier:@"wizardStart"];
      UINavigationController* nvc2= [[[UINavigationController alloc] initWithRootViewController:vc] autorelease];
      nvc2.navigationBar.barStyle = UIStatusBarStyleLightContent;
      
      [vc setModalPresentationStyle:UIModalPresentationFullScreen];
      
      User* user= [[Storage currentStorage] createDefaultUser:NO completion:nil];
      
      [SessionManager setWizardUser:user];
      [Settings loadUserSettings:user];
      
      [self.window.rootViewController presentViewController:nvc2 animated:YES completion:nil];
   }
   else
   {
      if ([Settings globalSettingBool:skUseICloud] && ([Settings globalSettingBool:skSingleUser] || [Settings globalSettingBool:skAutoLogin]))
      {
         // show waiting page until users are fully loaded from iCloud. else login dialog will popup, but we're in single user mode/auto-login mode
         
         iCloudWaitPage* page= [[[NSBundle mainBundle] loadNibNamed:@"iCloudWaitView_iPhone"owner:self options:nil] lastObject];
         
         page.textLabel.text= NSLocalizedString(@"Synchronizing with iCloud...", nil);
         self.iCloudWaitView= page;
         [self.window addSubview:page];
         
         [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(iCloudInitialized:) name:kICloudStorageInitialized object:nil];
         [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(sessionManagerDone:) name:kUserLoggedIn object:nil];
         [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(sessionManagerDone:) name:kUserLoginFailed object:nil];
         
         [self.storage reloadUsers:nil];
      }
      else
      {
         [self.storage reloadUsers:^(BOOL success)
          {
             // session
             
             [self.sessionManager login];
          }];
      }
   }
}

-(void)iCloudInitialized:(id)sender
{
   [self.sessionManager login];
}

-(void)sessionManagerDone:(id)sender
{
   if (self.iCloudWaitView)
   {
      [UIView animateWithDuration:0.5 animations:^()
       {
          self.iCloudWaitView.alpha = 0.0f;
       } completion:^(BOOL finished)
       {

          [self.iCloudWaitView removeFromSuperview];
          self.iCloudWaitView= nil;
       }];
   }
}

//************************************************************
// showMenu
//************************************************************

-(void)showMenu
{
   JASidePanelController* side = (JASidePanelController*)self.window.rootViewController;
   [side showLeftPanelAnimated:YES];
}

//************************************************************
// showMenu
//************************************************************

-(void)hideMenu
{
   JASidePanelController* side = (JASidePanelController*)self.window.rootViewController;
   [side showCenterPanelAnimated:YES];
}

#pragma mark - Storage

//************************************************************
// localDocumentsDirectoryURL
//************************************************************

+(NSURL*)localDocumentsDirectoryURL
{
   static NSURL* localDocumentsDirectoryURL = nil;
   
   if (localDocumentsDirectoryURL == nil)
   {
      NSString *documentsDirectoryPath = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES ) objectAtIndex:0];
      
      localDocumentsDirectoryURL = [[NSURL fileURLWithPath:documentsDirectoryPath] retain];
   }
   
   return localDocumentsDirectoryURL;
}

//************************************************************
// applicationDocumentsDirectory
//************************************************************

- (NSURL *)applicationDocumentsDirectory
{
   // The directory the application uses to store the Core Data store file. This code uses a directory named "com.theappcodellc.CoreDataTest” in the application's documents directory.

   return [[[NSFileManager defaultManager] URLsForDirectory:NSDocumentDirectory inDomains:NSUserDomainMask] lastObject];
}

@end
