//************************************************************
// MapController.m
// Annual Leave iPad
//************************************************************
// Created by Patrick Fial on 13.09.11.
// Copyright 2012-2012 Patrick Fial. All rights reserved.
//************************************************************

//************************************************************
// includes
//************************************************************

#import "MapController.h"
#import "Constants.h"
#import "Service.h"
#import "User.h"
#import "YearSummary.h"
#import "Calculation.h"
#import "LeaveInfo.h"
#import "Settings.h"
#import "Storage.h"
#import "SessionManager.h"
#import "JASidePanelController.h"
#import "TabController.h"
#import "EventAnnotation.h"

//************************************************************
// class MapController(private)
//************************************************************

@interface MapController()

- (void) adjustZoom;

@end

//************************************************************
// class MapController
//************************************************************

@implementation MapController

@synthesize mapView, mapAnnotations;

//************************************************************
// initWithNibName
//************************************************************

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
   self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
   
   if (self) 
   {
      // Custom initialization
      
      self.mapAnnotations= [[[NSMutableArray alloc] init] autorelease];
      self.tabBarItem= [[[UITabBarItem alloc] initWithTitle:[self pageTitle] image:[UIImage imageNamed:@"Tab_Map.png"] tag:0] autorelease];
      
      [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(reloadByNotification) name:kLeaveChanged object:nil];
      [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(reloadByNotification) name:kYearChangedNotification object:nil];
      [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(reloadByNotification) name:kImportFinished object:nil];
   }
   
   return self;
}

//************************************************************
// dealloc
//************************************************************

-(void) dealloc
{
   self.mapAnnotations= nil;
   
   [super dealloc];
}

//************************************************************
// pageTitle
//************************************************************

-(NSString*)pageTitle
{
   return NSLocalizedString(@"Map", nil);
}

#pragma mark - View lifecycle

//************************************************************
// viewDidLoad
//************************************************************

- (void)viewDidLoad
{
   [super viewDidLoad];
   
   // add toolbar to super construction
   
   UIBarButtonItem* mapItem = [[[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemBookmarks target:self action:@selector(toggleMapType)] autorelease];
   
   [self.toolbar setItems:[NSArray arrayWithObjects:menuItem, spacer, titleItem, spacer, mapItem, addItem, nil]];
   
   self.mapView.delegate= self;
   self.mapView.mapType = [Settings userSettingInt:skLastMapType];
}

//************************************************************
// viewWillAppear
//************************************************************

-(void)viewWillAppear:(BOOL)animated
{
   [self reload];
   [self adjustZoom];
}

//************************************************************
// reload
//************************************************************

-(void)reload
{
   [self reallyReload];
}

-(void)reloadByNotification
{
   [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(reallyReload) object:nil];
   [self performSelector:@selector(reallyReload) withObject:nil afterDelay:2.0];
}

-(void)reallyReload
{
   [self.mapAnnotations removeAllObjects];
   [self.mapView removeAnnotations:self.mapView.annotations];  // remove any annotations that exist
   
   // add new ones
   
   for (LeaveInfo* info in [SessionManager displayUser].leave)
   {
      if (!info.location || ![info.location isKindOfClass:[NSDictionary class]]  || !info.location.count)
         continue;
      
      [self addMarker:info];
   }
}

//************************************************************
// addMarker
//************************************************************

-(void)addMarker:(LeaveInfo*)leaveInfo
{
   EventAnnotation* ann= [[[EventAnnotation alloc] init] autorelease];
   
   // cross link
   
   ann.info= leaveInfo;
   leaveInfo.annotation= ann;
   
   [self.mapAnnotations addObject:ann];
   [self.mapView addAnnotation:ann];
}

//************************************************************
// removeMarker
//************************************************************

-(void)removeMarker:(LeaveInfo *)leaveInfo
{
   if (!leaveInfo.annotation)
      return;
   
   [self.mapView removeAnnotation:leaveInfo.annotation];
   [self.mapAnnotations removeObject:leaveInfo.annotation];
}

//************************************************************
// toggleMapType
//************************************************************

-(void)toggleMapType
{
   int mapType= (self.mapView.mapType+1) % 3;
   
   self.mapView.mapType= mapType;
   
   [Settings setUserSetting:skLastMapType withInt:mapType];
}

#pragma mark - map adjustments

//************************************************************
// adjustZoom
//************************************************************

-(void) adjustZoom
{
   [self.mapView showAnnotations:self.mapView.annotations animated:YES];
}

#pragma mark - MapViewDelegate

//************************************************************
// viewForAnnotation
//************************************************************

- (MKAnnotationView *)mapView:(MKMapView *)theMapView viewForAnnotation:(id <MKAnnotation>)annotation
{
   // if it's the user location, just return nil.
   
   if ([annotation isKindOfClass:[MKUserLocation class]])
      return nil;
   
   // handle our two custom annotations
   //
   
   if ([annotation isKindOfClass:[EventAnnotation class]]) // for Golden Gate Bridge
   {
      // try to dequeue an existing pin view first
      
      MKPinAnnotationView* pinView = (MKPinAnnotationView *)
      [mapView dequeueReusableAnnotationViewWithIdentifier:@"eventAnnotation"];
      
      if (!pinView)
      {
         // if an existing pin view was not available, create one
         
         MKPinAnnotationView* customPinView = [[[MKPinAnnotationView alloc]
                                                initWithAnnotation:annotation reuseIdentifier:@"eventAnnotation"] autorelease];
         
         customPinView.tintColor = [UIColor redColor];
         customPinView.animatesDrop = YES;
         customPinView.canShowCallout = YES;
         
         UIButton* rightButton = [UIButton buttonWithType:UIButtonTypeDetailDisclosure];
         
//         [rightButton addTarget:self
//                         action:nil
//               forControlEvents:UIControlEventTouchUpInside];
         customPinView.rightCalloutAccessoryView = rightButton;
         
         return customPinView;
      }
      else
      {
         pinView.annotation = annotation;
      }
      
      return pinView;
   }
   
   return nil;
}

//************************************************************
// calloutAccessoryControlTapped
//************************************************************

- (void)mapView:(MKMapView *)aMapView annotationView:(MKAnnotationView *)view calloutAccessoryControlTapped:(UIControl *)control
{
   EventAnnotation* ann= view.annotation;
   LeaveInfo* info= ann.info;
   
   [[Storage currentStorage] showAddDialog:info withBegin:nil endEnd:nil andYear:0 completion:nil];
   
   [aMapView deselectAnnotation:view.annotation animated:YES];
}

@end
