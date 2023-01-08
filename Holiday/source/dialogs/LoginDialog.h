//************************************************************
// LoginDialog.h
// Annual Leave iPad
//************************************************************
// Created by Patrick Fial on 05.01.2012
// Copyright 2012-2012 Patrick Fial. All rights reserved.
//************************************************************

#import <UIKit/UIKit.h>

@class MenuController;

@interface LoginDialog : UIViewController <UITextFieldDelegate>
{
}

@property (nonatomic, retain) NSMutableDictionary* availableUsers;

@property (nonatomic, retain) IBOutlet UILabel* labelTitle;
@property (nonatomic, retain) IBOutlet UILabel* labelAutoLogin;
@property (nonatomic, retain) IBOutlet UILabel* labelICloud;
@property (nonatomic, retain) IBOutlet UIButton* buttonLogin;
@property (nonatomic, retain) IBOutlet UIButton* buttonCreate;
@property (nonatomic, retain) IBOutlet UIButton* buttonUserlist;
@property (nonatomic, retain) IBOutlet UIButton* buttonResetICloud;
@property (nonatomic, retain) IBOutlet UITextField* textFieldUser;
@property (nonatomic, retain) IBOutlet UITextField* textFieldPassword;
@property (nonatomic, retain) IBOutlet UISwitch* switchAutoLogin;
@property (nonatomic, retain) IBOutlet UISwitch* switchICloud;
@property (nonatomic, retain) IBOutlet UILabel* loadICloudLabel;
@property (nonatomic, retain) IBOutlet UIActivityIndicatorView* loadICloudActivity;

@property (nonatomic, assign) MenuController* rvc;

-(void)login:(id)sender;
-(void)create:(id)sender;
-(void)showUserlist:(id)sender;

-(void)switchToggle:(id)sender;

-(void)enableControls;
-(void)disableControls;
-(void)showLoading;
-(void)hideLoading;

@end
