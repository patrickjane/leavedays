//************************************************************
// BackupImporter.m
// Holiday
//************************************************************
// Created by Patrick Fial on 04.09.2015
// Copyright 2015-2015 Patrick Fial. All rights reserved.
//************************************************************

//************************************************************
// includes
//************************************************************

#import "BackupImporter.h"
#import "Crypt.h"
#import "Service.h"
#import "Settings.h"
#import "SessionManager.h"
#import "YearSummary.h"
#import "AppDelegate.h"

#import "User.h"
#import "YearSummary.h"
#import "LeaveInfo.h"
#import "Category.h"
#import "Pool.h"
#import "Timetable.h"

//************************************************************
// class BackupImporter
//************************************************************

@implementation BackupImporter

@synthesize importCategories, importLeaveInfos, importPools;
@synthesize importTimetables, importUsers, importYears, importedUserNames, completionBlock;
@synthesize savableUsers;

//************************************************************
// init
//************************************************************

-(id)init
{
   self= [super init];
   
   if (self)
   {
      self.completionBlock= nil;
      self.importedUserNames= [NSMutableArray array];
      self.importUsers= [NSMutableArray array];
      self.importYears= [NSMutableArray array];
      self.importPools= [NSMutableArray array];
      self.importLeaveInfos= [NSMutableArray array];
      self.importCategories= [NSMutableArray array];
      self.importTimetables= [NSMutableArray array];
      self.savableUsers= [NSMutableArray array];
      
      self.dateFormatter= [[[NSDateFormatter alloc] init] autorelease];
      [self.dateFormatter setDateFormat:@"yyyy-MM-dd HH:mm:ss ZZZ"];
      
   }
   
   return self;
}

//************************************************************
// dealloc
//************************************************************

-(void)dealloc
{
   self.importUsers= nil;
   self.importYears= nil;
   self.importPools= nil;
   self.importLeaveInfos= nil;
   self.importCategories= nil;
   self.importTimetables= nil;
   self.dateFormatter= nil;
   self.completionBlock= nil;

   [super dealloc];
}

//************************************************************
// import File
//************************************************************

-(void)importFile:(NSURL*)aUrl completion:(void (^)(BOOL success))completionHandler
{
   self.completionBlock = completionHandler;
   
   if ([aUrl.pathExtension isEqualToString:@"alb"])
   {
      NSError *error = nil;
      NSFileCoordinator* coordinator= [[[NSFileCoordinator alloc] initWithFilePresenter:nil] autorelease];
      
      [coordinator coordinateReadingItemAtURL:aUrl options:0 error:&error byAccessor:^(NSURL* newURL)
       {
          UIViewController* rvc= [UIApplication sharedApplication].delegate.window.rootViewController;
          NSData* rawData= nil;
          
          rawData= [NSData dataWithContentsOfURL:newURL];
          
          if (!rawData || error)
          {
             [Service alert:NSLocalizedString(@"Error", nil) withText:NSLocalizedString(@"Failed to load data from storage", nil) andError:error forController:rvc completion:nil];
             return;
          }
          
          NSString* base64Encoded = [[[NSString alloc] initWithData:rawData encoding:NSUTF8StringEncoding] autorelease];
          NSData* plainData= [NSData dataFromBase64String:base64Encoded];
          NSString* plainString= [[[NSString alloc] initWithData:plainData encoding:NSUTF8StringEncoding] autorelease];
          
          parser= [[CHCSVParser alloc] initWithCSVString:plainString];
          parser.delegate= self;
          parser.sanitizesFields = YES;
          
          if (error)
          {
             [Service alert:NSLocalizedString(@"Error", nil) withText:NSLocalizedString(@"Import failed", nil) andError:error forController:rvc completion:nil];
             return;
          }
          
          [parser parse];
          
       }];
   }
   else if ([aUrl.pathExtension isEqualToString:@"alb2"])
   {
      NSLog(@"Import alb v2 backup");
      
      UIViewController* rvc= [UIApplication sharedApplication].delegate.window.rootViewController;
      
      User* user= [[User alloc] initWithFileURL:aUrl];
      
      [user openWithCompletionHandler:^(BOOL success)
       {
          if (!success)
          {
             [Service alert:NSLocalizedString(@"Error", nil) withText:NSLocalizedString(@"Backup could not be opened", nil) andError:nil forController:rvc completion:nil];
             return;
          }
          
          NSString* fileName= [NSString stringWithFormat:@"%@.user", user.uuid];
          NSURL* url= [((AppDelegate*)[UIApplication sharedApplication].delegate).applicationDocumentsDirectory URLByAppendingPathComponent:fileName];
          
          if (![Settings globalSettingBool:skSingleUser] && [[NSFileManager defaultManager] fileExistsAtPath:url.path isDirectory:nil])
          {
             [Service alert:NSLocalizedString(@"Error", nil) withText:NSLocalizedString(@"Backup could not be imported. Same user already exists.", nil) andError:nil forController:rvc completion:nil];
          }
          else
          {
             NSLog(@"Saving imported user to new url %@", url);
             
             // make it the new single user
             
             void (^onCompletion)(BOOL) = ^(BOOL success)
             {
                NSLog(@"DONE saving imported user to new url %@ (success: %d)", url, success);
                
                [user closeWithCompletionHandler:nil];
                [user autorelease];
                
                if (!success)
                   [Service alert:NSLocalizedString(@"Error", nil) withText:NSLocalizedString(@"Backup could not be imported.", nil) andError:nil forController:rvc completion:nil];
                else
                {
                   [[Storage currentStorage] initUser:url completion:^(BOOL success) {
                      if ([Settings globalSettingBool:skSingleUser])
                         [[SessionManager session] logout];
                      
                      [Service message:NSLocalizedString(@"Info", nil) withText:NSLocalizedString(@"Successfully imported user.", nil) forController:rvc completion:nil];
                   }];
                }
             };
             
             if ([Settings globalSettingBool:skSingleUser])
             {
                user.isSingleUser= YES;
                
                [[Storage currentStorage] wipeData:NO /* dont re-create singleuser */ completionHandler:^(BOOL success)
                 {
                    [user saveToURL:url forSaveOperation:UIDocumentSaveForCreating completionHandler:onCompletion];
                 }];
             }
             else
             {
                [user saveToURL:url forSaveOperation:UIDocumentSaveForCreating completionHandler:onCompletion];
             }
          }
       }];
   }
   
   return;
   
}

// ************************************************************
// toMode
// ************************************************************

-(int)toMode:(NSString*)field
{
   static NSString* delimUser= @"@USER";
   static NSString* delimPool= @"@POOL";
   static NSString* delimYear= @"@YEAR";
   static NSString* delimLeave= @"@LEAVE";
   static NSString* delimTimetable= @"@TIMETABLE";
   static NSString* delimCategory= @"@CATEGORY";
   
   if (!field || !field.length)
      return lmUnknown;
   
   if ([field isEqualToString:@"R"])
      return lmRecord;
   
   if ([field isEqualToString:delimUser])
      return lmUser;
   
   if ([field isEqualToString:delimPool])
      return lmPool;
   
   if ([field isEqualToString:delimYear])
      return lmYear;
   
   if ([field isEqualToString:delimLeave])
      return lmLeave;
   
   if ([field isEqualToString:delimTimetable])
      return lmTimetable;
   
   if ([field isEqualToString:delimCategory])
      return lmCategory;
   
   return lmUnknown;
}

#pragma mark - CSV parser callbacks

// ************************************************************
// didStartDocument
// ************************************************************

- (void)parserDidBeginDocument:(CHCSVParser *)aParser
{
   lastUser= nil;
   lastCategory= nil;
   lastPool= nil;
   lastLeave= nil;
   lastYear= nil;
   lastTimetable= nil;
   
   lastIndex= -1;
   lastMode= lmUnknown;
   isHeaderRow= -1;
   err= 0;
}

// ************************************************************
// didStartLine
// ************************************************************

- (void)parser:(CHCSVParser *)aParser didBeginLine:(NSUInteger)recordNumber
{
   lastIndex= -1;
   isHeaderRow= 0;
}

// ************************************************************
// didReadField
// ************************************************************

- (void)parser:(CHCSVParser *)aParser didReadField:(NSString *)field atIndex:(NSInteger)fieldIndex
{
   lastIndex++;
   
   if (!lastIndex)
   {
      int aMode= [self toMode:field];
      
      isHeaderRow= aMode != lmRecord;
      lastMode= isHeaderRow ? aMode : lastMode;
   }
   
   if (isHeaderRow == 1)
      return;
   
   switch (lastMode)
   {
      case lmUser:
      {
         switch (lastIndex)
         {
            case 1: lastUser= [[Storage currentStorage] createEmptyUser]; lastUser.availableUsers= [[field copy] autorelease]; break;
            case 2: lastUser.color=    [[field copy] autorelease];  break;
            case 3: lastUser.name=     [[field copy] autorelease];  break;
            case 4: lastUser.password= [[field copy] autorelease];  break;
            case 5: lastUser.rights=   [NSNumber numberWithInt:field.intValue];  break;
            case 6: break; // settings
            case 7: break; // userinfo
            case 8: lastUser.uuid=     [[field copy] autorelease]; [self.importUsers addObject:lastUser]; break;
            default: return;
         }

         break;
      }
      case lmYear:
      {
         switch (lastIndex)
         {
            case 1: lastYear= [[YearSummary alloc] init]; lastYear.amount_remain= [NSNumber numberWithDouble:field.doubleValue]; lastYear.pools= [NSMutableArray array]; break;
            case 2: lastYear.amount_remain_with_pools= [NSNumber numberWithDouble:field.doubleValue]; break;
            case 3: lastYear.amount_spent=             [NSNumber numberWithDouble:field.doubleValue]; break;
            case 4: lastYear.amount_spent_with_pools=  [NSNumber numberWithDouble:field.doubleValue]; break;
            case 5: lastYear.amount_with_pools=        [NSNumber numberWithDouble:field.doubleValue]; break;
            case 6: lastYear.days_per_year=            [NSNumber numberWithDouble:field.doubleValue]; break;
            case 7: lastYear.remain_expiration=        [self.dateFormatter dateFromString:field]; break;
            case 8: break; // userinfo
            case 9: lastYear.userid=                   [[field copy] autorelease];  break;
            case 10:lastYear.year=                     [NSNumber numberWithInt:field.intValue]; [self.importYears addObject:lastYear]; break;
         }

         break;
      }
      case lmCategory:
      {
         switch (lastIndex)
         {
            case 1: lastCategory= [[CategoryRef alloc] init]; lastCategory.affectCalculation= [NSNumber numberWithInt:field.intValue]; break;
            case 2: lastCategory.color=        [[field copy] autorelease];  break;
            case 3: lastCategory.deletable=    [NSNumber numberWithInt:field.intValue]; break;
            case 4: lastCategory.inssp=        [self.dateFormatter dateFromString:field]; break;
            case 5: lastCategory.internalName= [[field copy] autorelease];  break;
            case 6: lastCategory.name=         [[field copy] autorelease];  break;
            case 7: lastCategory.savedAsHours= [NSNumber numberWithInt:field.intValue]; break;
            case 8: lastCategory.sumMonthly=   [NSNumber numberWithInt:field.intValue]; [self.importCategories addObject:lastCategory]; lastCategory= nil;
            case 9: break; // userinfo
         }
         break;
      }
      case lmTimetable:
      {
         switch (lastIndex)
         {
            case 1: lastTimetable= [[Timetable alloc] init]; lastTimetable.day_0= [NSNumber numberWithDouble:field.doubleValue]; break;
            case 2: lastTimetable.day_1=        [NSNumber numberWithDouble:field.doubleValue]; break;
            case 3: lastTimetable.day_2=        [NSNumber numberWithDouble:field.doubleValue]; break;
            case 4: lastTimetable.day_3=        [NSNumber numberWithDouble:field.doubleValue]; break;
            case 5: lastTimetable.day_4=        [NSNumber numberWithDouble:field.doubleValue]; break;
            case 6: lastTimetable.day_5=        [NSNumber numberWithDouble:field.doubleValue]; break;
            case 7: lastTimetable.day_6=        [NSNumber numberWithDouble:field.doubleValue]; break;
            case 8: lastTimetable.hours_total=  [NSNumber numberWithDouble:field.doubleValue]; break;
            case 9: lastTimetable.internalname= [[field copy] autorelease]; break;
            case 10:lastTimetable.name=         [[field copy] autorelease]; break;
            case 11:lastTimetable.uuid=         [[field copy] autorelease]; [self.importTimetables addObject:lastTimetable]; lastTimetable= nil; break;
         }

         break;
      }
      case lmPool:
      {
         switch (lastIndex)
         {
            case 1: lastPool= [[Pool alloc] init]; lastPool.category= [[field copy] autorelease]; lastPool.earned= [NSNumber numberWithDouble:0.0]; break;
            case 2: lastPool.expired=      [NSNumber numberWithDouble:field.doubleValue]; break;
            case 3: lastPool.internalName= [[field copy] autorelease]; break;
            case 4: lastPool.pool=         [NSNumber numberWithDouble:field.doubleValue]; break;
            case 5: lastPool.remain=       [NSNumber numberWithDouble:field.doubleValue]; break;
            case 6: lastPool.spent=        [NSNumber numberWithDouble:field.doubleValue]; break;
            case 7: break; // userinfo
            case 8: lastPool.userid=       [[field copy] autorelease]; break;
            case 9: lastPool.year=         [NSNumber numberWithInt:field.intValue]; [self.importPools addObject:lastPool]; lastPool= nil; break;
            default: return;
         }
         
         break;
      }
      case lmLeave:
      {
         switch (lastIndex)
         {
            case 1: lastLeave= [[LeaveInfo alloc] init]; lastLeave.affectsCalculation= [NSNumber numberWithInt:field.intValue]; lastLeave.options= [NSData data]; break;
            case 2: lastLeave.begin=               [self.dateFormatter dateFromString:field]; break;
            case 3: lastLeave.begin_half_day=      [NSNumber numberWithInt:field.intValue]; break;
            case 4: lastLeave.calculateDuration=   [NSNumber numberWithInt:field.intValue]; break;
            case 5: lastLeave.category=            [[field copy] autorelease]; break;
            case 6: lastLeave.comment=             [[field copy] autorelease]; break;
            case 7: lastLeave.duration=            [NSNumber numberWithDouble:field.doubleValue]; break;
            case 8: lastLeave.end=                 [self.dateFormatter dateFromString:field]; break;
            case 9: lastLeave.end_half_day=        [NSNumber numberWithInt:field.intValue]; break;
            case 10:lastLeave.isUnknownDate=       [NSNumber numberWithInt:field.intValue]; break;
            case 11:lastLeave.location=            [NSJSONSerialization JSONObjectWithData:[field dataUsingEncoding:NSUTF8StringEncoding] options:0 error:nil]; break; // [[field copy] autorelease]; break;
            case 12:lastLeave.month=               [NSNumber numberWithInt:field.intValue]; break;
            case 13:lastLeave.savedAsHours=        [NSNumber numberWithInt:field.intValue]; break;
            case 14:lastLeave.status=              [NSNumber numberWithInt:field.intValue]; break;
            case 15:lastLeave.sumMonthly=          [NSNumber numberWithInt:field.intValue]; break;
            case 16:lastLeave.timeTable=           [[field copy] autorelease]; break;
            case 17:lastLeave.title=               [[field copy] autorelease]; break;
            case 18: break;  // userinfo
            case 19:lastLeave.userid=              [[field copy] autorelease]; break;
            case 20:lastLeave.uuid=                [[field copy] autorelease]; break;
            case 21:lastLeave.year=                [NSNumber numberWithInt:field.intValue]; break;
            case 22:lastLeave.monthNameOfBegin=    [[field copy] autorelease]; [importLeaveInfos addObject:lastLeave]; lastLeave= nil; break;
               
         }
         break;
      }
      default:
         return;
   }
   
   return;
}

// ************************************************************
// didEndDocument
// ************************************************************

- (void)parserDidEndDocument:(CHCSVParser *)aParser
{
   NSLog(@"Finished import with (%lu) users, (%lu) years, (%lu) categories, (%lu) timetables, (%lu) leave infos",
         (unsigned long)self.importUsers.count, (unsigned long)self.importYears.count, (unsigned long)self.importCategories.count, (unsigned long)self.importTimetables.count, (unsigned long)self.importLeaveInfos.count);
   
//   // block definition for recursive integration of users
//   
//   void (^__block importUserBlock)(BOOL success);
//
//   importUserBlock = ^(BOOL success)
//   {
//      if (!success)
//      {
//         NSLog(@"Aborting import due to internal failure");
//         return;
//      }
//      
//      User* firstUser= self.importUsers.firstObject;
//      
//      [self.importUsers removeObject:firstUser];
//      
//      if (firstUser)
//      {
//         NSLog(@"Integrating next user");
//         
//         [self.importUsers removeObject:firstUser];
//         [self integrateUser:firstUser completion:importUserBlock];
//      }
//      else
//         [self finalizeImport];
//   };

   // actually start integration
   
   if (self.importUsers.count == 1 && [Settings globalSettingBool:skSingleUser])
   {
      UIViewController* rvc= [UIApplication sharedApplication].delegate.window.rootViewController;
      UIAlertController* actionSheet= [UIAlertController alertControllerWithTitle:NSLocalizedString(@"Warning", nil) message:NSLocalizedString(@"In single user mode, already saved data will be overwritten by the import. Continue?", nil) preferredStyle:UIAlertControllerStyleActionSheet];
      
      [actionSheet addAction:[UIAlertAction actionWithTitle:NSLocalizedString(@"Continue", nil) style:UIAlertActionStyleDefault handler:^(UIAlertAction* action)
                              {
                                 User* firstUser= self.importUsers.firstObject;
                                 
                                 [self.importUsers removeObject:firstUser];

                                 if (firstUser)
                                 {
                                    [self mergeSingleUser:firstUser completion:^(BOOL success)
                                     {
                                        [self finalizeImport];
                                     }];
                                 }
                                 else
                                    [self finalizeImport];
                              }]];
      
      [actionSheet addAction:[UIAlertAction actionWithTitle:NSLocalizedString(@"Cancel", nil) style:UIAlertActionStyleCancel handler:nil]];
      
      [rvc presentViewController:actionSheet animated:YES completion:nil];
      actionSheet.view.tintColor = MAINCOLORDARK;
   }
   else
      [self importNextUser];
}

-(void)importNextUser
{
   User* firstUser= self.importUsers.firstObject;
   
   [self.importUsers removeObject:firstUser];
   
   if (firstUser)
   {
      NSLog(@"Integrating next user");
      
      [self integrateUser:firstUser completion:^(BOOL success)
       {
          if (!success)
          {
             NSLog(@"Aborting import due to internal failure");
             return;
          }

          [self importNextUser];
       }];
   }
   else
      [self finalizeImport];
}

// ************************************************************
// didFailWithError
// ************************************************************

- (void)parser:(CHCSVParser *)aParser didFailWithError:(NSError *)error
{
   UIViewController* rvc= [UIApplication sharedApplication].delegate.window.rootViewController;

   if (error)
      [Service alert:NSLocalizedString(@"Error", nil) withText:NSLocalizedString(@"Failed to save data", nil) andError:error forController:rvc completion:nil];
   
   [parser cancelParsing];
   
   err++;
}

#pragma mark - After

// ************************************************************
// Integrate User
// ************************************************************

-(void)integrateUser:(User*)aUser completion:(void (^)(BOOL success))completionHandler
{
   if (!aUser)
   {
      completionHandler(YES);
      return;
   }
   
   NSString* theName = aUser.name;
   int i = 0;
   
   while ([[Storage currentStorage] userWithName:theName])
   {
      if (!i++)
         theName = [NSString stringWithFormat:@"%@ (imported)", aUser.name];
      else
         theName = [NSString stringWithFormat:@"%@ (imported %d)", aUser.name, i+1];
   }

   if (![theName isEqualToString:aUser.name])
      NSLog(@"integrate user %@ as %@ (user with same name already existed) ...", aUser.name, theName);
   else
      NSLog(@"integrate user %@ ...", theName);
   
   [[Storage currentStorage] createUser:theName andPassword:aUser.password andUuid:aUser.uuid completion:^(BOOL success, User* newUser)
    {
       newUser.rights= aUser.rights;
       newUser.availableUsers= aUser.availableUsers;
       newUser.color= aUser.color;

       [self.importedUserNames addObject:theName];  // save for summary popup at the end

       [newUser saveDocument:^(BOOL success)
        {
           completionHandler(YES);
        }];
    }];
}

// ************************************************************
// Merge Single User
// ************************************************************

-(void)mergeSingleUser:(User*)aUser completion:(void (^)(BOOL success))completionHandler
{
   if (!aUser)
   {
      completionHandler(YES);
      return;
   }
   
   User* singleUser= [[Storage currentStorage] singleUser];
   
   if (!singleUser)
   {
      NSLog(@"FATAL: Missing single user object in global user list, cannot merge users!");
      completionHandler(NO);
      return;
   }

   singleUser.name = aUser.name;
   singleUser.password = aUser.password;
   singleUser.rights = aUser.rights;
   singleUser.color= aUser.color;
   
   [importedUserNames addObject:singleUser.name];  // save for summary popup at the end
   
   [singleUser saveDocument:^(BOOL success)
    {
       completionHandler(YES);
    }];
}

// ************************************************************
// finalizeImport
// ************************************************************

-(void)finalizeImport
{
   NSLog(@"Finalizing import");
   
   BOOL merge = self.importedUserNames.count == 1 && [Settings globalSettingBool:skSingleUser];
   User* owner= merge ? [[Storage currentStorage] singleUser] : nil;
   
   if (merge && !owner)
   {
      NSLog(@"FATAL: Missing single user object in global user list, cannot merge users!");
      return;
   }
   
   if (merge)
   {
      // in merge case, everything will be replaced

      [owner.categories removeAllObjects];
      [owner.timetables removeAllObjects];
      [owner.years removeAllObjects];
      [owner.leave removeAllObjects];
   }

   [self.savableUsers removeAllObjects];

   // (1) categories

   for (CategoryRef* cat in self.importCategories)
   {
      if (merge)
      {
         cat.userid = owner.uuid;
      }
      else
      {
         owner= cat.userid ? [[Storage currentStorage] userWithUUid:cat.userid] : nil;

         if (!owner && cat.userid)
         {
            NSLog(@"Cannot import category '%@' with unknown owner '%@'", cat.name, cat.userid);
            continue;
         }
      }

      if (owner)
      {
         [owner.categories addObject:cat];
         
         if (![self.savableUsers containsObject:owner])
            [self.savableUsers addObject:owner];
      }
      else
      {
         for (User* aOwner in [Storage userlist])
         {
            if (cat.deletable.boolValue && ![Storage categoryForName:cat.name ofUser:aOwner])
               [aOwner.categories addObject:cat];
         }
      }
   }
   
   if (merge && !self.importCategories.count)
      [Storage createDefaultCategories:owner];

   // (2) timetables
   
   for (Timetable* tt in self.importTimetables)
   {
      if (merge)
      {
         tt.userid = owner.uuid;
      }
      else
      {
         owner= tt.userid ? [[Storage currentStorage] userWithUUid:tt.userid] : nil;

         if (!owner && tt.userid)
         {
            NSLog(@"Cannot import timetable '%@' with unknown owner '%@'", tt.name, tt.userid);
            continue;
         }
      }

      if (owner)
      {
         [owner.timetables addObject:tt];
         
         if (![self.savableUsers containsObject:owner])
            [self.savableUsers addObject:owner];
      }
      else
      {
         for (User* aOwner in [Storage userlist])
            [aOwner.timetables addObject:tt];
      }
   }
   
   if (merge && !self.importTimetables.count)
      [Storage createDefaultTimetables:owner];


   // (3) years

   for (YearSummary* year in self.importYears)
   {
      if (merge)
      {
         year.userid = owner.uuid;
      }
      else
      {
         owner= [[Storage currentStorage] userWithUUid:year.userid];
         
         if (!owner)
         {
            NSLog(@"Cannot import year summary '%@' with unknown owner '%@'", year.year, year.userid);
            continue;
         }
      }

      [owner.years addObject:year];
   }

   // (4) pools
   
   for (Pool* pool in self.importPools)
   {
      if (merge)
      {
         pool.userid = owner.uuid;
      }
      else
      {
         owner= [[Storage currentStorage] userWithUUid:pool.userid];
         
         if (!owner)
         {
            NSLog(@"Cannot import pool '%@' with unknown owner '%@'", pool.category, pool.userid);
            continue;
         }
      }

      int found= 0;
      
      for (YearSummary* year in owner.years)
      {
         if (year.year.intValue == pool.year.intValue)
         {
            [year.pools addObject:pool];
            found= 1;
            break;
         }
      }
      
      if (!owner)
         NSLog(@"Cannot import pool '%@' with unknown year '%@'", pool.category, pool.year);

      if (![self.savableUsers containsObject:owner])
         [self.savableUsers addObject:owner];
   }

   // (4) leave info
   
   for (LeaveInfo* info in self.importLeaveInfos)
   {
      if (merge)
      {
         info.userid = owner.uuid;
      }
      else
      {
         owner= [[Storage currentStorage] userWithUUid:info.userid];
         
         if (!owner)
         {
            NSLog(@"Cannot import leave info '%@' with unknown owner '%@'", info.title, info.userid);
            continue;
         }
      }
      
      [owner.leave addObject:info];
      
      if (![self.savableUsers containsObject:owner])
         [self.savableUsers addObject:owner];
   }
   
   // (5) block declaration for recursive saving

//   void (^__block saveUserBlock)(BOOL success) = ^(BOOL success)
//   {
//      if (!success)
//      {
//         NSLog(@"Aborting import due to internal failure");
//         return;
//      }
//
//      User* firstUser= savableUsers.firstObject;
//
//      [savableUsers removeObject:firstUser];
//
//      if (firstUser)
//      {
//         NSLog(@"Saving next user");
//
//         [savableUsers removeObject:firstUser];
//         [firstUser saveDocument:saveUserBlock];
//      }
//      else
//      {
//         [[NSNotificationCenter defaultCenter] postNotificationName:kImportFinished object:self];
//
//         [savableUsers removeAllObjects];
//         [savableUsers release];
//
//         NSLog(@"-------- IMPORT DONE --------");
//
//         UIViewController* rvc= [UIApplication sharedApplication].delegate.window.rootViewController;
//
//         NSMutableString* message = [[NSLocalizedString(@"Successfully imported backup with the following users:", nil) mutableCopy] autorelease];
//
//         for (NSString* user in self.importedUserNames)
//            [message appendFormat:@"\n%@", user];
//
//         [Service message:NSLocalizedString(@"Info", nil) withText:message forController:rvc completion:nil];
//
//         if (self.completionBlock)
//            self.completionBlock(YES);
//      }
//   };
   
   // (6) trigger recursively saving of all new users
   
   [self saveNextUser];
   
//   User* firstUser= [savableUsers firstObject];
//
//   [savableUsers removeObject:firstUser];
//
//   [firstUser saveDocument:saveUserBlock];
}

-(void)saveNextUser
{
   User* firstUser= self.savableUsers.firstObject;
   
   [self.savableUsers removeObject:firstUser];
   
   if (firstUser)
   {
      NSLog(@"Saving next user");
      
      [firstUser saveDocument:^(BOOL success)
       {
          if (!success)
          {
             NSLog(@"Aborting import due to internal failure");
             return;
          }
          
          [self saveNextUser];
       }];
   }
   else
   {
      [[NSNotificationCenter defaultCenter] postNotificationName:kImportFinished object:self];
      
      [self.savableUsers removeAllObjects];
      
      NSLog(@"-------- IMPORT DONE --------");
      
      UIViewController* rvc= [UIApplication sharedApplication].delegate.window.rootViewController;
      
      NSMutableString* message = [[NSLocalizedString(@"Successfully imported backup with the following users:", nil) mutableCopy] autorelease];
      
      for (NSString* user in self.importedUserNames)
         [message appendFormat:@"\n%@", user];
      
      [Service message:NSLocalizedString(@"Info", nil) withText:message forController:rvc completion:nil];
      
      if (self.completionBlock)
      {
         self.completionBlock(YES);
         self.completionBlock= nil;
      }
      
   }
}

@end
