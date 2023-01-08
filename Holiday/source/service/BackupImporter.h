//************************************************************
// BackupImporter.h
// Holiday
//************************************************************
// Created by Patrick Fial on 04.09.2015
// Copyright 2015-2015 Patrick Fial. All rights reserved.
//************************************************************

//************************************************************
// includes
//************************************************************

#import <Foundation/Foundation.h>
#import "CHCSVParser.h"

@class User;
@class YearSummary;
@class LeaveInfo;
@class CategoryRef;
@class Pool;
@class Timetable;

//************************************************************
// class BackupImporter
//************************************************************

enum ImportMode
{
   lmUnknown= -1,
   
   lmUser,
   lmYear,
   lmPool,
   lmLeave,
   lmTimetable,
   lmCategory,
   
   lmRecord
};

@interface BackupImporter : NSObject<CHCSVParserDelegate>
{
   CHCSVParser* parser;
   
   YearSummary* lastYear;
   User* lastUser;
   Pool* lastPool;
   CategoryRef* lastCategory;
   LeaveInfo* lastLeave;
   Timetable* lastTimetable;
   
   enum ImportMode lastMode;
   int lastIndex;
   int isHeaderRow;
   int err;
}

@property (nonatomic, retain, nullable) NSMutableArray* importedUserNames;
@property (nonatomic, retain, nullable) NSMutableArray* importUsers;
@property (nonatomic, retain, nullable) NSMutableArray* importYears;
@property (nonatomic, retain, nullable) NSMutableArray* importPools;
@property (nonatomic, retain, nullable) NSMutableArray* importLeaveInfos;
@property (nonatomic, retain, nullable) NSMutableArray* importCategories;
@property (nonatomic, retain, nullable) NSMutableArray* importTimetables;
@property (nonatomic, retain, nullable) NSMutableArray* savableUsers;
@property (nonatomic, retain, nullable) NSDateFormatter* dateFormatter;
@property (nonatomic, copy, nullable) void (^completionBlock)(BOOL success);

-(void)importFile:(nullable NSURL*)aUrl completion:(nullable void (^)(BOOL success))completionHandler;;

-(int)toMode:(nullable NSString*)field;

-(void)integrateUser:(nullable User*)aUser completion:(nullable void (^)(BOOL success))completionHandler;
-(void)mergeSingleUser:(nullable User*)aUser completion:(nullable void (^)(BOOL success))completionHandler;
-(void)finalizeImport;

@end
