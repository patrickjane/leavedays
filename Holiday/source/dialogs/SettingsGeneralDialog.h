//************************************************************
// SettingsController.h
// Holiday
//************************************************************
// Created by Patrick Fial on 06.01.12.
// Copyright 2012-2014 Patrick Fial. All rights reserved.
//************************************************************

//************************************************************
// includes
//************************************************************

#import <UIKit/UIKit.h>
#import <EventKitUI/EventKitUI.h>
#import "SegmentCell.h"
#import "SwitchCell.h"
#import "Service.h"

@class BackupImporter;
@class BackupExporter;

//************************************************************
// class SettingsController
//************************************************************

@interface SettingsGeneralDialog : UITableViewController<EKCalendarChooserDelegate, UIDocumentPickerDelegate>
{
   int needReset;
}

@property (nonatomic, retain) BackupImporter* importer;
@property (nonatomic, retain) BackupExporter* exporter;

@end
