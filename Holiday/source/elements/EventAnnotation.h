//************************************************************
// EventAnnotation.h
// Annual Leave iPad
//************************************************************
// Created by Patrick Fial on 16.02.2012
// Copyright 2012-2012 Patrick Fial. All rights reserved.
//************************************************************

#import <MapKit/MapKit.h>

@class LeaveInfo;

@interface EventAnnotation : NSObject<MKAnnotation>
{
   LeaveInfo* info;
}

@property (nonatomic, retain) LeaveInfo* info;

@end
