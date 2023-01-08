//************************************************************
// MapController.h
// Annual Leave iPad
//************************************************************
// Created by Patrick Fial on 13.09.11.
// Copyright 2012-2012 Patrick Fial. All rights reserved.
//************************************************************

//************************************************************
// includes
//************************************************************

#import <UIKit/UIKit.h>
#import <MapKit/MapKit.h>

#import "BasePage.h"

//************************************************************
// class MapController
//************************************************************

@interface MapController : BasePage <UIPopoverControllerDelegate,MKMapViewDelegate>
{
}

@property (nonatomic, retain) IBOutlet MKMapView* mapView;
@property (nonatomic, retain) NSMutableArray* mapAnnotations;

@end
