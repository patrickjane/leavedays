//************************************************************
// EventAnnotation.m
// Annual Leave iPad
//************************************************************
// Created by Patrick Fial on 16.02.2012
// Copyright 2012-2012 Patrick Fial. All rights reserved.
//************************************************************

#import "EventAnnotation.h"
#import "LeaveInfo.h"
#import "Service.h"

@implementation EventAnnotation

@synthesize info;

//************************************************************
// coordinate
//************************************************************

- (CLLocationCoordinate2D)coordinate;
{
   CLLocationCoordinate2D theCoordinate;
   
   NSDictionary* dict= self.info.location; //[NSJSONSerialization JSONObjectWithData:[self.info.location dataUsingEncoding:NSUTF8StringEncoding] options:0 error:nil];
   
//   NSDictionary* dict= [self.info.location objectFromJSONString];

   theCoordinate.latitude= [[dict valueForKey:@"lat"] doubleValue];
   theCoordinate.longitude= [[dict valueForKey:@"lng"] doubleValue];
   
   return theCoordinate; 
}

//************************************************************
// title
//************************************************************

- (NSString *)title
{
   return self.info.title ? self.info.title : NSLocalizedString(@"<no title>", nil);
}

//************************************************************
// subtitle
//************************************************************

- (NSString *)subtitle
{
   return [Service rangeStringForDate:info.begin end:info.end];
}

//************************************************************
// dealloc
//************************************************************

- (void)dealloc
{
   self.info= nil;
   [super dealloc];
}

@end
