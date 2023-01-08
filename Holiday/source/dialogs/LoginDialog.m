//************************************************************
// LoginController.m
// Annual Leave iPad
//************************************************************
// Created by Patrick Fial on 05.01.2012
// Copyright 2012-2012 Patrick Fial. All rights reserved.
//************************************************************

#import "LoginDialog.h"
#import "TextCell.h"
#import "SwitchCell.h"
#import "Service.h"
#import "User.h"
#import "Settings.h"
#import "Crypt.h"
#import "SessionManager.h"
#import "Storage.h"

int eraseAlert;

@implementation LoginDialog

@synthesize labelTitle, buttonLogin, buttonCreate, buttonUserlist, rvc;
@synthesize loadICloudLabel, loadICloudActivity;
@synthesize textFieldUser, textFieldPassword, switchAutoLogin;
@synthesize labelAutoLogin;
@synthesize availableUsers, labelICloud, switchICloud, buttonResetICloud;

//************************************************************
// init
//************************************************************

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
   self= [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
   
   if (self)
   {
      self.availableUsers= [[[NSMutableDictionary alloc] init] autorelease];
   }
   
   return self;
}

//************************************************************
// dealloc
//************************************************************

-(void)dealloc
{
   self.availableUsers= nil;
   self.labelTitle= nil;
   self.buttonLogin= nil;
   self.buttonCreate= nil;
   self.buttonUserlist= nil;
   self.textFieldUser= nil;
   self.textFieldPassword= nil;
   self.switchAutoLogin= nil;
   self.loadICloudLabel= nil;
   self.loadICloudActivity= nil;
   
   [super dealloc];
}

#pragma mark - View lifecycle

//************************************************************
// viewDidLoad
//************************************************************

- (void)viewDidLoad
{
   [super viewDidLoad];
   
   NSString* appName= [[[NSBundle mainBundle] localizedInfoDictionary] objectForKey:@"CFBundleDisplayName"];
   
   if (appName == nil)
      appName= [[[NSBundle mainBundle] infoDictionary] objectForKey:@"CFBundleDisplayName"];

   self.labelTitle.text= appName;
   self.textFieldUser.text= [Settings globalSettingString:skLastUser];
   self.textFieldUser.placeholder= NSLocalizedString(@"Enter username", nil);
   self.textFieldUser.delegate= self;
   self.textFieldPassword.placeholder= NSLocalizedString(@"Enter password", nil);
   self.textFieldPassword.delegate= self;
   self.labelAutoLogin.text= NSLocalizedString(@"Stay logged in", nil);
   self.switchAutoLogin.on= [Settings globalSettingBool:skAutoLogin];
   self.loadICloudLabel.text= NSLocalizedString(@"Loading iCloud storage, please wait ...", nil);

   [self.buttonLogin addTarget:self action:@selector(login:) forControlEvents:UIControlEventTouchUpInside];
   [self.buttonCreate addTarget:self action:@selector(create:) forControlEvents:UIControlEventTouchUpInside];   
   [self.buttonUserlist addTarget:self action:@selector(showUserlist:) forControlEvents:UIControlEventTouchUpInside];   
   [self.switchAutoLogin addTarget:self action:@selector(switchToggle:) forControlEvents:UIControlEventValueChanged];
   [self.switchICloud addTarget:self action:@selector(switchToggle:) forControlEvents:UIControlEventValueChanged];
   
   [self.buttonLogin setTitle:NSLocalizedString(@"Login", nil) forState:UIControlStateNormal];
   [self.buttonLogin setTitle:NSLocalizedString(@"Login", nil) forState:UIControlStateHighlighted];
   [self.buttonLogin setTitle:NSLocalizedString(@"Login", nil) forState:UIControlStateDisabled];
   [self.buttonLogin setTitle:NSLocalizedString(@"Login", nil) forState:UIControlStateSelected];
   
   [self.buttonCreate setTitle:NSLocalizedString(@"Create ", nil) forState:UIControlStateNormal];
   [self.buttonCreate setTitle:NSLocalizedString(@"Create ", nil) forState:UIControlStateHighlighted];
   [self.buttonCreate setTitle:NSLocalizedString(@"Create ", nil) forState:UIControlStateDisabled];
   [self.buttonCreate setTitle:NSLocalizedString(@"Create ", nil) forState:UIControlStateSelected];
   
   [self.buttonCreate setTitleColor:MAINCOLORDARK forState:UIControlStateNormal];
   [self.buttonLogin setTitleColor:MAINCOLORDARK forState:UIControlStateNormal];
   
   if (!iCloudAvailable)
   {
      self.switchICloud.on= NO;
      self.switchICloud.enabled= NO;
      self.labelICloud.text= NSLocalizedString(@"iCloud not available", nil);
      self.labelICloud.textColor= [UIColor lightGrayColor];
   }
   else
   {
      self.switchICloud.on= NO; //[Settings useICloud];
      self.labelICloud.text= NSLocalizedString(@"iCloud synchronization", nil);
   }

   loadICloudActivity.hidesWhenStopped= YES;
   
   // icloud tricks
   
//   if (iCloudAvailable && !iCloudReady && [Settings useICloud])
//   {
//      // lock controls until icloud is ready
//      
//      [self disableControls];
//      [self showLoading];
//   }
//   else
   {
      [self enableControls];
      [self hideLoading];
   }
   
   self.buttonResetICloud.enabled= iCloudAvailable;

//   self.labelICloud.hidden= YES;
//   self.switchICloud.hidden= YES;
//   self.buttonResetICloud.hidden= YES;
}

//************************************************************
// viewDidAppear
//************************************************************

-(void)viewDidAppear:(BOOL)animated
{
}

#pragma mark - Buttons

// ************************************************************
// login
// ************************************************************

-(void)login:(id)sender
{
   if (!self.textFieldUser.text.length)
   {
      [Service alert:NSLocalizedString(@"Error", nil) withText:NSLocalizedString(@"No user selected", nil) andError:nil forController:self completion:nil];
      return;
   }
   
   User* user= [[Storage currentStorage] userWithName:self.textFieldUser.text];

   if (!user)
   {
      [Service alert:NSLocalizedString(@"Error", nil) withText:NSLocalizedString(@"User does not exist", nil) andError:nil forController:self completion:nil];
      return;
   }
   
   if (isEmpty(user.password) != isEmpty(self.textFieldPassword.text) && ![user.password isEqualToString:self.textFieldPassword.text.hashedSha2])
   {
      [Service alert:NSLocalizedString(@"Error", nil) withText:NSLocalizedString(@"Password incorrect", nil) andError:nil forController:self completion:nil];
      return;
   }
   
   [[SessionManager session] login:user withAutoLogin:switchAutoLogin.isOn];
   
   [self dismissViewControllerAnimated:NO completion:^{}];
}

// ************************************************************
// create user
// ************************************************************

-(void)create:(id)sender
{
   if (![self.textFieldUser.text length])
   {
      [Service alert:NSLocalizedString(@"Error", nil) withText:NSLocalizedString(@"Can't create user with empty name", nil) andError:nil forController:self completion:nil];
      return;
   }

   // try to find existing user first

   if ([[Storage currentStorage] haveUserWithName:self.textFieldUser.text])
   {
      [Service alert:NSLocalizedString(@"Error", nil) withText:NSLocalizedString(@"Can't create user, a user with the same name already exists!", nil) andError:nil forController:self completion:nil];
      return;
   }

   // determine if this is the first user

   int isAdmin= NO;
   NSArray* users= [Storage userlist];

   if (![users count])
      isAdmin= YES;

   [[Storage currentStorage] createUser:self.textFieldUser.text andPassword:self.textFieldPassword.text andUuid:nil completion:^(BOOL success, User* aUser)
    {
       if (success)
       {
          if (isAdmin)
             aUser.rights= [NSNumber numberWithInt:rightAdmin];
          else
             aUser.rights= [NSNumber numberWithInt:0];

          [aUser saveDocument:^(BOOL success)
           {
              if (success)
              {
                 [aUser updateChangeCount:UIDocumentChangeDone];
              
                 [[SessionManager session] login:aUser withAutoLogin:switchAutoLogin.isOn];
              
                 [self dismissViewControllerAnimated:YES completion:^{}];
              }
              else
                 NSLog(@"Error: Failed to save user after creating new user");
           }];
       }
    }];
}

// ************************************************************
// showUserlist
// ************************************************************

-(void)showUserlist:(id)sender
{
   // re-init global userlist
   
   NSArray* users= [Storage userlist];
   
   if (!users.count)
   {
      [Service message:NSLocalizedString(@"Info", nil) withText:NSLocalizedString(@"No users have been created yet", nil) forController:self completion:nil];
      return;
   }
   
   UIAlertController* actionSheet= [UIAlertController alertControllerWithTitle:NSLocalizedString(@"Select user", nil) message:nil preferredStyle:UIAlertControllerStyleActionSheet];
   
   for (User* user in [Storage userlist])
   {
      [actionSheet addAction:[UIAlertAction actionWithTitle:user.name style:UIAlertActionStyleDefault handler:^(UIAlertAction* action)
                              {
                                 self.textFieldUser.text= action.title;
                              }]];
   }

   [actionSheet addAction:[UIAlertAction actionWithTitle:NSLocalizedString(@"Cancel", nil) style:UIAlertActionStyleCancel handler:nil]];
   [self presentViewController:actionSheet animated:YES completion:nil];
   actionSheet.view.tintColor = MAINCOLORDARK;
}

#pragma mark - switch

// ************************************************************
// autoLoginToggle
// ************************************************************

-(void)switchToggle:(id)sender
{
   if (sender == self.switchAutoLogin)
      [Settings setGlobalSetting:skAutoLogin withBool:self.switchAutoLogin.on];
//   else
//   {
//      UIAlertView* alert;
//      alertForICloud= YES;
//
//      if (self.switchICloud.on)
//      {
//         alert= [[[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Note", nil) 
//                                            message:NSLocalizedString(@"iCloud synchronization is still experimental. The local data from the first enabled device will be copied to iCloud.", nil) 
//                                           delegate:self 
//                                  cancelButtonTitle:NSLocalizedString(@"Cancel", nil)
//                                  otherButtonTitles:NSLocalizedString(@"Continue", nil), nil] autorelease];
//      }
//      else
//      {
//         alert= [[[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Note", nil) 
//                                            message:NSLocalizedString(@"If you stop using iCloud you will switch to using local data on this device only. Your local data is completely separate from iCloud. Any changes you make will not be be synchronized with iCloud.", nil) 
//                                           delegate:self 
//                                  cancelButtonTitle:NSLocalizedString(@"Cancel", nil)
//                                  otherButtonTitles:NSLocalizedString(@"Continue", nil), nil] autorelease];
//      }
//      
//      [alert show];
//   }
}

#pragma mark - TextField delegate

// ************************************************************
// textFieldShouldReturn
// ************************************************************

- (BOOL)textFieldShouldReturn:(UITextField *)textField
{
   if (textField == self.textFieldUser)
   {
      [self.textFieldPassword becomeFirstResponder];
      return NO;
   }
   
   [textField resignFirstResponder];
   
   return YES;
}

#pragma mark - UI controlling

// ************************************************************
// enableControls
// ************************************************************

-(void)enableControls
{
   [self.buttonLogin setEnabled:YES];
   [self.buttonCreate setEnabled:YES];
   [self.switchICloud setEnabled:iCloudAvailable];
   
   self.buttonLogin.titleLabel.textColor= [UIColor darkGrayColor];
   self.buttonCreate.titleLabel.textColor= [UIColor darkGrayColor];
}

// ************************************************************
// disableControls
// ************************************************************

-(void)disableControls
{
   [self.buttonLogin setEnabled:NO];
   [self.buttonCreate setEnabled:NO];
   [self.switchICloud setEnabled:NO];
   
   self.buttonLogin.titleLabel.textColor= [UIColor lightGrayColor];
   self.buttonCreate.titleLabel.textColor= [UIColor lightGrayColor];
}

// ************************************************************
// showLoading
// ************************************************************

-(void)showLoading
{
   [self.loadICloudLabel setHidden:NO];
   [self.loadICloudActivity setHidden:NO];
   [loadICloudActivity startAnimating];
}

// ************************************************************
// hideLoading
// ************************************************************

-(void)hideLoading
{
   [self.loadICloudLabel setHidden:YES];
   [self.loadICloudActivity setHidden:YES];
   [loadICloudActivity stopAnimating];
}

@end
