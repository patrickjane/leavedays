//************************************************************
// User.h
// Holliday
//************************************************************
// Created by Patrick Fial on 06.01.12.
// Copyright 2012-2013 Patrick Fial. All rights reserved.
//************************************************************

//************************************************************
// includes
//************************************************************

#import "Storage.h"

enum Rights
{
   rightSeeAll=   0x0001,
   rightEditAll=  0x0002,
   rightUserEdit= 0x0004,
   
   rightAdmin= rightSeeAll | rightEditAll | rightUserEdit
};

//************************************************************
// class User
//************************************************************

@interface User : ALDocument

@property (nonatomic, retain) NSString * uuid;
@property (nonatomic, retain) NSString * name;
@property (nonatomic, retain) NSString * password;
@property (nonatomic, retain) NSNumber * rights;
@property (nonatomic, assign) BOOL isSingleUser;
@property (nonatomic, retain) NSString * availableUsers;
@property (nonatomic, retain) NSString * color;
@property (nonatomic, retain) NSMutableDictionary * settings;
@property (nonatomic, retain) NSString * userInfo;
@property (nonatomic, retain) NSMutableArray* years;
@property (nonatomic, retain) NSMutableArray* leave;
@property (nonatomic, retain) NSMutableArray* categories;
@property (nonatomic, retain) NSMutableArray* timetables;
@property (nonatomic, retain) NSMutableArray* freedays;

-(void)saveToICloud:(void (^)(BOOL success))completionHandler;

@end
