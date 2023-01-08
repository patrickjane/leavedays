//************************************************************
// OverviewCell.m
// Holiday
//************************************************************
// Created by Patrick Fial on 08.06.2010
// Copyright 2010-2015 Patrick Fial. All rights reserved.
//************************************************************

//************************************************************
// includes
//************************************************************

#import "OverviewCell.h"
#import "LeaveInfo.h"
#import "Category.h"
#import "Service.h"
#import "Settings.h"
#import "User.h"
#import "Storage.h"
#import "SessionManager.h"

@implementation OverviewCell

@synthesize titleText;
@synthesize dateText;
@synthesize categoryText;
@synthesize ownerLabel;

// ************************************************************
// setSelected
// ************************************************************

- (void)setSelected:(BOOL)selected animated:(BOOL)animated 
{
   [super setSelected:selected animated:animated];
}

// ************************************************************
// fill
// ************************************************************

- (void) fill:(LeaveInfo*)info
{
   CategoryRef* c= [Storage categoryForName:info.category ofUser:[[Storage currentStorage] userWithUUid:info.userid]];
   
   NSString* dateString = nil;
   NSString* durationString= nil;
   NSString* completeString= nil;
   NSNumberFormatter* numberFormatter= [Service numberFormatter];
   NSInteger oldMax= [numberFormatter maximumFractionDigits];
   
   // prepare strings
   
   if ([info.isUnknownDate boolValue])
      dateString = NSLocalizedString(@"Unknown date", nil);      
   else
      dateString = [Service rangeStringForDate:info.begin end:info.end];

   if (c && [c.savedAsHours boolValue])
      [numberFormatter setMaximumFractionDigits:2];
   
   durationString= [NSString stringWithFormat:@"%@%@",
                    info.mode.intValue ? @"+" : @"",
                    [Service niceDuration:[info.duration doubleValue] withCategory:c]];

   [numberFormatter setMaximumFractionDigits:oldMax];
   
   completeString= [NSString stringWithFormat:@"%@, %@", durationString, dateString];
   
   // title ("London")

   self.titleText.text = info.title;
   self.titleText.textColor = info.status.integerValue ? [UIColor colorNamed:@"cellMainText"] : [UIColor lightGrayColor];

   // category ("Special Leave")
   
   self.categoryText.text = info.category;

   // duration + date ("8 Days, 20.12.2012 - 23.12.2012")

   self.dateText.text = completeString;

   // owner ("Peter")

   if (info.userid)
   {
      User* user= [[Storage currentStorage] userWithUUid:info.userid];
      
      if (user)
      {
         self.ownerLabel.text = user.name;
         self.ownerLabel.textColor= [Service colorString:user.color];
      }
      else
         self.ownerLabel.text= nil;
   }
   
   // category color, if available
   
   if (!c)
      self.categoryText.textColor = [UIColor blackColor];
   else 
      self.categoryText.textColor = [Service colorString:c.color];
   
   
}

// ************************************************************
// dealloc
// ************************************************************

- (void)dealloc 
{
   [super dealloc];
}


@end
