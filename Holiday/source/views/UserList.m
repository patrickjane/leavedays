//************************************************************
// UserList.m
// Annual Leave iPad
//************************************************************
// Created by Patrick Fial on 29.01.12.
// Copyright 2012-2012 Patrick Fial. All rights reserved.
//************************************************************

//************************************************************
// includes
//************************************************************

#import "UserList.h"
#import "UserEdit.h"
#import "Service.h"
#import "User.h"
#import "LeaveInfo.h"
#import "Pool.h"
#import "YearSummary.h"
#import "Storage.h"
#import "SessionManager.h"

@implementation UserList

@synthesize activeUserIndex, addButton;

#pragma mark - lifecycle

//************************************************************
// initWithStyle
//************************************************************

- (id)initWithStyle:(UITableViewStyle)style
{
   self = [super initWithStyle:UITableViewStyleGrouped];
   
   if (self) 
   {
      // Custom initialization
      
      self.activeUserIndex= nil;
      self.addButton= nil;
   }
   
   return self;
}

//************************************************************
// dealloc
//************************************************************

- (void)dealloc
{
   [NSFetchedResultsController deleteCacheWithName:@"UserListCache"];

   self.activeUserIndex= nil;
   self.addButton= nil;
   
   [super dealloc];
}

//************************************************************
// viewDidLoad
//************************************************************

- (void)viewDidLoad
{
   [super viewDidLoad];

   self.navigationItem.title= NSLocalizedString(@"User list", nil);
   self.navigationItem.hidesBackButton = NO;
   self.navigationItem.rightBarButtonItem = self.editButtonItem;
   self.tableView.backgroundColor= DARKTABLEBACKCOLOR;
   self.tableView.separatorColor= DARKTABLESEPARATORCOLOR;
   
   self.addButton= [[[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemAdd target:self action:@selector(addUser)] autorelease];
}

// ************************************************************
// viewWilLAppear
// ************************************************************

- (void)viewWillAppear:(BOOL)animated 
{
   [[self tableView] reloadData];
   [super viewWillAppear:animated];
}

//************************************************************
// viewWillDisappear
//************************************************************

-(void)viewWillDisappear:(BOOL)animated
{
//   for (User* usr in [Storage userlist])
//      NSLog(@"UUID %@ User '%@'", usr.uuid, usr.name);
}

//************************************************************
// setEditing
//************************************************************

- (void)setEditing:(BOOL)editing animated:(BOOL)animated
{
   [super setEditing:editing animated:YES];
   
   if (editing)
      self.navigationItem.leftBarButtonItem= self.addButton;
   else
      self.navigationItem.leftBarButtonItem= self.navigationItem.backBarButtonItem;
}

#pragma mark - Add User

// ************************************************************
// addUser
// ************************************************************

-(void)addUser
{
   [[Storage currentStorage] createUser:NSLocalizedString(@"New user", nil) andPassword:@"" andUuid:nil completion:^(BOOL success, User* aUser)
    {
       if (success)
       {
          UserEdit* dvc= [[UserEdit alloc] initWithStyle:UITableViewStyleGrouped];
          
          [dvc fill:aUser];
          
          [self.navigationController pushViewController:dvc animated:YES];
          
          [dvc release];
       }
    }];
}

#pragma mark - Table view data source

//************************************************************
// numberOfSectionsInTableView
//************************************************************

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
   return 1;
}

//************************************************************
// numberOfRowsInSection
//************************************************************

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
   return [Storage userlist].count;
}

//************************************************************
// cellForRowAtIndexPath
//************************************************************

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
   UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"Cell"];
   
   if (cell == nil)
   {
      cell= [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleValue1 reuseIdentifier:@"Cell"] autorelease];
      cell.backgroundColor= DARKTABLEBACKCOLOR;
      cell.textLabel.textColor= DARKTABLETEXTCOLOR;
   }
   
   User* user= [[Storage userlist] objectAtIndex:indexPath.row];
   
   cell.textLabel.text= user.name;

   int rights= [user.rights intValue];
   
   if (rights & rightAdmin)
      cell.detailTextLabel.text= NSLocalizedString(@"Admin", nil);
   else
      cell.detailTextLabel.text= NSLocalizedString(@"User", nil);
   
   if ([user.uuid isEqualToString:[SessionManager activeUser].uuid])
      self.activeUserIndex= indexPath;
   
   return cell;
}

// ************************************************************
// canEditRowAtIndexPath
// ************************************************************

-(BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath
{
   return !self.activeUserIndex || [self.activeUserIndex compare:indexPath] != NSOrderedSame;
}

// ************************************************************
// commitEditingStyle
// ************************************************************

- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath 
{
   if (editingStyle == UITableViewCellEditingStyleDelete) 
   {
      User* user= [[Storage userlist] objectAtIndex:indexPath.row];

      if ([user.uuid isEqualToString:[SessionManager activeUser].uuid])
      {
         [Service alert:NSLocalizedString(@"Error", nil) withText:NSLocalizedString(@"Cannot delete currently active user", nil)  andError:nil forController:nil completion:nil];
         return;
      }
      
      // delete the user

      [[Storage currentStorage] deleteUser:user];
      
      [self.tableView reloadData];
   }
}

// ************************************************************
// titleForHeaderInSection
// ************************************************************

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section 
{
   return NSLocalizedString(@"Users", nil);
}

// ************************************************************
// titleForFooterInSection
// ************************************************************

- (NSString *)tableView:(UITableView *)tableView titleForFooterInSection:(NSInteger)section 
{
   return NSLocalizedString(@"Only admin users can add/delete other users.\nNote: Currently active user can not be deleted.", nil);
}

#pragma mark - Table view delegate

//************************************************************
// didSelectRowAtIndexPath
//************************************************************

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
   UserEdit* dvc= [[UserEdit alloc] initWithStyle:UITableViewStyleGrouped];

   [dvc fill:[[Storage userlist] objectAtIndex:indexPath.row]];
   
   [self.navigationController pushViewController:dvc animated:YES];
   
   [dvc release];
}

@end
