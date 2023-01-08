//************************************************************
// UserEdit.h
// Annual Leave iPad
//************************************************************
// Created by Patrick Fial on 01.02.12.
// Copyright 2012-2012 Patrick Fial. All rights reserved.
//************************************************************

#import <UIKit/UIKit.h>
#import "SwitchCell.h"
#import "TextCell.h"
#import "Service.h"

#import "ColorPickerController.h"

@class User;

@interface UserEdit : UITableViewController<UIPopoverControllerDelegate,HRColorPickerViewControllerDelegate, UITextFieldDelegate, TextInputCellDelegate>
{
   // local selection
   
   int userRights;
   int isInsert;
   
   // tabbing
   
   UITextField* passwordField;
   UITextField* passwordConfirmField;
   BOOL editName;
   BOOL editPassword;
   BOOL needDeletion;
   BOOL isRestrictedMode;
}

@property (nonatomic, assign) BOOL wizardMode;

@property (nonatomic, retain) User* userInfo;
@property (nonatomic, retain) NSArray* menuItems;

@property (nonatomic, retain) UIColor* userColor;
@property (nonatomic, retain) NSString* userName;
@property (nonatomic, retain) NSString* userPassword;
@property (nonatomic, retain) NSString* userConfirmedPassword;
@property (nonatomic, retain) NSMutableDictionary* availableUsers;
@property (nonatomic, assign) int userRights;
@property (nonatomic, assign) BOOL isRestrictedMode;
@property (nonatomic, retain) NSString* initialUserName;

- (BOOL)save;
- (void)fill:(User*)user;
- (NSString*)wizardTitle;

@end
