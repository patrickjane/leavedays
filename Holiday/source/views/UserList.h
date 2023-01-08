//************************************************************
// UserList.h
// Annual Leave iPad
//************************************************************
// Created by Patrick Fial on 29.01.12.
// Copyright 2012-2012 Patrick Fial. All rights reserved.
//************************************************************

#import <UIKit/UIKit.h>

@interface UserList : UITableViewController
{
   NSIndexPath* activeUserIndex;
   UIBarButtonItem* addButton;
}

@property (nonatomic, retain) NSIndexPath* activeUserIndex;
@property (nonatomic, retain) UIBarButtonItem* addButton;

-(void)addUser;

@end
