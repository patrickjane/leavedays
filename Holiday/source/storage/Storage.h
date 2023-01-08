//************************************************************
// Storage.h
// Holliday
//************************************************************
// Created by Patrick Fial on 15.09.13.
// Copyright 2013-2013 Patrick Fial. All rights reserved.
//************************************************************

//************************************************************
// includes
//************************************************************

#import <Foundation/Foundation.h>

@class User;
@class YearSummary;
@class CategoryRef;
@class Timetable;
@class LeaveInfo;
@class Pool;
@class Freeday;

//************************************************************
// class Storage
//************************************************************

@interface Storage : NSObject

// static

+(Storage*)currentStorage;
+(NSArray*)userlist;

// helpers

-(void)showAddDialog;
-(void)showAddDialog:(LeaveInfo*)info withBegin:(NSDate*)begin endEnd:(NSDate*)end andYear:(int)year completion:(void (^)(void))completionHandler;

// interaction

-(void)reloadUsers:(void (^)(BOOL success))completionHandler;
-(void)forgetUsers;
-(void)stopQueries;
-(void)wipeData:(BOOL)isSingleUser completionHandler:(void (^)(BOOL success))completionHandler;

//************************************************************
// user

-(User*)userWithUUid:(NSString*)uuid;
-(User*)userWithName:(NSString*)name;
-(User*)singleUser;
-(NSArray*)usersWithName:(NSString*)name;
-(BOOL)haveUserWithName:(NSString*)name;
-(User*)createEmptyUser;
-(User*)createDefaultUser:(BOOL)store completion:(void (^)(BOOL success))completionHandler;
-(void)createUser:(NSString*)name andPassword:(NSString*)password andUuid:(NSString*)aUuid completion:(void (^)(BOOL success, User* user))completionHandler;
-(BOOL)deleteUser:(User*)user;
-(void)initUser:(NSURL*)userUrl;
-(void)initUser:(NSURL*)userUrl completion:(void (^)(BOOL success))completionHandler;
-(void)addUser:(User*)aUser;

//************************************************************
// year

-(YearSummary*)getYear:(int)aYear;
-(YearSummary*)getYear:(int)aYear withUserId:(NSString*)userid;
-(YearSummary*)createYearSummary:(int)aYear;
-(YearSummary*)createYearSummary:(int)aYear withPrecedingYear:(YearSummary*)precedingYear;
-(void)saveYear:(YearSummary*)year completion:(void (^)(BOOL success))completionHandler;
-(void)deleteYear:(YearSummary*)info completion:(void (^)(BOOL success))completionHandler;

+(NSArray*)getYearNumberList;

//************************************************************
// category

+(CategoryRef*)createCategory:(User*)owner;
+(CategoryRef*)categoryForName:(NSString*)name ofUser:(User*)owner;
+(CategoryRef*)categoryForInternalName:(NSString*)name ofUser:(User*)owner;
+(void)deleteCategory:(CategoryRef*)cat completion:(void (^)(BOOL success))completionHandler;
+(void)createDefaultCategories:(User*)owner;

//************************************************************
// timetable

+(Timetable*)createTimetable:(User*)owner;
+(Timetable*)getTimeTable:(NSString*)uuid;
+(Timetable*)getTimeTableForInternalName:(NSString*)internalName orName:(NSString*)name;
+(void)saveTimetable:(Timetable*)tt completion:(void (^)(BOOL success))completionHandler;
+(void)deleteTimetable:(Timetable*)timetable completion:(void (^)(BOOL success))completionHandler;
+(void)createDefaultTimetables:(User*)owner;

//************************************************************
// freedays

+(Freeday*)createFreeday:(User*)owner;
+(Freeday*)getFreeday:(NSString*)uuid;
+(void)saveFreeday:(Freeday*)freeday completion:(void (^)(BOOL success))completionHandler;
+(void)deleteFreeday:(Freeday*)freeday completion:(void (^)(BOOL success))completionHandler;
+(void)rebuildFreedaysList;
+(NSDictionary*)freedaysList;

//************************************************************
// leave

-(LeaveInfo*)createLeaveForOwnerUUID:(NSString*)uuid;
-(LeaveInfo*)createLeaveForOwner:(User*)owner;
-(LeaveInfo*)getLeaveInfoWithUUID:(NSString*)leaveId;
+(void)saveLeave:(LeaveInfo*)info completion:(void (^)(BOOL success))completionHandler;
+(void)saveLeaveInCalendar:(LeaveInfo*)info;
+(void)deleteLeaveFromCalendar:(LeaveInfo*)info;
-(void)deleteLeave:(LeaveInfo*)info completion:(void (^)(BOOL success))completionHandler;
-(double)getLeaveForMonth:(int)month inYear:(int)year;
-(NSMutableArray*)getLeaveForUsers:(NSArray*)userIds withFilter:(NSPredicate*)predicate andSorting:(NSArray*)sortDescriptors;

// pools

+(Pool*)poolOfArray:(NSArray*)pools withName:(NSString*)name;
+(Pool*)poolOfArray:(NSArray*)pools withInternalName:(NSString*)name;
-(Pool*)createPool:(YearSummary*)year withCategory:(CategoryRef*)category;
-(void)createPool:(YearSummary*)year withCategory:(CategoryRef*)category completion:(void (^)(BOOL success, Pool* newPool))completionHandler;
-(void)deletePool:(Pool*)pool completion:(void (^)(BOOL success))completionHandler;

@end

//************************************************************
// class ALDocument
//************************************************************

@interface ALDocument : UIDocument<NSFilePresenter>

-(void)handleError:(NSError *)error userInteractionPermitted:(BOOL)userInteractionPermitted;
-(void)saveDocument:(void (^)(BOOL success))completionHandler;

@end

//************************************************************
// class ALObject
//************************************************************

@interface ALObject : NSObject

-(void)loadFromDictionary:(NSDictionary*)dict;
-(NSDictionary*)saveToDictionary;

@end
