//************************************************************
// Storage.m
// Holliday
//************************************************************
// Created by Patrick Fial on 15.09.13.
// Copyright 2013-2013 Patrick Fial. All rights reserved.
//************************************************************

//************************************************************
// includes
//************************************************************

#import <objc/runtime.h>    // key-value coding to NSDictionary

#import "AppDelegate.h"
#import "Settings.h"
#import "Service.h"
#import "Storage.h"
#import "Crypt.h"
#import "SessionManager.h"
#import "LeaveDialog.h"
#import "Calculation.h"
#import "EventService.h"

#import "User.h"
#import "YearSummary.h"
#import "Category.h"
#import "Pool.h"
#import "Timetable.h"
#import "LeaveInfo.h"
#import "Freeday.h"

//************************************************************
// class Storage(private)
//************************************************************

@interface Storage()
{
   NSMetadataQuery* queryUsers;
}

@property (nonatomic, retain) NSMutableArray* userList;

-(void)fileListReceived:(NSMetadataQuery*)query;
+(void)createDefaultCategories:(User*)owner;
+(void)createDefaultTimetables:(User*)owner;
-(void)userStateChanged:(NSNotification*)notification;

@end

//************************************************************
// class Storage
//************************************************************

@implementation Storage

@synthesize userList;

#pragma mark - Lifecycle

//************************************************************
// statics
//************************************************************

static Storage* storageInstace= nil;
static int nActivities= 0;
static NSMutableDictionary* freedays = nil;

//************************************************************
// init
//************************************************************

-(id)init
{
   self= [super init];
   
   if (self)
   {
      freedays = [[NSMutableDictionary alloc] init];
      storageInstace= self;
      queryUsers= nil;
      self.userList= [NSMutableArray array];
   }
   
   return self;
}

//************************************************************
// dealloc
//************************************************************

-(void)dealloc
{
   [self.userList removeAllObjects];
   self.userList= nil;
   
   [freedays release];
   
   [super dealloc];
}

//************************************************************
// currentStorage
//************************************************************

+(Storage*)currentStorage
{
   return storageInstace;
}

//************************************************************
// userlist
//************************************************************

+(NSArray*)userlist
{
   return [Storage currentStorage].userList;
}

#pragma mark - Static helpers

//************************************************************
// stopQueries
//************************************************************

-(void)showAddDialog
{
   [self showAddDialog:nil withBegin:nil endEnd:nil andYear:0 completion:nil];
}

-(void)showAddDialog:(LeaveInfo*)info withBegin:(NSDate*)begin endEnd:(NSDate*)end andYear:(int)year completion:(void (^)(void))completionHandler
{
   AppDelegate* delegate= (AppDelegate*)[UIApplication sharedApplication].delegate;
   LeaveDialog* dvc= [[[LeaveDialog alloc] initWithStyle:UITableViewStyleGrouped] autorelease];
   UINavigationController* navController = [[[UINavigationController alloc] initWithRootViewController:dvc] autorelease];
   navController.navigationBar.barStyle = UIStatusBarStyleLightContent;
   
   dvc.leaveInfo= info;
   
   if (begin)
      dvc.beginDate= begin;
      
   if (end)
      dvc.endDate= end;
      
   if (year)
      dvc.leaveYear= year;
   
   [dvc fill];
   
   dvc.completionHandler= completionHandler;

   [delegate.window.rootViewController presentViewController:navController animated:YES completion:nil];
}

#pragma mark - Queries

//************************************************************
// stopQueries
//************************************************************

-(void)stopQueries
{
   if (queryUsers && !queryUsers.isStopped)
      [queryUsers stopQuery];
}

#pragma mark - Callbacks

//************************************************************
// fileListReceived
//************************************************************

-(void)fileListReceived:(NSNotification *)notification
{
   NSMetadataQuery* query= [notification object];
   
   NSLog(@"Received user file list from icloud ...");
   
   // (1) clear list and remember static objects
   
   NSString* displayUserFilename= [SessionManager displayUser] ? [[SessionManager displayUser].fileURL.lastPathComponent retain] : nil;
   NSString* activeUserFilename= [SessionManager activeUser] ? [[SessionManager activeUser].fileURL.lastPathComponent retain] : nil;
   
   [self.userList removeAllObjects];
   
   [SessionManager setActiveUser:nil];
   [SessionManager setDisplayUser:nil];
   
   // (2) loop users and open documents
   
   dispatch_group_t userLoadGroup = dispatch_group_create();
   
   for (NSMetadataItem* result in [query results])
   {
      User* user= [[User alloc] initWithFileURL:[result valueForAttribute:NSMetadataItemURLKey]];
      
      if (displayUserFilename && [displayUserFilename isEqualToString:[result valueForAttribute:NSMetadataItemFSNameKey]])
         [SessionManager setDisplayUser:user];
      
      if (activeUserFilename && [activeUserFilename isEqualToString:[result valueForAttribute:NSMetadataItemFSNameKey]])
         [SessionManager setActiveUser:user];
      
      NSLog(@"Opening user document with filename '%@'", [result valueForAttribute:NSMetadataItemFSNameKey]);
      
      dispatch_group_enter(userLoadGroup);
      
      [user openWithCompletionHandler:^(BOOL success)
       {
          if (success)
             [self.userList addObject:user];
          else
             NSLog(@"FAILED to open document");
          
          dispatch_group_leave(userLoadGroup);
       }];
      
      [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(userStateChanged:) name:UIDocumentStateChangedNotification object:user];
   }
   
   dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0),^{
      dispatch_group_wait(userLoadGroup, DISPATCH_TIME_FOREVER);
      dispatch_release(userLoadGroup);
      
      dispatch_async(dispatch_get_main_queue(),^
                     {
                        // done
                        
                        [[NSNotificationCenter defaultCenter] postNotificationName:kICloudStorageInitialized object:self];
                     });
   });
   
   [displayUserFilename release];
   [activeUserFilename release];
   
   [queryUsers autorelease];
   queryUsers= nil;
}

//************************************************************
// userStateChanged
//************************************************************

-(void)userStateChanged:(NSNotification*)notification
{
   User* usr= notification.object;
   
   int state= (int)usr.documentState;
   
   if (state == 0)
      NSLog(@"-------- iCloud Notification received for user '%@', state is UIDocumentStateNormal", usr.name);

   if (state & UIDocumentStateEditingDisabled)
   {
      NSLog(@"-------- iCloud Notification received for user '%@', state is UIDocumentStateEditingDisabled", usr.name);
      nActivities |= UIDocumentStateEditingDisabled;
   }
   
   if (state & UIDocumentStateInConflict)
   {
      NSLog(@"-------- iCloud Notification received for user '%@', state is UIDocumentStateInConflict", usr.name);
      nActivities |= UIDocumentStateInConflict;
   }

   if (state & UIDocumentStateClosed)
   {
      NSLog(@"-------- iCloud Notification received for user '%@', state is UIDocumentStateClosed", usr.name);
      nActivities |= UIDocumentStateClosed;
   }
   
   if (state & UIDocumentStateProgressAvailable)
   {
      NSLog(@"-------- iCloud Notification received for user '%@', state is UIDocumentStateProgressAvailable", usr.name);
      nActivities |= UIDocumentStateProgressAvailable;
   }
   
   if (state & UIDocumentStateSavingError)
   {
      NSLog(@"-------- iCloud Notification received for user '%@', state is UIDocumentStateSavingError", usr.name);
      nActivities |= UIDocumentStateSavingError;
   }

   if (state & UIDocumentStateEditingDisabled)
   {
      NSLog(@"-------- iCloud Notification received for user '%@', state is UIDocumentStateEditingDisabled", usr.name);
      nActivities |= UIDocumentStateEditingDisabled;
   }

   if (state != 0 && !(state & UIDocumentStateInConflict || state & UIDocumentStateNormal || state & UIDocumentStateClosed || state & UIDocumentStateProgressAvailable || state & UIDocumentStateSavingError || state & UIDocumentStateEditingDisabled))
      NSLog(@"-------- iCloud Notification received for user '%@', state is %d (nActivities: %d)", usr.name, state, nActivities);

   if (state == 0 && (nActivities & UIDocumentStateProgressAvailable))
   {
      if ((nActivities & UIDocumentStateEditingDisabled) && !(state & UIDocumentStateInConflict))
      {
         nActivities= 0;
         [[NSNotificationCenter defaultCenter] postNotificationName:kICloudUpdate object:self];
         NSLog(@"-------- iCloud Notification - updates for %@ successfully received, posting notification kICloudUpdate", usr.name);
      }
   }
   
   NSFileVersion* currentVersion= [NSFileVersion currentVersionOfItemAtURL:usr.fileURL];
   NSMutableArray* versions= [[NSFileVersion unresolvedConflictVersionsOfItemAtURL:usr.fileURL] mutableCopy];

   if (versions.count)
   {
      [versions addObject:currentVersion];
      [versions sortUsingComparator:^(NSFileVersion* first, NSFileVersion* second) {
         return [[NSCalendar currentCalendar] compareDate:second.modificationDate toDate:first.modificationDate toUnitGranularity:NSCalendarUnitSecond];
      }];
      
      for (NSFileVersion* version in versions)
         NSLog(@"- iCloud CONFLICT: Conflicting version: %c (%@)", version == currentVersion ? 'C' : 'X', version.modificationDate);
      
      NSFileVersion* versionToPick= versions.firstObject;
      
      NSLog(@"- iCloud CONFLICT: Resolving conflict to version: %c %@", versionToPick == currentVersion ? 'C' : 'X', versionToPick.modificationDate);
      
      if (versionToPick == currentVersion)
      {
         [NSFileVersion removeOtherVersionsOfItemAtURL:usr.fileURL error:nil];
         
         for (NSFileVersion* conflict in [NSFileVersion unresolvedConflictVersionsOfItemAtURL:usr.fileURL])
            conflict.resolved= YES;

         NSLog(@"- iCloud CONFLICT: Picked current version and removed other versions");
         
         [[NSNotificationCenter defaultCenter] postNotificationName:kICloudUpdate object:self];
      }
      else
      {
         [versionToPick replaceItemAtURL:usr.fileURL options:0 error:nil];
         [NSFileVersion removeOtherVersionsOfItemAtURL:usr.fileURL error:nil];
         
         for (NSFileVersion* conflict in [NSFileVersion unresolvedConflictVersionsOfItemAtURL:usr.fileURL])
            conflict.resolved= YES;
         
         [usr revertToContentsOfURL:usr.fileURL completionHandler:^(BOOL success) {
            if (success)
               NSLog(@"- iCloud CONFLICT: Successfully reverted to newest OTHER version");
            else
               NSLog(@"- iCloud CONFLICT: FAILED to revert to newest OTHER version");
            
            [[NSNotificationCenter defaultCenter] postNotificationName:kICloudUpdate object:self];
         }];
      }
   }
}


#pragma mark - General Storage

//************************************************************
// wipeData
//************************************************************

-(void)wipeData:(BOOL)isSingleUser completionHandler:(void (^)(BOOL success))completionHandler
{
   NSArray* users= [self.userList copy];
   
   for (User* user in users)
      [self deleteUser:user];
       
   [users release];
   
   // (re-)create the deault user
   
   if (isSingleUser)
      [self createDefaultUser:YES completion:completionHandler];
   else if (completionHandler)
      completionHandler(YES);
}

#pragma mark - User specific

//************************************************************
// forgetUsers
//************************************************************

-(void)forgetUsers
{
   int n= 0;
   
   NSLog(@"Forget users ...");
   
   for (User* user in userList)
   {
      [user closeWithCompletionHandler:nil];
      n++;
   }
   
   [userList removeAllObjects];
   
   NSLog(@"Closed %d users", n);
}

//************************************************************
// reloadUsers
//************************************************************

-(void)reloadUsers:(void (^)(BOOL success))completionHandler
{
   if ([Settings globalSettingBool:skICloudAvailable] && [Settings globalSettingBool:skUseICloud])
   {
      NSLog(@"Retrieving file list from iCloud ...");
      
      if (!queryUsers)
      {
         queryUsers = [[NSMetadataQuery alloc] init];
         [queryUsers setSearchScopes:[NSArray arrayWithObjects:NSMetadataQueryUbiquitousDocumentsScope, nil]];
         [queryUsers setPredicate:[NSPredicate predicateWithFormat:@"%K LIKE '*.user'", NSMetadataItemFSNameKey]];
         
         [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(fileListReceived:) name: NSMetadataQueryDidFinishGatheringNotification object:queryUsers];
//         [nc addObserver:self selector:@selector(queryDidUpdate:) name:NSMetadataQueryDidUpdateNotification object:self.query];
      }
      
      if (![queryUsers isStarted])
         [queryUsers startQuery];
      
      if (completionHandler)
         completionHandler(YES);
   }
   else
   {
      dispatch_group_t userLoadGroup = dispatch_group_create();
      
      NSArray* localDocuments = [[NSFileManager defaultManager] contentsOfDirectoryAtPath:[[AppDelegate localDocumentsDirectoryURL] path] error:nil];
      
      for (NSString* document in localDocuments)
      {
         if (![document hasSuffix:@".user"])
            continue;

         User* user=[[[User alloc] initWithFileURL:[NSURL fileURLWithPath:[[[AppDelegate localDocumentsDirectoryURL] path]
                                                                           stringByAppendingPathComponent:document]]] autorelease];

#ifdef __DEBUG__
         NSLog(@"Opening user document at url '%@'/'%@' ...", [AppDelegate localDocumentsDirectoryURL], document);
#endif
         dispatch_group_enter(userLoadGroup);

         [user openWithCompletionHandler:^(BOOL success)
          {
             if (success)
                [self.userList addObject:user];
             else
                NSLog(@"FAILED to open document");

             dispatch_group_leave(userLoadGroup);
          }];
      }

      dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0),^{
         dispatch_group_wait(userLoadGroup, DISPATCH_TIME_FOREVER);
         dispatch_release(userLoadGroup);
         dispatch_async(dispatch_get_main_queue(),^
                        {
                           if (completionHandler)
                              completionHandler(TRUE);
                        });
      });
   }
}

//************************************************************
// userWithUUid
//************************************************************

-(User*)userWithUUid:(NSString*)uuid;
{
   for (User* user in self.userList)
      if ([user.uuid isEqualToString:uuid])
         return user;
   
   return nil;
}

//************************************************************
// userWithName
//************************************************************

-(User*)userWithName:(NSString*)name
{
   for (User* user in self.userList)
      if ([user.name isEqualToString:name])
         return user;
   
   return nil;
}

//************************************************************
// usersWithName
//************************************************************

-(NSArray*)usersWithName:(NSString*)name
{
   NSMutableArray* users= [NSMutableArray array];
   
   for (User* user in self.userList)
      if ([user.name isEqualToString:name])
         [users addObject:user];

   return users;
}

// *****************************************
// singleUser
// *****************************************

-(User*)singleUser
{
   for (User* user in self.userList)
      if (user.isSingleUser)
         return user;
   
   return nil;
}

// *****************************************
// haveUserWithName
// *****************************************

-(BOOL)haveUserWithName:(NSString*)name
{
   User* user= [self userWithName:name];
   
   if (user)
      return YES;
   
   return NO;
}

//************************************************************
// createUser
//************************************************************

-(User*)createEmptyUser
{
   NSString* uuid= @"EMPTY";
   NSString* path= [[AppDelegate localDocumentsDirectoryURL] path];
   NSURL* url= [NSURL fileURLWithPath:[path stringByAppendingPathComponent:[NSString stringWithFormat:@"%@.user", uuid]]];
   
   User* user=[[User alloc] initWithFileURL:url];
   
   return user;
}

//************************************************************
// createDefaultUser
//************************************************************

-(User*)createDefaultUser:(BOOL)store completion:(void (^)(BOOL success))completionHandler
{
   NSString* uuid= [Service createUUID];
   NSString* path= [[AppDelegate localDocumentsDirectoryURL] path];
   NSURL* url= [NSURL fileURLWithPath:[path stringByAppendingPathComponent:[NSString stringWithFormat:@"%@.user", uuid]]];
   
   if ([[NSFileManager defaultManager] fileExistsAtPath:url.absoluteString])
   {
      [Service alert:NSLocalizedString(@"Error", nil) withText:NSLocalizedString(@"Same user already exists", nil) andError:nil forController:nil completion:nil];
      return nil;
   }
   
   User* user=[[[User alloc] initWithFileURL:url] autorelease];
   
   user.uuid= uuid;
   user.name= NSLocalizedString(@"Default user", nil);
   user.password= @"";
   user.years= [NSMutableArray array];
   user.leave= [NSMutableArray array];
   user.timetables= [NSMutableArray array];
   user.categories= [NSMutableArray array];
   user.settings= [Settings getDefaultSettings];
   user.isSingleUser= YES;
   
   NSString* color= nil;
   
   if ([Storage userlist].count)
   {
      color= [[Service defaultColors] objectAtIndex:[Storage userlist].count % [Service defaultColors].count];
      user.rights= [NSNumber numberWithInt:0];
   }
   else
   {
      color= [[Service defaultColors] objectAtIndex:0];
      user.rights= [NSNumber numberWithInt:rightAdmin];
   }
   
   user.color= color;
   user.availableUsers= user.uuid;
   
   // categories, timetables
   
   [Storage createDefaultCategories:user];
   [Storage createDefaultTimetables:user];
   
   // default year
   
   int year= (int)[[NSCalendar currentCalendar] component:NSCalendarUnitYear fromDate:[NSDate date]];
   
   YearSummary* thisYear= [[Storage currentStorage] createYearSummary:year];
   
   thisYear.userid= user.uuid;
   [user.years addObject:thisYear];
   
   // default pool residual leave

   [[Storage currentStorage] createPool:thisYear withCategory:[Storage categoryForInternalName:@"residualleave" ofUser:user]];

   if (store)
   {
      [self.userList addObject:user];
      [user saveDocument:completionHandler];
   }

   return user;
}

//************************************************************
// addUser
//************************************************************

-(void)addUser:(User*)aUser
{
   [self.userList addObject:aUser];
}

//************************************************************
// createUser
//************************************************************

-(void)createUser:(NSString*)name andPassword:(NSString*)password andUuid:(NSString*)aUuid completion:(void (^)(BOOL success, User* user))completionHandler
{
   NSString* uuid= aUuid ? aUuid : [Service createUUID];
   NSString* path= [[AppDelegate localDocumentsDirectoryURL] path];
   NSURL* url= [NSURL fileURLWithPath:[path stringByAppendingPathComponent:[NSString stringWithFormat:@"%@.user", uuid]]];

   if ([[NSFileManager defaultManager] fileExistsAtPath:url.absoluteString])
   {
      [Service alert:NSLocalizedString(@"Error", nil) withText:NSLocalizedString(@"Same user already exists", nil) andError:nil forController:nil completion:nil];
      completionHandler(NO, nil);
      return;
   }
   
   User* user=[[[User alloc] initWithFileURL:url] autorelease];
   
   user.uuid= uuid;
   user.name= name;
   user.password= isEmpty(password) ? nil : [password hashedSha2];
   user.years= [NSMutableArray array];
   user.leave= [NSMutableArray array];
   user.timetables= [NSMutableArray array];
   user.categories= [NSMutableArray array];
   user.settings= [Settings getDefaultSettings];
   
   NSString* color= nil;
   
   if ([Storage userlist].count)
      color= [[Service defaultColors] objectAtIndex:[Storage userlist].count % [Service defaultColors].count];
   else
      color= [[Service defaultColors] objectAtIndex:0];
   
   user.color= color;
   user.availableUsers= user.uuid;
   
   [Storage createDefaultCategories:user];
   [Storage createDefaultTimetables:user];
   
   
   [user saveToURL:url forSaveOperation:UIDocumentSaveForCreating completionHandler:^(BOOL success)
    {
       if (!success)
          [Service alert:NSLocalizedString(@"Error", nil) withText:NSLocalizedString(@"Failed to save data", nil) andError:nil forController:nil completion:nil];
       else
       {
          [self.userList addObject:user];
#ifdef __DEBUG__
          [NSString stringWithFormat:@"Successfully saved user to url '%@'", url.path];
#endif
       }
       
       completionHandler(success, user);
    }];
}

//************************************************************
// deleteUser
//************************************************************

-(BOOL)deleteUser:(User*)aUser
{
   for (User* user in self.userList)
      if (user == aUser)
      {
         [self.userList removeObject:user];
         break;
      }
   
   [aUser closeWithCompletionHandler:^(BOOL success)
    {
       if (success)
       {
          NSError* error= nil;
          NSFileManager* fileManager = [[[NSFileManager alloc] init] autorelease];

          if ([fileManager removeItemAtURL:aUser.fileURL error:&error] != true)
          {
             [Service alert:NSLocalizedString(@"Error", nil) withText:NSLocalizedString(@"Failed to delete data from storage", nil) andError:nil forController:nil completion:nil];
          }
          else
             NSLog(@"Deleted document %@", aUser.fileURL.path);
       }
    }];


   return YES;
}

// *****************************************
// initUser
// *****************************************

-(void)initUser:(NSURL*)userUrl completion:(void (^)(BOOL success))completionHandler
{
   User* user=[[[User alloc] initWithFileURL:userUrl] autorelease];
   
#ifdef __DEBUG__
   NSLog(@"Opening user document at url '%@' ...", userUrl.path);
#endif
   
   [user openWithCompletionHandler:^(BOOL success)
    {
       if (success)
          [self.userList addObject:user];
       else
          NSLog(@"FAILED to open document");
       
       if (completionHandler)
          completionHandler(success);
    }];
}

-(void)initUser:(NSURL*)userUrl
{
   return [self initUser:userUrl completion:nil];
   
//   User* user=[[[User alloc] initWithFileURL:userUrl] autorelease];
//   
//#ifdef __DEBUG__
//   NSLog(@"Opening user document at url '%@' ...", userUrl.path);
//#endif
//   
//   [user openWithCompletionHandler:^(BOOL success)
//    {
//       if (success)
//          [self.userList addObject:user];
//       else
//          NSLog(@"FAILED to open document");
//    }];
}

#pragma mark - Year specific

// *****************************************
// fetch year (current user)
// *****************************************

-(YearSummary*)getYear:(int)aYear
{
   if (![SessionManager activeUser])
      return nil;
   
   return [self getYear:aYear withUserId:[SessionManager activeUser].uuid];
}

// *****************************************
// fetch year (specific user)
// *****************************************

-(YearSummary*)getYear:(int)aYear withUserId:(NSString*)userid
{
   User* user= [[Storage currentStorage] userWithUUid:userid];
   
   if (!user)
   {
      [Service alert:NSLocalizedString(@"Error", nil) withText:NSLocalizedString(@"Failed to load data from storage", nil) andError:nil forController:nil completion:nil];
      return nil;
   }
   
   for (YearSummary* year in user.years)
   {
      if (year.year.intValue == aYear)
         return year;
   }

   return nil;
}

// *****************************************
// create Year Summary
// *****************************************

-(YearSummary*)createYearSummary:(int)aYear
{
   YearSummary* precedingYear= [[Storage currentStorage] getYear:aYear-1];
   
   return [self createYearSummary:aYear withPrecedingYear:precedingYear];
}

// *****************************************
// create Year Summary (variant)
// *****************************************

-(YearSummary*)createYearSummary:(int)aYear withPrecedingYear:(YearSummary*)precedingYear
{
   YearSummary* sum= [self getYear:aYear];
   
   if (sum)
      return sum;
   
   // new document, insert empty year info

   sum= [[[YearSummary alloc] init] autorelease];
   sum.year = [NSNumber numberWithInt:aYear];
   sum.userid= [SessionManager activeUser].uuid;
   
   sum.amount_remain = [NSNumber numberWithInt:0];
   sum.amount_remain_with_pools = [NSNumber numberWithInt:0];
   sum.amount_spent = [NSNumber numberWithInt:0];
   sum.amount_spent_with_pools = [NSNumber numberWithInt:0];
   sum.amount_with_pools = [NSNumber numberWithInt:0];
   sum.days_per_year = [NSNumber numberWithInt:0];
   sum.remain_expiration = nil;
   sum.userInfo = nil;
   sum.pools= [NSMutableArray array];
   sum.uuid= [Service createUUID];
   
   double amount_with_pools= 0.0;
   
   if (precedingYear)
   {
      sum.days_per_year = precedingYear.days_per_year;
      sum.amount_remain = precedingYear.days_per_year;
      
      amount_with_pools+= precedingYear.days_per_year.doubleValue;
   }
   else
   {
      sum.days_per_year = [NSNumber numberWithInt:0];
      sum.amount_remain = [NSNumber numberWithInt:0];
   }

   if (precedingYear && [[precedingYear year] intValue] == aYear-1)
   {
      // also add residual leave, if this is the following year
      
      Pool* pool= [Storage poolOfArray:sum.pools withInternalName:@"residualleave"];
      CategoryRef* cat= [Storage categoryForInternalName:@"residualleave" ofUser:[SessionManager activeUser]];
      
      if (!pool && cat)
      {
         pool = [[[Pool alloc] init] autorelease];
         [sum.pools addObject:pool];
         
         pool.pool= precedingYear.amount_remain_with_pools;
         pool.spent= [NSNumber numberWithDouble:0.0];
         pool.expired= [NSNumber numberWithDouble:0.0];
         pool.remain= precedingYear.amount_remain_with_pools;
         pool.year= [NSNumber numberWithInt:aYear];
         pool.earned = [NSNumber numberWithDouble:0.0];
         pool.category= cat.name;
         pool.internalName= @"residualleave";
         
         amount_with_pools+= [precedingYear.amount_remain_with_pools doubleValue];
      }
   }
   
   sum.amount_spent = [NSNumber numberWithInt:0];
   sum.amount_with_pools = [NSNumber numberWithInt:amount_with_pools];
   
   int index= 0;

   for (YearSummary* aSum in [SessionManager activeUser].years)
   {
      if (aSum.year.intValue < sum.year.intValue)
         index++;
      else
         break;
   }
   
   [[SessionManager activeUser].years insertObject:sum atIndex:index];
   
   [[NSNotificationCenter defaultCenter] postNotificationName:kInsertedNotification object:self];
   
   return sum;
}

// ************************************************************
// saveLeave
// ************************************************************

-(void)saveYear:(YearSummary *)year completion:(void (^)(BOOL))completionHandler
{
   User* owner= [[Storage currentStorage] userWithUUid:year.userid];
   
   if (!owner)
   {
      NSLog(@"Unknown owner '%@' - can't save leave", year.userid);
      return;
   }
   
   [owner saveDocument:^(BOOL success)
    {
       if (!success)
          [Service alert:NSLocalizedString(@"Error", nil) withText:NSLocalizedString(@"Failed to save data", nil) andError:nil forController:nil completion:nil];
       
       if (completionHandler)
          completionHandler(success);
    }];
}

// ************************************************************
// deleteYear
// ************************************************************

-(void)deleteYear:(YearSummary*)sum completion:(void (^)(BOOL success))completionHandler
{
   User* owner= [[Storage currentStorage] userWithUUid:sum.userid];
   
   if (!owner)
   {
      NSLog(@"Unknown owner '%@' - can't save leave", sum.userid);
      
      if (completionHandler)
         completionHandler(NO);
      
      return;
   }
   
   NSUInteger index= [owner.years indexOfObject:sum];
   
   if (index == NSNotFound)
   {
      NSLog(@"Leave '%@' not found for user '%@' - can't delete/update leave", sum.year, owner.name);
      
      if (completionHandler)
         completionHandler(NO);
      
      return;
   }

   int leaveYear= sum.year.intValue;
   
   // delete associated leave entries

   [owner.leave filterUsingPredicate:[NSPredicate predicateWithBlock:^BOOL(id obj, NSDictionary* bindings)
                                      {
                                         LeaveInfo* ifo= (LeaveInfo*)obj;
                                         return ifo.year.intValue != leaveYear;
                                      }]];
   
   // delete year itself

   [owner.years removeObjectAtIndex:index];
   
   // save & recalculate stuff
   
   [owner saveDocument:^(BOOL success)
    {
       [Calculation recalculateYear:leaveYear+1 withLastYearRemain:0.0 setRemain:NO completion:^(BOOL success)
        {
           [[NSNotificationCenter defaultCenter] postNotificationName:kDeletedNotification object:self];
           
           if (completionHandler)
              completionHandler(success);
        }];
    }];
}

static NSArray* yearNumberList= nil;

// *****************************************
// get year list
// *****************************************

+(NSArray*)getYearNumberList
{
   if (!yearNumberList)
   {
      NSMutableArray* array= [NSMutableArray array];
      
      for (int i = 1970; i < 2051; i++)
         [array addObject:[NSString stringWithFormat:@"%d", i]];
      
      yearNumberList= [[NSArray alloc] initWithArray:array];
   }
   
   return yearNumberList;
}

#pragma mark - Category

// ************************************************************
// createCategory
// ************************************************************

+(CategoryRef*)createCategory:(User*)owner
{
   CategoryRef* res= [[[CategoryRef alloc] init] autorelease];
   
   res.userid= owner.uuid;
 
   [owner.categories addObject:res];
   
   return res;
}

// ************************************************************
// categoryForName
// ************************************************************

+(CategoryRef*)categoryForName:(NSString*)name ofUser:(User*)owner
{
   if (!name)
      return nil;
   
   for (CategoryRef* cat in owner.categories)
      if ([cat.name isEqualToString:name])
         return cat;
   
   return nil;
}

// ************************************************************
// categoryForInternalName
// ************************************************************

+(CategoryRef*)categoryForInternalName:(NSString*)name ofUser:(User*)owner
{
   if (!name)
      return nil;

   for (CategoryRef* cat in owner.categories)
      if ([cat.internalName isEqualToString:name])
         return cat;
   
   return nil;
}

// ************************************************************
// deleteCategory
// ************************************************************

+(void)deleteCategory:(CategoryRef*)cat completion:(void (^)(BOOL success))completionHandler
{
   User* owner= [[Storage currentStorage] userWithUUid:cat.userid];
   
   if (!owner)
   {
      NSLog(@"FATAL: Cannot delete category info for non-existent owner '%@'", cat.userid);
      return;
   }
   
   [owner.categories removeObject:cat];
   
   if (completionHandler)
   {
      [owner saveDocument:^(BOOL success)
       {
          completionHandler(success);
       }];
   }   
}

// ************************************************************
// createDefaultCategories
// ************************************************************

+(void)createDefaultCategories:(User*)owner
{
   bool needSickleave= true;
   bool needOvertime= true;
   bool needResidualLeave= true;
   bool needSpecialLeave= true;
   CategoryRef* cat= nil;

   for (CategoryRef* c in owner.categories)
   {
      if ([c.internalName isEqualToString:@"sickleave"])
         needSickleave= false;
      
      else if ([c.internalName isEqualToString:@"overtime"])
         needOvertime= false;
      
      else if ([c.internalName isEqualToString:@"residualleave"])
         needResidualLeave= false;
      
      else if ([c.internalName isEqualToString:@"specialleave"])
         needSpecialLeave= false;
   }
   
   if (needSickleave)
   {
      // create initial categories, if necessary
      
      cat= [Storage createCategory:owner];
      cat.deletable = [NSNumber numberWithInt:0];
      cat.affectCalculation = [NSNumber numberWithInt:0];
      cat.name = NSLocalizedString(@"Sick leave", nil);
      cat.internalName = @"sickleave";
      cat.sumMonthly = [NSNumber numberWithInt:0];
      cat.color = [Service stringColor:RGB(129, 78, 78)];
      cat.inssp = [NSDate date];
      cat.savedAsHours = [NSNumber numberWithInt:0];
      cat.userid= owner.uuid;
      cat.honorFreeDays= [NSNumber numberWithBool:NO];
   }
   
   if (needOvertime)
   {
      // create initial categories, if necessary
      
      cat= [Storage createCategory:owner];
      cat.deletable = [NSNumber numberWithInt:0];
      cat.affectCalculation = [NSNumber numberWithInt:0];
      cat.name = NSLocalizedString(@"Overtime", nil);
      cat.internalName = @"overtime";
      cat.sumMonthly = [NSNumber numberWithInt:1];
      cat.color = [Service stringColor:RGB(78, 129, 90)];
      cat.inssp = [NSDate date];
      cat.savedAsHours = [NSNumber numberWithInt:1];
      cat.userid= owner.uuid;
      cat.honorFreeDays= [NSNumber numberWithBool:YES];
   }
   
   if (needResidualLeave)
   {
      // create initial categories, if necessary
      
      cat= [Storage createCategory:owner];
      cat.deletable = [NSNumber numberWithInt:0];
      cat.affectCalculation = [NSNumber numberWithInt:1];
      cat.name = NSLocalizedString(@"Residual leave", nil);
      cat.internalName = @"residualleave";
      cat.sumMonthly = [NSNumber numberWithInt:0];
      cat.color = [Service stringColor:RGB(0, 0, 0)];
      cat.inssp = [NSDate date];
      cat.savedAsHours = [NSNumber numberWithInt:0];
      cat.userid= owner.uuid;
      cat.honorFreeDays= [NSNumber numberWithBool:YES];
   }
   
   if (needSpecialLeave)
   {
      // create initial categories, if necessary
      
      cat= [Storage createCategory:owner];
      cat.deletable = [NSNumber numberWithInt:0];
      cat.affectCalculation = [NSNumber numberWithInt:1];
      cat.name = NSLocalizedString(@"Special leave", nil);
      cat.internalName = @"specialleave";
      cat.sumMonthly = [NSNumber numberWithInt:0];
      cat.color = [Service stringColor:RGB(0, 0, 0)];
      cat.inssp = [NSDate date];
      cat.savedAsHours = [NSNumber numberWithInt:0];
      cat.userid= owner.uuid;
      cat.honorFreeDays= [NSNumber numberWithBool:YES];
   }
}

#pragma mark - Timetable

// ************************************************************
// createCategory
// ************************************************************

+(Timetable*)createTimetable:(User*)owner
{
   Timetable* res= [[[Timetable alloc] init] autorelease];
   
   res.uuid= [Service createUUID];
   res.userid= owner.uuid;
   
   [owner.timetables addObject:res];
   
   return res;
}

// ************************************************************
// createDefaultTimetables
// ************************************************************

+(void)createDefaultTimetables:(User*)owner
{
   if (owner.timetables.count)
      return;

   // create initial categories, if necessary
      
   Timetable* timeTable= [Storage createTimetable:owner];
      
   timeTable.name = NSLocalizedString(@"Default timetable", nil);
   timeTable.hours_total = [NSNumber numberWithDouble:40.0];
   timeTable.internalname = @"default";
   timeTable.day_0 = [NSNumber numberWithDouble:0.0];
   timeTable.day_1 = [NSNumber numberWithDouble:8.0];
   timeTable.day_2 = [NSNumber numberWithDouble:8.0];
   timeTable.day_3 = [NSNumber numberWithDouble:8.0];
   timeTable.day_4 = [NSNumber numberWithDouble:8.0];
   timeTable.day_5 = [NSNumber numberWithDouble:8.0];
   timeTable.day_6 = [NSNumber numberWithDouble:0.0];
}

// ************************************************************
// getTimeTable
// ************************************************************

+(Timetable*)getTimeTable:(NSString*)uuid
{
   for (User* user in [[Storage currentStorage] userList])
   {
      for (Timetable* tt in user.timetables)
         if ([tt.uuid isEqualToString:uuid])
            return tt;
   }
   
   return nil;
}

// ************************************************************
// getTimeTableForInternalName
// ************************************************************

+(Timetable*)getTimeTableForInternalName:(NSString*)internalName orName:(NSString*)name;
{
   for (User* user in [[Storage currentStorage] userList])
   {
      for (Timetable* tt in user.timetables)
         if ([tt.internalname isEqualToString:internalName])
            return tt;
   }

   for (User* user in [[Storage currentStorage] userList])
   {
      for (Timetable* tt in user.timetables)
         if ([tt.name isEqualToString:name])
            return tt;
   }

   return nil;
}

// ************************************************************
// saveTimetable
// ************************************************************

+(void)saveTimetable:(Timetable*)tt completion:(void (^)(BOOL success))completionHandler
{
   User* owner= [[Storage currentStorage] userWithUUid:tt.userid];
   
   if (!owner)
   {
      NSLog(@"Unknown owner '%@' - can't save timetable", tt.userid);
      return;
   }
   
   [owner saveDocument:^(BOOL success)
    {
       if (completionHandler)
          completionHandler(success);
    }];
}

// ************************************************************
// deleteTimetable
// ************************************************************

+(void)deleteTimetable:(Timetable*)timetable completion:(void (^)(BOOL success))completionHandler
{
   User* owner= [[Storage currentStorage] userWithUUid:timetable.userid];
   
   if (!owner)
   {
      NSLog(@"FATAL: Cannot delete category info for non-existent owner '%@'", timetable.userid);
      return;
   }
   
   [owner.timetables removeObject:timetable];
   
   if (completionHandler)
   {
      [owner saveDocument:^(BOOL success)
       {
          completionHandler(success);
       }];
   }
}

#pragma mark - Freeday

//************************************************************
// freedays

+(Freeday*)createFreeday:(User*)owner
{
   Freeday* res= [[[Freeday alloc] init] autorelease];
   
   res.uuid= [Service createUUID];
   res.userid= owner.uuid;
   res.title = nil;
   
   [owner.freedays addObject:res];
   
   return res;
}

+(Freeday*)getFreeday:(NSString*)uuid
{
   for (User* user in [[Storage currentStorage] userList])
   {
      for (Freeday* fd in user.freedays)
         if ([fd.uuid isEqualToString:uuid])
            return fd;
   }
   
   return nil;
}

+(void)saveFreeday:(Freeday*)freeday completion:(void (^)(BOOL success))completionHandler
{
   User* owner= [[Storage currentStorage] userWithUUid:freeday.userid];
   
   if (!owner)
   {
      NSLog(@"Unknown owner '%@' - can't save freeday", freeday.userid);
      return;
   }
   
   [owner saveDocument:^(BOOL success)
    {
      [Storage rebuildFreedaysList];

       if (completionHandler)
          completionHandler(success);
    }];
}

+(void)deleteFreeday:(Freeday*)freeday completion:(void (^)(BOOL success))completionHandler
{
   User* owner= [[Storage currentStorage] userWithUUid:freeday.userid];
   
   if (!owner)
   {
      NSLog(@"FATAL: Cannot delete category info for non-existent owner '%@'", freeday.userid);
      return;
   }
   
   [owner.freedays removeObject:freeday];
   
   if (completionHandler)
   {
      [owner saveDocument:^(BOOL success)
       {
         [Storage rebuildFreedaysList];
          completionHandler(success);
       }];
   }
}

+(void)rebuildFreedaysList
{
   [freedays removeAllObjects];
   
   [[NSNotificationCenter defaultCenter] postNotificationName:kPublicHolidayEntriesLoaded object:self];
   
   for (Freeday* day in [SessionManager activeUser].freedays)
   {
      NSString* key = [NSString stringWithFormat:@"%d%d", day.day.intValue, day.month.intValue];
      [freedays setObject:day forKey:key];
   }
}

+(NSDictionary*)freedaysList
{
   return freedays;
}

#pragma mark - LeaveInfo

// ************************************************************
// getLeaveInfoWithUUID
// ************************************************************

-(LeaveInfo*)getLeaveInfoWithUUID:(NSString*)leaveId
{
   for (User* user in self.userList)
   {
      for (LeaveInfo* ifo in user.leave)
         if ([ifo.uuid isEqualToString:leaveId])
            return ifo;
   }
   
   return nil;
}

// ************************************************************
// createLeaveForOwnerUUID
// ************************************************************

-(LeaveInfo*)createLeaveForOwnerUUID:(NSString*)uuid
{
   User* owner= [[Storage currentStorage] userWithUUid:uuid];
   
   if (!owner)
   {
      NSLog(@"Unknown owner '%@' - can't save leave", uuid);
      return nil;
   }
   
   return [self createLeaveForOwner:owner];
}

// ************************************************************
// createLeaveForOwner
// ************************************************************

-(LeaveInfo*)createLeaveForOwner:(User*)owner
{
   LeaveInfo* info= [[LeaveInfo alloc] init];
   info.options= [NSData data];
   
   [owner.leave addObject:info];
   
   [info release];
   
   info.uuid= [Service createUUID];
   
   return info;
}

// ************************************************************
// saveLeave
// ************************************************************

+(void)saveLeave:(LeaveInfo*)info completion:(void (^)(BOOL success))completionHandler
{
   User* owner= [[Storage currentStorage] userWithUUid:info.userid];
   
   if (!owner)
   {
      NSLog(@"Unknown owner '%@' - can't save leave", info.userid);
      return;
   }
   
   int beginYear = info.begin ? (int)info.year.integerValue : na;
   int endYear = info.end ? [Service getLeaveYearForDate:info.end] : na;
   
   // add years, if they don't already exist.
   
   if (beginYear != na)
      [[Storage currentStorage] createYearSummary:beginYear];

   if (endYear != na && endYear != beginYear)
      [[Storage currentStorage] createYearSummary:endYear];
   
   // also add following year, so that residual leave will always be calculated correctly.
   
   if (beginYear != na || endYear != na)
      [[Storage currentStorage] createYearSummary:endYear != na ? endYear+1 : beginYear+1];
   
//   [owner saveDocument:^(BOOL success)
//    {
       [Calculation recalculateYear:beginYear withLastYearRemain:0.0 setRemain:false completion:^(BOOL success)
        {
           [[NSNotificationCenter defaultCenter] postNotificationName:kLeaveChanged object:self];

           if (completionHandler)
              completionHandler(success);
        }];
//    }];
}

// ************************************************************
// saveLeaveInCalendar
// ************************************************************

+(void)saveLeaveInCalendar:(LeaveInfo*)info
{
   // also store in user calendar, if configured
   
   if ([Settings userSettingInt:skStoreInCalendar])
      [info saveInCalendar:[NSArray arrayWithObject:[EventService storageCalendar]] store:[EventService eventStore]];
}

// ************************************************************
// deleteLeaveFromCalendar
// ************************************************************

+(void)deleteLeaveFromCalendar:(LeaveInfo*)info
{
   // remove from calendar, if configured
   
   if ([Settings userSettingInt:skStoreInCalendar])
      [info deleteFromCalendar:[NSArray arrayWithObject:[EventService storageCalendar]] store:[EventService eventStore]];
}

// ************************************************************
// deleteLeave
// ************************************************************

-(void)deleteLeave:(LeaveInfo*)info completion:(void (^)(BOOL success))completionHandler
{
   User* owner= [[Storage currentStorage] userWithUUid:info.userid];
   
   if (!owner)
   {
      NSLog(@"Unknown owner '%@' - can't save leave", info.userid);
      
      if (completionHandler)
         completionHandler(NO);
      
      return;
   }

   NSUInteger index= [owner.leave indexOfObject:info];
   
   if (index == NSNotFound)
   {
      NSLog(@"Leave '%@' not found for user '%@' - can't delete/update leave", info.title, owner.name);
      
      if (completionHandler)
         completionHandler(NO);
      
      return;
   }
   
   if ([Settings userSettingInt:skStoreInCalendar])
      [info deleteFromCalendar:[NSArray arrayWithObject:[EventService storageCalendar]] store:[EventService eventStore]];
   
   [owner.leave removeObjectAtIndex:index];
   
   [owner saveDocument:^(BOOL success) {
      completionHandler(success);
      
      int theYear= [info.year intValue];
      
      [Calculation recalculateYear:theYear withLastYearRemain:0.0 setRemain:false completion:^(BOOL success)
       {
          [[NSNotificationCenter defaultCenter] postNotificationName:kLeaveChanged object:self];
          
          if (completionHandler)
             completionHandler(success);
       }];
   }];
}

// *****************************************
// getLeaveForMonth
// *****************************************

-(double)getLeaveForMonth:(int)month inYear:(int)year
{
   double total= 0;
   
   User* user= [[Storage currentStorage] userWithUUid:[SessionManager activeUser].uuid];

   if (!user)
      return total;
   
   for (LeaveInfo* info in user.leave)
   {
      int beginYear = info.begin ? (int)[[NSCalendar currentCalendar] component:NSCalendarUnitYear fromDate:info.begin] : na;
      int endYear = info.end ? (int)[[NSCalendar currentCalendar] component:NSCalendarUnitYear fromDate:info.end] : na;

      if (beginYear != year && endYear != year)
         continue;
      
      CategoryRef* c= [Storage categoryForName:info.category ofUser:[[Storage currentStorage] userWithUUid:info.userid]];
      
      bool needsHourInput;
      
      if (c)
         needsHourInput= [c.savedAsHours boolValue];
      else
         needsHourInput= [Settings userSettingInt:skUnit];
      
      bool honorsFreeDays= c ? [c.honorFreeDays boolValue] : YES;
      bool affectsCalc= c ? [c.affectCalculation boolValue] : YES;

      if (affectsCalc && info.mode.integerValue == lmSpend)
         total += [Calculation calculateLeaveDuration:info.begin
                                                  _in:info.end
                                                  _in:info.begin_half_day.boolValue
                                                  _in:info.end_half_day.boolValue
                                                  _in:needsHourInput
                                                  _in:honorsFreeDays
                                                  _in:user.timetables
                                                  _in:month
                                                  _in:year];
   }
   
   return total;
}

// *****************************************
//  getLeaveForUsers
// *****************************************

-(NSArray*)getLeaveForUsers:(NSArray*)userIds withFilter:(NSPredicate*)predicate andSorting:(NSArray*)sortDescriptors
{
   NSMutableArray* tmp= [NSMutableArray array];
   
   for (NSString* uuid in userIds)
   {
      User* user= [[Storage currentStorage] userWithUUid:uuid];
      
      if (!user)
         continue;
      
      [tmp addObjectsFromArray:user.leave];
   }
   
   if (predicate && sortDescriptors)
      return [[tmp filteredArrayUsingPredicate:predicate] sortedArrayUsingDescriptors:sortDescriptors];
   
   if (predicate)
      return [tmp filteredArrayUsingPredicate:predicate];
   
   if (sortDescriptors)
      return [tmp sortedArrayUsingDescriptors:sortDescriptors];
   
   return [[tmp copy] autorelease];
}

#pragma mark - Pool

// *****************************************
// poolOfArray
// *****************************************

+(Pool*) poolOfArray:(NSArray*)pools withInternalName:(NSString*)name
{
   if (!pools || ![pools count] || !name || ![name length])
      return nil;
   
   Pool* pool= nil;
   
   for (int i= 0; i < [pools count]; i++)
   {
      pool= (Pool*)[pools objectAtIndex:i];
      
      if ([pool.internalName isEqualToString:name])
         return pool;
   }
   
   return nil;
}

// *****************************************
// poolOfArray year
// *****************************************

+(Pool*)poolOfArray:(NSArray*)pools withName:(NSString*)name
{
   if (!pools || ![pools count] || !name || ![name length])
      return nil;
   
   Pool* pool= nil;
   
   for (int i= 0; i < [pools count]; i++)
   {
      pool= (Pool*)[pools objectAtIndex:i];
      
      if ([pool.category isEqualToString:name])
         return pool;
   }
   
   return nil;
}

// *****************************************
// createPool
// *****************************************

-(Pool*)createPool:(YearSummary*)year withCategory:(CategoryRef*)category
{
   Pool* pool= [[Pool alloc] init];
   
   pool.pool= [NSNumber numberWithDouble:0.0];
   pool.spent= [NSNumber numberWithDouble:0.0];
   pool.expired= [NSNumber numberWithDouble:0.0];
   pool.remain=  [NSNumber numberWithDouble:0.0];
   pool.earned=  [NSNumber numberWithDouble:0.0];
   pool.year= year.year;
   pool.category= category.name;
   pool.internalName= category.internalName;
   pool.yearId= year.uuid;
   
   [year.pools addObject:pool];
   
   return pool;
}

// *****************************************
// createPool
// *****************************************

-(void)createPool:(YearSummary*)year withCategory:(CategoryRef*)category completion:(void (^)(BOOL success, Pool* newPool))completionHandler
{
   Pool* pool= [self createPool:year withCategory:category];
   
   [self saveYear:year completion:^(BOOL success)
    {
       if (completionHandler)
          completionHandler(success, pool);
    }];
}

// *****************************************
// deletePool
// *****************************************

-(void)deletePool:(Pool*)pool completion:(void (^)(BOOL success))completionHandler
{
   NSPredicate* pred= [NSPredicate predicateWithFormat:@"uuid == %@", pool.yearId];
   NSArray* res= nil;
   
   for (User* user in self.userList)
   {
      res= [user.leave filteredArrayUsingPredicate:pred];
      
      if (res && res.count == 1)
      {
         YearSummary* sum= res.firstObject;
         NSUInteger index= [sum.pools indexOfObject:pool];
         
         if (index == NSNotFound)
         {
            NSLog(@"Pool '%@' not found for year (%@) of user '%@' - can't delete/update leave", pool.category, sum.year, user.name);
            
            if (completionHandler)
               completionHandler(NO);
            
            return;
         }
         
         [sum.pools removeObjectAtIndex:index];
         
         if (completionHandler)
            [self saveYear:sum completion:^(BOOL success) { completionHandler(success); }];
      }
   }
}

@end

// ************************************************************
// class ALDocument
// ************************************************************

#pragma mark - Class ALDocument

@implementation ALDocument

// ************************************************************
// handleError
// ************************************************************

- (void)handleError:(NSError *)error userInteractionPermitted:(BOOL)userInteractionPermitted
{
   NSLog(@"Error: '%@' ('%@')", error.localizedDescription, error.userInfo);
   [super handleError:error userInteractionPermitted:userInteractionPermitted];
}

//************************************************************
// save document
//************************************************************

-(void)saveDocument:(void (^)(BOOL success))completionHandler
{
   NSLog(@"SAVING DOCUMENT %@", self.fileURL);

   [self saveToURL:self.fileURL forSaveOperation:UIDocumentSaveForOverwriting completionHandler:^(BOOL success)
    {
       if (!success)
          [Service alert:NSLocalizedString(@"Error", nil) withText:[NSString stringWithFormat:@"Failed to save url '%@'", self.fileURL.path] andError:nil forController:nil completion:nil];
       
       if (completionHandler)
          completionHandler(success);
    }];
}
@end

#pragma mark - Class ALObject

//************************************************************
// class ALObject
//************************************************************

@implementation ALObject

//************************************************************
// loadFromDictionary
//************************************************************

-(void)loadFromDictionary:(NSDictionary*)dict
{
   [dict enumerateKeysAndObjectsUsingBlock:^(id key, id obj, BOOL *stop)
    {
       if([obj respondsToSelector:NSSelectorFromString(key)])
          [self setValue:obj forKey:(NSString*)key];
    }];
}

//************************************************************
// saveToDictionary
//************************************************************

-(NSDictionary*)saveToDictionary
{
   NSMutableDictionary* dict = [NSMutableDictionary dictionary];
   
   unsigned count= 0;
   objc_property_t* properties = class_copyPropertyList([self class], &count);
   
   for (int i = 0; i < count; i++)
   {
      NSString *key = [NSString stringWithUTF8String:property_getName(properties[i])];
      id obj= [self valueForKey:key];
      
      if (obj)
         [dict setObject:obj forKey:key];
   }
   
   free(properties);
   
   return dict;
}

@end
