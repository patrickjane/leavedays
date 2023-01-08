//************************************************************
// ActionPicker.m
// Holiday
//************************************************************
// Created by Patrick Fial on 19.05.2017
// Copyright 2017-2017 Patrick Fial. All rights reserved.
//************************************************************

//************************************************************
// includes
//************************************************************

#import "ActionPicker.h"
#import "AppDelegate.h"

//************************************************************
// Class ActionPicker
//************************************************************

@implementation ActionPicker

@synthesize items, pickerContainer, valueChanged, saveOnDismiss, currentSelection;

#pragma mark - Lifecycle

//************************************************************
// init
//************************************************************

-(id)initWithValues:(NSArray*)values andSelection:(NSString*)selection
{
   CGRect bounds = [[UIScreen mainScreen] bounds];

   self= [super initWithFrame:bounds];
   
   if (self)
   {
      self.saveOnDismiss = FALSE;
      self.backgroundColor= [UIColor colorWithRed:0.0 green:0.0 blue:0.0 alpha:0.4];

      // date picker frame
      
      CGRect rect= CGRectMake(0.0,
                              self.frame.size.height - 200 - 10.0 - 15.0,
                              self.frame.size.width,
                              200.0);
      
      UIPickerView* picker= [[UIPickerView alloc] initWithFrame:CGRectMake(0.0, 0.0, bounds.size.width, 200.0)];
      
      self.currentSelection = selection;
      self.items = values;
      self.pickerContainer = [[UIView alloc] initWithFrame:rect];
      self.pickerContainer.transform = CGAffineTransformMakeScale(0.95f, 1.0f);
      picker.delegate = self;
      picker.dataSource = self;
      
      [self.pickerContainer addSubview:picker];
      
      picker.backgroundColor = [UIColor colorNamed:@"cellBackground"];
      picker.layer.cornerRadius = 10;
      picker.layer.masksToBounds=YES;
      
      if (selection && [values indexOfObject:selection])
         [picker selectRow:[values indexOfObject:selection] inComponent:0 animated:NO];
      
      [self addSubview:self.pickerContainer];
      [self.pickerContainer release];
      [picker release];
      
      [self setAlpha:0.0];
      
      self.valueChanged= nil;
   }
   
   return self;
}

//************************************************************
// includes
//************************************************************

-(void)dealloc
{
   self.pickerContainer= nil;
   self.valueChanged= nil;
   
   [super dealloc];
}

#pragma mark - Touches

//************************************************************
// touchesBegan
//************************************************************

-(void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event
{
   UITouch* touch = [touches anyObject];
   CGPoint touchPoint = [touch locationInView:self];
   
   if (touchPoint.y < self.frame.size.height - 200)
      [self dismiss];
   
   [super touchesBegan:touches withEvent:event];
}

#pragma mark - Hide/Show

//************************************************************
// show
//************************************************************

-(void)show
{
   AppDelegate* delegate= (AppDelegate*)[UIApplication sharedApplication].delegate;
   [delegate.window addSubview:self];
   
   CGRect orig= self.pickerContainer.frame;
   self.pickerContainer.frame= CGRectMake(orig.origin.x, orig.origin.y + 300.0, orig.size.width, orig.size.height);
   
   // fade-in and add to mainwindow's view to cover whole screen
   
   [UIView animateWithDuration:0.2 animations:^()
    {
       self.alpha = 1.0f;
       self.pickerContainer.frame= orig;
    }];
}

//************************************************************
// dismiss
//************************************************************

-(void)dismiss
{
   if (self.valueChanged && self.saveOnDismiss)
      self.valueChanged(self.currentSelection);

   CGRect orig= self.pickerContainer.frame;
   
   // fade-out and remove from superview. will dealloc itself.
   
   [UIView animateWithDuration:0.2 animations:^()
    {
       self.alpha = 0.0f;
       self.pickerContainer.frame= CGRectMake(orig.origin.x, orig.origin.y + 300.0, orig.size.width, orig.size.height);
    } completion:^(BOOL finished)
    {
       if (finished)
          [self removeFromSuperview];
    }];
}

#pragma mark - UIPickerView delegate/datasource methods

//************************************************************
// didSelectRow
//************************************************************

- (void)pickerView:(UIPickerView *)pickerView didSelectRow:(NSInteger)row inComponent:(NSInteger)component
{
   self.currentSelection = [self.items objectAtIndex:row];
   
   if (self.valueChanged && !self.saveOnDismiss)
      self.valueChanged(self.currentSelection);
}

//************************************************************
// numberOfComponentsInPickerView
//************************************************************

- (NSInteger)numberOfComponentsInPickerView: (UIPickerView*)thePickerView {
   return 1;
}

//************************************************************
// numberOfRowsInComponent
//************************************************************

- (NSInteger)pickerView:(UIPickerView*)thePickerView numberOfRowsInComponent:(NSInteger)component
{
   return self.items.count;
}

//************************************************************
// titleForRow
//************************************************************

- (NSString *)pickerView:(UIPickerView *)thePickerView titleForRow:(NSInteger)row forComponent:(NSInteger)component
{
   return [self.items objectAtIndex:row];
}

@end
