//************************************************************
// ActionDate.m
// Holiday
//************************************************************
// Created by Patrick Fial on 31.12.2014
// Copyright 2014-2014 Patrick Fial. All rights reserved.
//************************************************************

//************************************************************
// includes
//************************************************************

#import "ActionDate.h"
#import "AppDelegate.h"
#import "SwitchCell.h"

#define HEIGHT_CAL 140.0
#define HEIGHT_PICKER 250.0
#define HEIGHT_HALFDAY 43.0
#define SPACING 6.0
#define HEIGHT_TOTAL_SOLO (HEIGHT_PICKER + SPACING)
#define HEIGHT_TOTAL_HALFDAY (HEIGHT_PICKER + SPACING + HEIGHT_HALFDAY + SPACING)
//#define HEIGHT_TOTAL_CAL (HEIGHT_CAL + SPACING + HEIGHT_PICKER + SPACING)
//#define HEIGHT_TOTAL_CAL_HALFDAY (HEIGHT_CAL + SPACING + HEIGHT_PICKER + SPACING + HEIGHT_HALFDAY + SPACING)

//************************************************************
// Class ActionPicker
//************************************************************

@implementation ActionDate

@synthesize datePicker;

#pragma mark - Lifecycle

//************************************************************
// init
//************************************************************

-(id)initWithDate:(NSDate*)date
{
   return [self initWithDate:date andHalfDay:na];
}

-(id)initWithDate:(NSDate*)date andHalfDay:(int)halfDay
{
   CGRect bounds = [[UIScreen mainScreen] bounds];

   self= [super initWithFrame:bounds];

   if (self)
   {
      self.backgroundColor= [UIColor colorWithRed:0.0 green:0.0 blue:0.0 alpha:0.4];

      self.isHalfDay = halfDay;
      totalHeight= halfDay == na ? HEIGHT_TOTAL_SOLO : HEIGHT_TOTAL_HALFDAY;

      if ((int)[[UIScreen mainScreen] nativeBounds].size.height >= 2436 || (int)[[UIScreen mainScreen] nativeBounds].size.height == 1792)    // iPhone X, XS, XS max
         totalHeight += 28.0;

      // date picker frame

      CGRect rect= CGRectMake(0.0,
                              self.frame.size.height - totalHeight,
                              self.frame.size.width,
                              totalHeight);

      // Container

      self.pickerContainer = [[UIView alloc] initWithFrame:rect];
      self.pickerContainer.transform = CGAffineTransformMakeScale(0.95f, 1.0f);
      
      // date picker
      
      self.datePicker= [[UIDatePicker alloc] initWithFrame:CGRectMake(0.0, 0.0, bounds.size.width, HEIGHT_PICKER)];
      self.datePicker.backgroundColor = [UIColor colorNamed:@"cellBackground"];
      self.datePicker.layer.cornerRadius = 10;
      self.datePicker.layer.masksToBounds=YES;
      self.datePicker.datePickerMode= UIDatePickerModeDate;
      [self.pickerContainer addSubview:self.datePicker];
      
      // half-day switch in UITableView
      
      if (self.isHalfDay != na)
      {
         UITableView* table= [[UITableView alloc] initWithFrame:CGRectMake(0.0, HEIGHT_PICKER + SPACING, bounds.size.width, HEIGHT_HALFDAY)];
         table.dataSource= self;
         table.layer.cornerRadius= 10;
         table.layer.masksToBounds= YES;
         table.alwaysBounceVertical= NO;
         table.separatorStyle = UITableViewCellSeparatorStyleNone;
         [self.pickerContainer addSubview:table];
      }

      if (date)
          [self.datePicker setDate:date animated:NO];
      
      [self addSubview:self.pickerContainer];
      [self.pickerContainer release];
      [self.datePicker release];
      
      [self setAlpha:0.0];
      
      [self.datePicker addTarget:self action:@selector(valueChanged:) forControlEvents:UIControlEventValueChanged];
      
      self.valueChanged= nil;
   }
   
   return self;
}

-(NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
   return 1;
}

-(NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
   return 1;
}

-(UITableViewCell*)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
   SwitchCell* switchCell = (SwitchCell*)[tableView dequeueReusableCellWithIdentifier:@"SwitchCell_Small"];
   
   if (switchCell == nil)
   {
      NSArray* nibContents= [[NSBundle mainBundle] loadNibNamed:@"SwitchCell_Small" owner:self options:nil];
      switchCell = [nibContents lastObject];
      switchCell.selectionStyle = UITableViewCellSelectionStyleNone;
   }
   
   switchCell.label.text = NSLocalizedString(@"Half day", nil);
   switchCell.vSwitch.on = self.isHalfDay;
   switchCell.valueChanged= ^(BOOL value) {
      self.isHalfDay= value;
      [self valueChanged:self.datePicker];
   };
   
   return switchCell;
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

#pragma mark - Delegation

//************************************************************
// valueChanged
//************************************************************

-(void)valueChanged:(id)value
{
   UIDatePicker* picker= value;
   
   self.date = picker.date;
   
   if (self.valueChanged)
      self.valueChanged(self.date, self.isHalfDay);
}

#pragma mark - Touches

//************************************************************
// touchesBegan
//************************************************************

-(void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event
{
   UITouch* touch = [touches anyObject];
   CGPoint touchPoint = [touch locationInView:self];
   
   if (touchPoint.y < self.frame.size.height - totalHeight)
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


@end
