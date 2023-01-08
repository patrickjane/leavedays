//************************************************************
// SessionManager.m
// Holliday
//************************************************************
// Created by Patrick Fial on 12.04.14.
// Copyright 2014-2014 Patrick Fial. All rights reserved.
//************************************************************

//************************************************************
// includes
//************************************************************

#import "SessionManager.h"
#import "Settings.h"
#import "Service.h"
#import "Storage.h"
#import "Calculation.h"
#import "LoginDialog.h"
#import "AppDelegate.h"
#import "PublicHoliday.h"

#import "User.h"
#import "YearSummary.h"
#import "Pool.h"

//************************************************************
// class SessionManager
//************************************************************

@implementation SessionManager

static SessionManager* instance= nil;

#pragma mark - Static Class stuff

+(SessionManager*)session
{
   return instance;
}

#pragma mark - Lifecycle

//************************************************************
// init
//************************************************************

-(id)init
{
   self = [super init];
   
   if (self)
   {
      instance= self;
   }
   
   return self;
}

//************************************************************
// dealloc
//************************************************************

-(void)dealloc
{
   [super dealloc];
}

#pragma mark - functionality

//************************************************************
// login
//************************************************************

-(void)login
{
   if (![Settings globalSettingBool:skSingleUser])
   {
      // try auto-login
      
      if ([Settings globalSettingBool:skAutoLogin] && [[Settings globalSettingString:skLastUser] length])
      {
         User* user= [[Storage currentStorage] userWithName:[Settings globalSettingString:skLastUser]];
         
         if (user)
         {
            [self login:user withAutoLogin:YES];
            return;
         }
      }
      
      [[NSNotificationCenter defaultCenter] postNotificationName:kUserLoginFailed object:self];

      AppDelegate* del= (AppDelegate*)[UIApplication sharedApplication].delegate;
      LoginDialog* login= [[[LoginDialog alloc] initWithNibName:@"LoginDialog_iPhone" bundle:[NSBundle mainBundle]] autorelease];

      login.modalPresentationStyle= UIModalPresentationFormSheet;
      [del.window.rootViewController presentViewController:login animated:YES completion:nil];
   }
   else
   {
      User* user= [[Storage currentStorage] singleUser];
      
//      if (!user)
//         user= [Storage userlist].firstObject;
      
      if (user)
      {
         [self login:user withAutoLogin:NO];
      }
      else
      {
         // should really never happen
         
         NSLog(@"FATAL: could not find single user for login");
         [[NSNotificationCenter defaultCenter] postNotificationName:kUserLoginFailed object:self];
         
         AppDelegate* del= (AppDelegate*)[UIApplication sharedApplication].delegate;
         LoginDialog* login= [[[LoginDialog alloc] initWithNibName:@"LoginDialog_iPhone" bundle:[NSBundle mainBundle]] autorelease];
            
         login.modalPresentationStyle= UIModalPresentationFormSheet;
         [del.window.rootViewController presentViewController:login animated:YES completion:nil];
      }
   }
}

//************************************************************
// login (specific user after successful authentification)
//************************************************************

-(void)login:(User*)user withAutoLogin:(BOOL)autoLogin
{
   [Settings loadUserSettings:user];
   [Settings setGlobalSetting:skLastUser withString:user.name];
   [Settings setGlobalSetting:skAutoLogin withBool:autoLogin];
   
   [SessionManager setActiveUser:user];
   [SessionManager setDisplayUser:user];
   [SessionManager setDisplayUserIds:[NSArray arrayWithObject:user.uuid]];
   [SessionManager setDisplayUsers:[NSDictionary dictionaryWithObject:user.name forKey:user.uuid]];
   
   if ([Settings userSettingInt:skYearBeginPorted] == 0)
   {
      NSLog(@"Porting year begin ... ");
      
      id yearBegin = [Settings userSettingObject:skYearBegin];
      
      if (!yearBegin || ![yearBegin isKindOfClass:[NSDate class]])
      {
         NSLog(@"Could not determine year begin, assuming january");
         [Settings setUserSetting:skYearBegin withInt:1];
         [Settings setUserSetting:skYearBeginPorted withInt:1];
      }
      else
      {
         int month = (int)[[NSCalendar currentCalendar] component:NSCalendarUnitMonth fromDate:yearBegin];

         [Settings setUserSetting:skYearBegin withInt:month];
         [Settings setUserSetting:skYearBeginPorted withInt:1];

         NSLog(@"Year begin is: %@ (month: %d)", yearBegin, month);
      }
   }
   else
      NSLog(@"Year begin already ported");

   // fetch/create year summaries for currently logged in user
   
   int thisYear= [Calculation getThisYear];
   YearSummary* year= [[Storage currentStorage] createYearSummary:thisYear];

   if (year)
      [SessionManager setCurrentYear:year];
   else
      NSLog(@"Could not load current year (%d)", thisYear);
   
   [Storage rebuildFreedaysList];
   
   [Calculation expireResidualLeave:year completion:^(BOOL success)
    {
       [[NSNotificationCenter defaultCenter] postNotificationName:kUserLoggedIn object:self];
    }];
   
   [[PublicHoliday instance] reloadEntries];
}

//************************************************************
// logout
//************************************************************

-(void)logout
{
   [Settings loadUserSettings:nil];        // save current settings and clear
   [Settings setGlobalSetting:skAutoLogin withBool:NO];
   
   // hide last users data
   
   [SessionManager setCurrentYear:nil];
   [SessionManager setDisplayUserIds:nil];
   [SessionManager setDisplayUsers:nil];
   [SessionManager setActiveUser:nil];
   
   [Settings synchronize];
   
   [[NSNotificationCenter defaultCenter] postNotificationName:kUserLoggedOut object:self];
   
   // open login dialog
       
   [self login];
}

//************************************************************
// logout (sender)
//************************************************************

-(void)logout:(id)sender
{
   [self logout];
}

#pragma mark - Static User stuff

static User* displayUser= nil;
static User* activeUser= nil;
static User* wizardUser= nil;
static NSArray* displayUserIds= nil;
static NSDictionary* displayUsers= nil;

//************************************************************
// activeUser
//************************************************************

+(User*)activeUser
{
   return activeUser;
}

//************************************************************
// displayUser
//************************************************************

+(User*)displayUser
{
   return displayUser;
}

//************************************************************
// displayUser
//************************************************************

+(User*)wizardUser
{
   return wizardUser;
}

//************************************************************
// setActiveUser
//************************************************************

+(void)setActiveUser:(User*)user
{
   if (activeUser)
      [activeUser release];
   
   activeUser= user;
   [user retain];
}

//************************************************************
// setDisplayUser
//************************************************************

+(void)setDisplayUser:(User*)user
{
   if (displayUser)
      [displayUser release];
   
   displayUser= user;
   [user retain];
}

// *****************************************
// setWizardUser
// *****************************************

+(void)setWizardUser:(User*)user
{
   if (wizardUser)
      [wizardUser release];
   
   wizardUser= user;
   [user retain];
}

// *****************************************
// setDefaultUsers (UUID list)
// *****************************************

+(NSArray*)displayUserIds
{
   return displayUserIds;
}

+(void)setDisplayUserIds:(NSArray*)ids
{
   [displayUserIds release];
   displayUserIds= ids;
   [displayUserIds retain];
}

// *****************************************
// setDefaultUsers (name/UUID dictionary)
// *****************************************

+(NSDictionary*)displayUsers
{
   return displayUsers;
}

+(void)setDisplayUsers:(NSDictionary*)users
{
   [displayUsers release];
   displayUsers= users;
   [displayUsers retain];
}

#pragma mark - Static Year stuff

static YearSummary* currentYear= nil;

//************************************************************
// currentYear
//************************************************************

+(YearSummary*)currentYear
{
   return currentYear;
}

//************************************************************
// setCurrentYear
//************************************************************

+(void)setCurrentYear:(YearSummary*)year
{
   if (currentYear)
      [currentYear release];
   
   currentYear= year;
   
   if (currentYear)
      [currentYear retain];
}

@end
