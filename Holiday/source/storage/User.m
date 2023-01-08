//************************************************************
// User.m
// Holliday
//************************************************************
// Created by Patrick Fial on 06.01.12.
// Copyright 2012-2013 Patrick Fial. All rights reserved.
//************************************************************

//************************************************************
// includes
//************************************************************

#import "AppDelegate.h"

#import "User.h"
#import "Service.h"
#import "Settings.h"

//************************************************************
// class User
//************************************************************

@implementation User

@synthesize uuid, name, password, rights, availableUsers;
@synthesize years, color, settings, userInfo, leave, categories;
@synthesize timetables, isSingleUser, freedays;

#pragma mark - Store

//************************************************************
// contentsForType
//************************************************************

- (id)contentsForType:(NSString *)typeName error:(NSError **)outError
{
   NSKeyedArchiver* archiver = [[[NSKeyedArchiver alloc] initRequiringSecureCoding:FALSE] autorelease];
   
   [archiver encodeInt:2 forKey:@"VERSION"];
   [archiver encodeObject:self.uuid forKey:@"UUID"];
   [archiver encodeObject:self.name forKey:@"NAME"];
   [archiver encodeObject:self.password forKey:@"PASSWORD"];
   [archiver encodeInt:self.rights.intValue forKey:@"RIGHTS"];
   [archiver encodeObject:self.availableUsers forKey:@"AVAILUSERS"];
   [archiver encodeObject:self.color forKey:@"COLOR"];
   [archiver encodeObject:self.settings forKey:@"SETTINGS"];
   [archiver encodeObject:self.userInfo forKey:@"USERINFO"];
   [archiver encodeObject:self.years forKey:@"YEARS"];
   [archiver encodeObject:self.leave forKey:@"LEAVE"];
   [archiver encodeObject:self.categories forKey:@"CATEGORIES"];
   [archiver encodeObject:self.timetables forKey:@"TIMETABLES"];
   [archiver encodeInt:self.isSingleUser forKey:@"ISSINGLEUSER"];
   [archiver encodeObject:self.freedays forKey:@"FREEDAYS"];

   return archiver.encodedData;
}

#pragma mark - Load

//************************************************************
// loadFromContents
//************************************************************

- (BOOL)loadFromContents:(id)contents ofType:(NSString *)typeName error:(NSError **)outError
{
   if ([contents length] <= 0)
      return FALSE;

   NSError* error = nil;
   NSKeyedUnarchiver* archiver= [[NSKeyedUnarchiver alloc] initForReadingFromData:contents error:&error];
   archiver.requiresSecureCoding = NO;
   
   if (error)
      [Service alert:NSLocalizedString(@"Error", nil) withText:NSLocalizedString(@"", nil) andError:error forController:nil completion:nil];
   
   int version= [archiver decodeIntForKey:@"VERSION"];
   
   if (version >= 1)
   {
      self.uuid= [archiver decodeObjectForKey:@"UUID"];
      self.name= [archiver decodeObjectForKey:@"NAME"];
      self.password= [archiver decodeObjectForKey:@"PASSWORD"];
      self.rights= [NSNumber numberWithInt:[archiver decodeIntForKey:@"RIGHTS"]];
      self.availableUsers= [archiver decodeObjectForKey:@"AVAILUSERS"];
      self.color= [archiver decodeObjectForKey:@"COLOR"];
      self.settings= [archiver decodeObjectForKey:@"SETTINGS"];
      self.userInfo= [archiver decodeObjectForKey:@"USERINFO"];
      self.years= [[[archiver decodeObjectForKey:@"YEARS"] mutableCopy] autorelease];
      self.leave= [[[archiver decodeObjectForKey:@"LEAVE"] mutableCopy] autorelease];
      self.categories= [[[archiver decodeObjectForKey:@"CATEGORIES"] mutableCopy] autorelease];
      self.timetables= [[[archiver decodeObjectForKey:@"TIMETABLES"] mutableCopy] autorelease];
      self.isSingleUser = [archiver decodeIntForKey:@"ISSINGLEUSER"];
      self.freedays= [NSMutableArray array];
   }

   if (version >= 2)
   {
      self.freedays= [[[archiver decodeObjectForKey:@"FREEDAYS"] mutableCopy] autorelease];
      
      if (!self.freedays)
         self.freedays= [NSMutableArray array];
   }
   
   [archiver finishDecoding];
   [archiver release];

   return YES;
}

#pragma mark - iCloud

// *****************************************
// saveUserToICloud
// *****************************************

-(void)saveToICloud:(void (^)(BOOL success))completionHandler
{
   NSURL* baseURL= [[NSFileManager defaultManager] URLForUbiquityContainerIdentifier:nil];

   if (!baseURL)
   {
      if (!completionHandler)
         return;
      
      [Service alert:NSLocalizedString(@"Error", nil) withText:NSLocalizedString(@"Cannot save user to iCloud - iCloud disabled", nil) andError:nil forController:nil completion:nil];
      
      completionHandler(NO);
      return;
   }
   
   NSURL* documentsURL = [baseURL URLByAppendingPathComponent:@"Documents"];
   NSURL* documentURL = [documentsURL URLByAppendingPathComponent:[NSString stringWithFormat:@"%@.user", self.uuid]];
   
   [self saveToURL:documentURL forSaveOperation:UIDocumentSaveForOverwriting completionHandler:^(BOOL success)
    {
       NSLog(@"%@ saved user to iCloud ....", success ? @"Successfully" : @"UNSUCCESSFULLY");
       
       if (completionHandler)
          completionHandler(success);
    }];
}

@end

