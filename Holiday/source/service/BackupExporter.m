//************************************************************
// BackupExporter.m
// Holiday
//************************************************************
// Created by Patrick Fial on 05.09.2015
// Copyright 2015-2015 Patrick Fial. All rights reserved.
//************************************************************

//************************************************************
// includes
//************************************************************

#import "AppDelegate.h"
#import "BackupExporter.h"
#import "Service.h"
#import "User.h"

//************************************************************
// class BackupExporter
//************************************************************

@implementation BackupExporter

@synthesize user;

#pragma mark - Lifecycle

//************************************************************
// init
//************************************************************

-(id)init
{
   self= [super init];
   
   if (self)
   {
      self.user= nil;
   }
   
   return self;
}

//************************************************************
// dealloc
//************************************************************

-(void)dealloc
{
   self.user= nil;
   
   [super dealloc];
}

#pragma mark - Export

//************************************************************
// exportUser
//************************************************************

-(void)exportUser:(User*)aUser
{
   self.user= aUser;
   
   NSError* error= nil;
   NSString* fileName= [NSString stringWithFormat:@"%@.backup.alb2", self.user.name];
   NSURL* url= [((AppDelegate*)[UIApplication sharedApplication].delegate).applicationDocumentsDirectory URLByAppendingPathComponent:fileName];
   UIViewController* rvc= [UIApplication sharedApplication].delegate.window.rootViewController;
   
   if ([[NSFileManager defaultManager] fileExistsAtPath:url.path isDirectory:nil])
      [[NSFileManager defaultManager] removeItemAtPath:url.path error:nil];

   if (![[NSFileManager defaultManager] copyItemAtPath:self.user.fileURL.path toPath:url.path error:&error] || error)
   {
      // temp-copying failed
      
      [Service alert:NSLocalizedString(@"Error", nil) withText:NSLocalizedString(@"User could not be exported", nil) andError:error forController:rvc completion:nil];
   }
   else
   {
      UIDocumentPickerViewController* dvc= [[[UIDocumentPickerViewController alloc] initWithURL:url inMode:UIDocumentPickerModeExportToService] autorelease];
      dvc.delegate= self;
      
      [[UINavigationBar appearance] setTintColor:nil];
//      [[UINavigationBar appearance] setTitleTextAttributes:@{NSForegroundColorAttributeName : LIGHTTEXTCOLOR}];

//      [[UIButton appearanceWhenContainedInInstancesOfClasses:[NSArray arrayWithObject:[UINavigationBar class]]] setTintColor:MAINCOLORDARK];
   
      UIViewController* rvc= [UIApplication sharedApplication].delegate.window.rootViewController;

      [rvc presentViewController:dvc animated:YES completion:nil];
   }
}

#pragma mark - UIDocumentPickerDelegate

// ************************************************************
// didPickDocumentAtURL
// ************************************************************

- (void)documentPicker:(UIDocumentPickerViewController *)controller didPickDocumentsAtURLs:(NSArray<NSURL *> *)urls
{
   UIViewController* rvc= [UIApplication sharedApplication].delegate.window.rootViewController;
   NSString* fileName= [NSString stringWithFormat:@"%@.backup.alb2", self.user.name];
   NSURL* url= [((AppDelegate*)[UIApplication sharedApplication].delegate).applicationDocumentsDirectory URLByAppendingPathComponent:fileName];
   
   if ([[NSFileManager defaultManager] fileExistsAtPath:url.path isDirectory:nil])
      [[NSFileManager defaultManager] removeItemAtPath:url.path error:nil];
   
   [Service message:NSLocalizedString(@"Info", nil) withText:NSLocalizedString(@"Successfully exported backup.", nil) forController:rvc completion:nil];
//   [[UIButton appearanceWhenContainedInInstancesOfClasses:[NSArray arrayWithObject:[UINavigationBar class]]] setTintColor:MAINCOLORDARK];
   
   [[UINavigationBar appearance] setTintColor:LIGHTTEXTCOLOR];
   [[UINavigationBar appearance] setTitleTextAttributes:@{NSForegroundColorAttributeName : LIGHTTEXTCOLOR}];
}

// ************************************************************
// documentPickerWasCancelled
// ************************************************************

-(void)documentPickerWasCancelled:(UIDocumentPickerViewController *)controller
{
   NSString* fileName= [NSString stringWithFormat:@"%@.backup.alb2", self.user.name];
   NSURL* url= [((AppDelegate*)[UIApplication sharedApplication].delegate).applicationDocumentsDirectory URLByAppendingPathComponent:fileName];
   
   if ([[NSFileManager defaultManager] fileExistsAtPath:url.path isDirectory:nil])
      [[NSFileManager defaultManager] removeItemAtPath:url.path error:nil];

//   [[UIButton appearanceWhenContainedInInstancesOfClasses:[NSArray arrayWithObject:[UINavigationBar class]]] setTintColor:MAINCOLORDARK];
   
   [[UINavigationBar appearance] setTintColor:LIGHTTEXTCOLOR];
   [[UINavigationBar appearance] setTitleTextAttributes:@{NSForegroundColorAttributeName : LIGHTTEXTCOLOR}];
}

@end
