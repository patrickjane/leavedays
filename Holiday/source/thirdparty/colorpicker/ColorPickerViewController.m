//
//  ColorPickerViewController.m
//  ColorPicker
//
//  Created by Gilly Dekel on 23/3/09.
//  Extended by Fabián Cañas August 2010.
//  Copyright 2010. All rights reserved.
//

#import "ColorPickerViewController.h"
#import "ColorPickerView.h"
#import "UIColor-HSVAdditions.h"
#import "Service.h"

@implementation ColorPickerViewController

@synthesize delegate, chooseButton;
#ifdef IPHONE_COLOR_PICKER_SAVE_DEFAULT
@synthesize defaultsKey;
#else
@synthesize defaultsColor;
#endif

NSString *keyForHue = @"hue";
NSString *keyForSat = @"sat";
NSString *keyForBright = @"bright";

// Implement viewDidLoad to do additional setup after loading the view, typically from a nib.

- (void)viewDidLoad 
{
   [super viewDidLoad];
   
#ifdef IPHONE_COLOR_PICKER_SAVE_DEFAULT
   
	NSUserDefaults *saveColors = [NSUserDefaults standardUserDefaults];
   
	if (defaultsKey==nil) 
   {
      self.defaultsKey = @"";
      NSLog(@"problem 0 in ColorPickerViewController.viewDidLoad");
   }
   
   NSData *colorData= [saveColors objectForKey:defaultsKey];
   UIColor *color;
   
   if (colorData!=nil) 
   {
      color = (UIColor*)[NSKeyedUnarchiver unarchiveObjectWithData:colorData];
   }
#endif
   
   [self.chooseButton setTitle:NSLocalizedString(@"Save", nil) forState:UIControlStateNormal];
   [self.chooseButton setTitle:NSLocalizedString(@"Save", nil) forState:UIControlStateHighlighted];
   [self.chooseButton setTitle:NSLocalizedString(@"Save", nil) forState:UIControlStateDisabled];
   [self.chooseButton setTitle:NSLocalizedString(@"Save", nil) forState:UIControlStateSelected];
   
   [self moveToDefault];   // Move the crosshair to the default setting
   
   self.view.backgroundColor= RGB(211, 213, 219);
   
   self.preferredContentSize= CGSizeMake(320.0, 460.0);
}

-(void) moveToDefault {
   ColorPickerView *theView = (ColorPickerView*) [self view];
#ifdef IPHONE_COLOR_PICKER_SAVE_DEFAULT
   NSUserDefaults *saveColors = [NSUserDefaults standardUserDefaults];
   NSData *colorData= [saveColors objectForKey:defaultsKey];
   UIColor *color;
   if (colorData!=nil) {
      color = (UIColor*)[NSKeyedUnarchiver unarchiveObjectWithData:colorData];
   }
   [theView setColor:color];
#else
   [theView setColor:defaultsColor];
#endif
}

//- (void) viewWillDisappear :(BOOL)animated { 
//
//}

- (UIColor *) getSelectedColor 
{
	return [(ColorPickerView *) [self view] getColorShown];
}

- (IBAction) chooseSelectedColor {
   [delegate colorPickerViewController:self didSelectColor:[self getSelectedColor]];
}

- (void)didReceiveMemoryWarning {
   [super didReceiveMemoryWarning]; // Releases the view if it doesn't have a superview
   // Release anything that's not essential, such as cached data
}

//// Housekeeping actions when a view as unloaded
//- (void)viewDidUnload {
//   // Release any retained subviews of the main view.
//#if ___IPHONE_OS_VERSION_MAX_ALLOWED >= 30000
//   [super viewDidUnload];  // First super, from iOS 3 on
//   
//   self.chooseButton=nil;   // Same as release, but also setting it to nil
//#endif
//   
//   return;
//}



- (void)dealloc {
   // Release claimed resources also
#ifdef IPHONE_COLOR_PICKER_SAVE_DEFAULT
   [defaultsKey release];
#else
   [defaultsColor release];
#endif
   self.chooseButton=nil;   // Same as release, but also setting it to nil
   
   [super dealloc];
}

@end
