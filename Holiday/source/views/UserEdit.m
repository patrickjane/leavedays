//************************************************************
// UserEdit.m
// Annual Leave iPad
//************************************************************
// Created by Patrick Fial on 01.02.12.
// Copyright 2012-2012 Patrick Fial. All rights reserved.
//************************************************************

#import "UserEdit.h"
#import "Service.h"
#import "User.h"
#import "Settings.h"
#import "Storage.h"
#import "Crypt.h"
#import "SessionManager.h"
#import "ActionTable.h"

//************************************************************
// class UserEdit
//************************************************************

@implementation UserEdit

@synthesize userInfo, menuItems, userColor, userName, userRights, initialUserName;
@synthesize userPassword, availableUsers, isRestrictedMode, userConfirmedPassword;
@synthesize wizardMode;

//************************************************************
// initWithStyle
//************************************************************

- (id)initWithStyle:(UITableViewStyle)style
{
   self = [super initWithStyle:style];
   
   if (self) 
   {
      // Custom initialization
      
      isRestrictedMode= NO;
      self.wizardMode= NO;
      self.userInfo= nil;
      self.initialUserName= nil;
      
      NSArray* s1= [NSArray arrayWithObjects:NSLocalizedString(@"Name", nil), NSLocalizedString(@"Password", nil), NSLocalizedString(@"Confirm password", nil), NSLocalizedString(@"Color", nil), nil];
      NSArray* s2= [NSArray arrayWithObjects:NSLocalizedString(@"Can edit users", nil), NSLocalizedString(@"Visible users", nil), nil];
      
      self.menuItems= [NSArray arrayWithObjects:s1, s2, nil];
      
      self.userColor= nil;
      self.userName= nil;
      self.userPassword= nil;
      self.userConfirmedPassword= nil;
      self.availableUsers= [NSMutableDictionary dictionary];
      userRights= 0;
      passwordField= nil;
      passwordConfirmField= nil;
      editName= false;
      editPassword= false;
      needDeletion= false;
      isInsert= false;
   }
   
   return self;
}

//************************************************************
// dealloc
//************************************************************

- (void)dealloc
{
   self.userInfo= nil;
   self.menuItems= nil;

   self.userColor= nil;
   self.userName= nil;
   self.userPassword= nil;
   self.userConfirmedPassword= nil;
   self.availableUsers= nil;
   userRights= 0;

   [super dealloc];
}

#pragma mark - View lifecycle

//************************************************************
// viewDidLoad
//************************************************************

- (void)viewDidLoad
{
   [super viewDidLoad];
   
   self.navigationItem.title= NSLocalizedString(@"Edit user", nil);
   self.navigationItem.leftBarButtonItem= self.navigationItem.backBarButtonItem;
   self.navigationItem.rightBarButtonItem= [[[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemSave target:self action:@selector(save)] autorelease];
   self.tableView.backgroundColor= DARKTABLEBACKCOLOR;
   self.tableView.separatorColor= DARKTABLESEPARATORCOLOR;
}

//************************************************************
// viewWillDisappear
//************************************************************

-(void)viewWillAppear:(BOOL)animated
{
   if (self.wizardMode)
      [self fill:nil];
   
  [super viewWillAppear:animated];
}

//************************************************************
// viewWillDisappear
//************************************************************

-(void)viewWillDisappear:(BOOL)animated
{
   if (!needDeletion || !self.userInfo)
   {
      [super viewWillDisappear:animated];
      return;
   }
   
   [[Storage currentStorage] deleteUser:self.userInfo];
   
   [super viewWillDisappear:animated];
}

#pragma mark - WizardPageDelegate

//************************************************************
// wizardTitle
//************************************************************

- (NSString*)wizardTitle
{
   return NSLocalizedString(@"User management", nil);
}

#pragma mark - fill & save

//************************************************************
// save
//************************************************************

-(void)fill:(User*)aUser
{
   User* user= aUser;
   self.userInfo= aUser;
   
   isInsert= false;
   
   self.userColor= [Service colorString:user.color];
   self.userName= user.name;
   self.userPassword= user.password;
   self.userConfirmedPassword= user.password;
   userRights= [self.userInfo.rights intValue];
   
   // convert uuid-list to 'uuid - name' pairs
   
   NSArray* uuids= [user.availableUsers componentsSeparatedByString:@","];
   
   for (int i= 0; i < uuids.count; i++)
   {
      User* theUser= [[Storage currentStorage] userWithUUid:[uuids objectAtIndex:i]];
      
      if (!theUser)
         continue;
      
      [self.availableUsers setValue:theUser.name forKey:theUser.uuid];
   }
}

//************************************************************
// save
//************************************************************

-(BOOL)save
{
   // check if passwords match
   
   if (self.userPassword && ![self.userPassword isEqualToString:self.userConfirmedPassword])
   {
      [Service message:NSLocalizedString(@"Error", nil) withText:NSLocalizedString(@"Passwords don't match", nil) forController:nil completion:nil];
      return NO;
   }
   
   needDeletion= false;
   
   // check if a user with same name already exists
   
   NSArray* users= [[Storage currentStorage] usersWithName:self.userName];
   
   if (users)
   {
      if ((self.initialUserName && [self.initialUserName isEqualToString:self.userName] && users.count > 1)
          || (!self.initialUserName && users.count > 0 && ![self.userName isEqualToString:self.userInfo.name]))
      {
         [Service message:NSLocalizedString(@"Error", nil) withText:NSLocalizedString(@"Can't create user, a user with the same name already exists!", nil) forController:nil completion:nil];
         
         if (isInsert)
            needDeletion= true;
         
         return NO;
      }
   }

   // set values

   if ([[Settings globalSettingString:skLastUser] isEqualToString:self.userInfo.name])
      [Settings setGlobalSetting:skLastUser withString:self.userName];

   self.userInfo.color= [Service stringColor:self.userColor];
   self.userInfo.name= self.userName;
   
   if (self.userPassword.length)
      self.userInfo.password= self.userPassword.length ? [self.userPassword hashedSha2] : nil;
   
   self.userInfo.rights= [NSNumber numberWithInt:userRights];
   self.userInfo.availableUsers= [[self.availableUsers allKeys] componentsJoinedByString:@","];

   if (!(userRights & rightAdmin))
   {
      // check if we still have at least ONE admin

      int haveAdmin= NO;
      NSArray* users= [Storage userlist];

      for (int i= 0; i < users.count && !haveAdmin; i++)
      {
         User* aUser= [users objectAtIndex:i];
         
         if ([aUser.rights intValue] & rightAdmin)
            haveAdmin++;
      }
      
      if (!haveAdmin)
      {
         userRights|= rightAdmin;
         self.userInfo.rights= [NSNumber numberWithInt:userRights];
         
         if (!self.wizardMode)
         {
            // suppress warning in wizard mode - silently create admin
            
            [Service message:NSLocalizedString(@"Note", nil) withText:NSLocalizedString(@"Cannot remove admin rights from last admin user. Reverted rights back to admin rights", nil)  forController:nil completion:nil];
         }
      }
   }
   
   // almost there: append new users to admin's user list by default
   
   for (User* admin in [Storage userlist])
   {
      if (admin.rights.intValue != rightAdmin)
         continue;
      
      NSMutableArray* users= [[admin.availableUsers componentsSeparatedByString:@","] mutableCopy];
      
      if (![users containsObject:self.userInfo.uuid])
      {
         [users addObject:self.userInfo.uuid];
         admin.availableUsers= [users componentsJoinedByString:@","];
      }
      
      [users release];
   }
   
   // finally save
   
   [self.userInfo saveDocument:^(BOOL success)
    {
       if (success)
       {
          // update static service register with new user instance
       
          if ([self.userInfo.uuid isEqualToString:[SessionManager activeUser].uuid])
             [SessionManager setActiveUser:self.userInfo];
       
          [self.navigationController popViewControllerAnimated:YES];
       }
       else
       {
          [Service alert:NSLocalizedString(@"Error", nil) withText:NSLocalizedString(@"Failed to save data", nil) andError:nil forController:self completion:nil];
       }
    }];

   return YES;
}

#pragma mark - Table view data source

//************************************************************
// numberOfSectionsInTableView
//************************************************************

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
   return !self.wizardMode ? [self.menuItems count] : [self.menuItems count]-1;
}

//************************************************************
// numberOfRowsInSection
//************************************************************

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
   return [[self.menuItems objectAtIndex:section] count];
}

//************************************************************
// cellForRowAtIndexPath
//************************************************************

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
   SwitchCell* switchCell= 0;
   TextCell* textCell= 0;
   UITableViewCell* cell= 0;
   
   switch (indexPath.section) 
   {
      case 0:
      {
         if (indexPath.row == 0 || indexPath.row == 1 || indexPath.row == 2)
         {
            // name, password
            
            textCell = (TextCell*)[tableView dequeueReusableCellWithIdentifier:@"TextCell"];
            
            if (textCell == nil)
            {
               NSArray* nibContents = [[NSBundle mainBundle] loadNibNamed:@"TextCell_Small" owner:self options:nil];
               textCell = [nibContents lastObject]; 
               textCell.selectionStyle = UITableViewCellSelectionStyleNone;
               textCell.textField.delegate = self;
               textCell.backgroundColor= DARKTABLEBACKCOLOR;
               textCell.label.textColor= DARKTABLETEXTCOLOR;
               textCell.textField.textColor= DARKTABLETEXTCOLOR;
            }

            textCell.label.text= [[self.menuItems objectAtIndex:indexPath.section] objectAtIndex:indexPath.row];

            if (indexPath.row == 0)
            {
               textCell.textField.attributedPlaceholder = [[[NSAttributedString alloc] initWithString:NSLocalizedString(@"Enter title", nil) attributes:@{NSForegroundColorAttributeName:[UIColor darkGrayColor]}] autorelease];
               textCell.textField.text= self.userName;
               textCell.textField.secureTextEntry= NO;
            }
            else if (indexPath.row == 1)
            {
               textCell.textField.attributedPlaceholder = [[[NSAttributedString alloc] initWithString:NSLocalizedString(@"Enter password", nil) attributes:@{NSForegroundColorAttributeName:[UIColor darkGrayColor]}] autorelease];
               textCell.textField.text= nil; // self.userPassword;
               textCell.textField.secureTextEntry= YES;
               passwordField= textCell.textField;
            }
            else
            {
               textCell.textField.attributedPlaceholder = [[[NSAttributedString alloc] initWithString:NSLocalizedString(@"Confirm password", nil) attributes:@{NSForegroundColorAttributeName:[UIColor darkGrayColor]}] autorelease];
               textCell.textField.text= nil; // self.userPassword;
               textCell.label.text= nil;
               textCell.textField.secureTextEntry= YES;
               passwordConfirmField= textCell.textField;
            }
            
            return textCell;
         }
         
         break;
      }
         
      case 1:
      {
         if (indexPath.row == 0)
         {
            // admin switch
            
            switchCell = (SwitchCell*)[tableView dequeueReusableCellWithIdentifier:@"SwitchCell"];
            
            if (switchCell == nil)
            {
               NSArray* nibContents = [[NSBundle mainBundle] loadNibNamed:@"SwitchCell_Small" owner:self options:nil];
               switchCell = [nibContents lastObject]; 
               switchCell.selectionStyle = UITableViewCellSelectionStyleNone;
               switchCell.backgroundColor= DARKTABLEBACKCOLOR;
               switchCell.label.textColor= DARKTABLETEXTCOLOR;
            }

            switchCell.vSwitch.enabled= !isRestrictedMode;
            switchCell.vSwitch.on= (userRights & rightAdmin);
            switchCell.label.text= [[self.menuItems objectAtIndex:indexPath.section] objectAtIndex:indexPath.row];
            
            switchCell.valueChanged= ^(BOOL value)
            {
               if (value)
                  userRights |= rightAdmin;
               else
                  userRights = userRights & ~rightAdmin;
            };
            
            return switchCell;
         }
        
         break;
      }
         
      default:
         break;
   }
   
   cell = [tableView dequeueReusableCellWithIdentifier:@"Cell"];
   
   if (cell == nil)
   {
      cell= [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleValue1 reuseIdentifier:@"Cell"] autorelease];
      cell.backgroundColor= DARKTABLEBACKCOLOR;
      cell.textLabel.textColor= DARKTABLETEXTCOLOR;
   }

   cell.textLabel.text= [[self.menuItems objectAtIndex:indexPath.section] objectAtIndex:indexPath.row];
   
   if (indexPath.row == 3)
   {
      // color
      
      cell.detailTextLabel.text= NSLocalizedString(@"Selection", nil);
      cell.detailTextLabel.textColor= self.userColor;
   }         
   else if (indexPath.row == 1)
   {
      // user visibility
      
      cell.detailTextLabel.text= [[self.availableUsers allValues] componentsJoinedByString:@", "];
      cell.userInteractionEnabled= !isRestrictedMode;
   }         
   
   return cell;
}

// ************************************************************
// titleForHeaderInSection
// ************************************************************

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section 
{
   if (!section)
      return NSLocalizedString(@"User details", nil);

   return NSLocalizedString(@"Rights", nil);
}

#pragma mark - Table view delegate

//************************************************************
// didSelectRowAtIndexPath
//************************************************************

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
   switch (indexPath.section) 
   {
      case 0:
      {
         if (indexPath.row == 3)
         {
            // color
            
            ColorPickerController* dvc= [[ColorPickerController alloc] initWithColor:self.userColor fullColor:YES];
            
            dvc.delegate= self;
            
            [self.navigationController pushViewController:dvc animated:YES];
            
            [dvc release];
         }
         
         break;
      }
         
      case 1:
      {
         if (indexPath.row == 1)
         {
            NSArray* users= [Storage userlist];
            bitarray selection;
            memset(selection, 0, sizeof(bitarray));
            
            int n= 0;
            
            for (User* user in users)
            {
               if ([self.availableUsers valueForKey:user.uuid])
                  BITOP(selection, n, |=);
               
               n++;
            }
            
            ActionTable* actionTable= [[[ActionTable alloc] initWithValues:[users mutableArrayValueForKeyPath:@"name"] andSelection:&selection] autorelease];
  
            actionTable.selectionChanged= ^(bitarray* newSelection)
            {
               int n= 0;
               
               for (User* user in users)
               {
                  if (BITOP(*newSelection, n, &))
                     [self.availableUsers setValue:user.name forKey:user.uuid];
                  else
                     [self.availableUsers removeObjectForKey:user.uuid];
                  
                  n++;
               }
               
               [self.tableView reloadRowsAtIndexPaths:[NSArray arrayWithObject:indexPath] withRowAnimation:UITableViewRowAnimationAutomatic];
            };
            
            [actionTable show];
            
            break;
         }
      }
         
      default:
         break;
   }
}

#pragma mark - Other delegates

// ************************************************************
// colorPickerViewController
// ************************************************************

-(void)setSelectedColor:(UIColor *)aColor
{
   self.userColor= aColor;
   
   [self.tableView reloadData];
}

// ************************************************************
// setSelection
// ************************************************************

-(void)setSelection:(NSArray *)keys withValues:(NSArray*)values
{
   self.availableUsers= [NSMutableDictionary dictionaryWithObjects:values forKeys:keys];
}

#pragma mark -
#pragma mark UITextField delegate

// ************************************************************
// shouldChangeCharactersInRange
// ************************************************************

- (void)textFieldDidBeginEditing:(UITextField *)textField
{
   editName= textField != passwordField && textField != passwordConfirmField;
   editPassword= textField == passwordField;
}

// ************************************************************
// shouldChangeCharactersInRange
// ************************************************************

- (BOOL)textField:(UITextField *)aTextField shouldChangeCharactersInRange:(NSRange)range replacementString:(NSString *)string 
{
   return [Service textField:aTextField shouldChangeCharactersInRange:range replacementString:string andType:tpText andFormatter:nil andDelegate:self];
}

// ************************************************************
// textFieldShouldReturn
// ************************************************************

- (BOOL)textFieldShouldReturn:(UITextField *)field 
{
   if (field != passwordConfirmField && passwordConfirmField && editPassword)
   {
      [passwordConfirmField becomeFirstResponder];
      editName= NO;
      editPassword= NO;
   }
   
   else if (field != passwordField && field != passwordConfirmField && passwordField)
   {
      [passwordField becomeFirstResponder];
      editName= NO;
      editPassword= YES;
   }

   [field resignFirstResponder];

   return YES;
}

// ************************************************************
// saveText
// ************************************************************

-(void) saveText:(NSString *)newText fromTextField:(UITextField*)aTextField
{
   if (editName)
      self.userName= newText;
   else if (editPassword)
      self.userPassword= newText;
   else
      self.userConfirmedPassword= newText;
}

// ************************************************************
// textFieldShouldClear
// ************************************************************

- (BOOL)textFieldShouldClear:(UITextField *)textField
{
   if (editName)
      self.userName= nil;
   else if (editPassword)
      self.userPassword= nil;
   else
      self.userConfirmedPassword= nil;

   return YES;
}

@end
