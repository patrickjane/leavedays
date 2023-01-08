//************************************************************
// BackupExporter.h
// Holiday
//************************************************************
// Created by Patrick Fial on 05.09.2015
// Copyright 2015-2015 Patrick Fial. All rights reserved.
//************************************************************

//************************************************************
// includes
//************************************************************

#import <Foundation/Foundation.h>

@class User;

//************************************************************
// class BackupExporter
//************************************************************

@interface BackupExporter : NSObject<UIDocumentPickerDelegate>

-(void)exportUser:(User*)aUser;

@property (nonatomic, retain) User* user;

@end
