//************************************************************
// BasePage.m
// Holliday
//************************************************************
// Created by Patrick Fial on 25.01.15.
// Copyright 2015-2015 Patrick Fial. All rights reserved.
//************************************************************

//************************************************************
// includes
//************************************************************

#import "Storage.h"
#import "TabController.h"
#import "JASidePanelController.h"
#import "BasePage.h"

@implementation BasePage

@synthesize toolbar;

#pragma mark - View Lifecycle


-(id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
   self= [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
   
   if (self)
   {
      CGRect bounds= [UIScreen mainScreen].bounds;
      UIView* statusbarBackground;
      
      NSLog(@"Screen bounds: %d", (int)[[UIScreen mainScreen] nativeBounds].size.height);
      
      if ((int)[[UIScreen mainScreen] nativeBounds].size.height >= 2436 || (int)[[UIScreen mainScreen] nativeBounds].size.height == 1792)    // iPhone X, XS, XS max, 12 Pro, 11?
         statusbarBackground= [[[UIToolbar alloc] initWithFrame:CGRectMake(0.0, 0.0, bounds.size.width, STATUSBARHEIGHT + 30.0)] autorelease];
      else
         statusbarBackground= [[[UIToolbar alloc] initWithFrame:CGRectMake(0.0, 0.0, bounds.size.width, STATUSBARHEIGHT)] autorelease];

      statusbarBackground.layer.masksToBounds = YES;
      
      [self.view addSubview:statusbarBackground];
   }

   return self;
}

-(void)viewDidLoad
{
   [super viewDidLoad];
   
   if (!self.toolbar)
      return;
	
   spacer=    [[[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:nil action:nil] autorelease];
   menuItem=  [[[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"Menu.png"] style:UIBarButtonItemStylePlain target:(TabController*)self.parentViewController action:@selector(handleShowMenu)] autorelease];
   addItem=   [[[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemAdd target:[Storage currentStorage] action:@selector(showAddDialog)] autorelease];
   titleItem= [[[UIBarButtonItem alloc] initWithTitle:[self pageTitle] style:UIBarButtonItemStylePlain target:nil action:nil] autorelease];

   NSArray* items= [NSArray arrayWithObjects:menuItem, spacer, titleItem, spacer, addItem, nil];
   
   self.toolbar.layer.masksToBounds = YES;
   self.toolbar.layer.cornerRadius = 0.0;
   self.toolbar.layer.shadowOffset = CGSizeMake(0, 0);
   self.toolbar.layer.shadowRadius = 2;
   self.toolbar.layer.shadowOpacity = 0.7;
   
   [self.toolbar setItems:items];
}

//************************************************************
// pageTitle
//************************************************************

-(NSString*)pageTitle
{
   return @"BasePage";
}

//************************************************************
// update
//************************************************************

-(void)update
{
   // dummy implementation
}

-(IBAction)menuButton:(id)sender
{
   [(TabController*)self.parentViewController handleShowMenu];
}

-(IBAction)addButton:(id)sender
{
   [[Storage currentStorage] showAddDialog];
}

@end
