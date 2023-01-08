//************************************************************
// MailPrefController.h
// Holiday
//************************************************************
// Created by Patrick Fial on 18.07.2010
// Copyright 2010-2015 Patrick Fial. All rights reserved.
//************************************************************

//************************************************************
// includes
//************************************************************

#import <UIKit/UIKit.h>
#import "TextCell.h"
#import "Service.h"

//************************************************************
// class MailPrefController
//************************************************************

@interface MailPrefController : UITableViewController <UITextFieldDelegate, UITextViewDelegate, TextInputCellDelegate>
{
   UITextField* toField;
   UITextField* ccField;
   UITextField* bccField;
   UITextField* subjectField;
   UITextView* bodyField;
}

@property (nonatomic, retain) NSArray* menuItems;
@property (nonatomic, retain) NSString* mailTo;
@property (nonatomic, retain) NSString* mailCc;
@property (nonatomic, retain) NSString* mailBcc;
@property (nonatomic, retain) NSString* mailSubject;
@property (nonatomic, retain) NSString* mailBody;
@property (nonatomic, retain) NSIndexPath* editedIndex;

-(void)fill;
-(void)saveMailPrefs;

@end
