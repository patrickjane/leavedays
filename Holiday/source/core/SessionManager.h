//************************************************************
// SessionManager.h
// Holliday
//************************************************************
// Created by Patrick Fial on 12.04.14.
// Copyright 2014-2014 Patrick Fial. All rights reserved.
//************************************************************

//************************************************************
// includes
//************************************************************

#import <Foundation/Foundation.h>

@class User;
@class YearSummary;
@class ContainerController;

//************************************************************
// class SessionManager
//************************************************************

@interface SessionManager : NSObject

-(void)login;
-(void)login:(User*)user withAutoLogin:(BOOL)autoLogin;
-(void)logout;
-(void)logout:(id)sender;

// static register

+(SessionManager*)session;

+(User*)activeUser;
+(User*)displayUser;
+(User*)wizardUser;

+(void)setActiveUser:(User*)user;
+(void)setDisplayUser:(User*)user;
+(void)setWizardUser:(User*)user;
+(NSArray*)displayUserIds;
+(void)setDisplayUserIds:(NSArray*)ids;
+(NSDictionary*)displayUsers;
+(void)setDisplayUsers:(NSDictionary*)user;

+(YearSummary*)currentYear;
+(void)setCurrentYear:(YearSummary*)year;

@end
