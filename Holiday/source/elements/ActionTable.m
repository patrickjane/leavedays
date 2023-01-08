//************************************************************
// ActionPicker.m
// Holiday
//************************************************************
// Created by Patrick Fial on 31.12.2014
// Copyright 2014-2014 Patrick Fial. All rights reserved.
//************************************************************

//************************************************************
// includes
//************************************************************

#import "ActionTable.h"
#import "AppDelegate.h"

#pragma mark - CheckButton

//************************************************************
// class CheckButton
//************************************************************

@implementation CheckButton

@synthesize checkmark;

//************************************************************
// initWithFrame
//************************************************************

-(id)initWithFrame:(CGRect)frame
{
   self= [super initWithFrame:frame];
   
   if (self)
   {
      self.checkmark= [[[UIImageView alloc] initWithImage:[UIImage imageNamed:@"checkmark.png"]] autorelease];
      [self addSubview:self.checkmark];
      self.checkmark.frame= CGRectMake(self.frame.size.width - self.checkmark.frame.size.width, self.checkmark.frame.origin.y, self.checkmark.frame.size.width, self.checkmark.frame.size.height);
   }
   
   return self;
}

//************************************************************
// setChecked
//************************************************************

-(void)setChecked:(BOOL)checked
{
   self.checkmark.hidden= !checked;
}

@end

#pragma mark - ActionTable

//************************************************************
// class ActionTable(private)
//************************************************************

@interface ActionTable()
{
   bitarray selection;
}

@property (nonatomic, retain) UIScrollView* pickerContainer;
@property (nonatomic, retain) NSArray* values;

@end

//************************************************************
// class ActionTable
//************************************************************

@implementation ActionTable

@synthesize values, pickerContainer;

#pragma mark - Lifecycle

//************************************************************
// initWithValues
//************************************************************

-(id)initWithValues:(NSArray*)aValues andSelection:(bitarray*)aSelection
{
   CGRect bounds = [[UIScreen mainScreen] bounds];

   self= [super initWithFrame:bounds];
   
   if (self)
   {
      self.values= aValues;
      self.selectionChanged= nil;
      
      self.backgroundColor= [UIColor colorWithRed:0.0 green:0.0 blue:0.0 alpha:0.4];

      memcpy(selection, aSelection, sizeof(bitarray));

      // some calculations

      double outerSpacing= 10.0;
      double buttonHeight= 57.0;                               // same as UIActionSheet
      double buttonWidth= bounds.size.width - 2*outerSpacing;
      double buttonSpacing= 0.5;
      double cancelSpacing= 8.5;
      int numberOfButtons= (int)aValues.count + 1;
      int maxButtons= 9;
      double containerHeight= numberOfButtons > maxButtons ? maxButtons * (buttonSpacing + buttonHeight) : numberOfButtons * (buttonSpacing + buttonHeight) + cancelSpacing + outerSpacing - 1.0;
      double realHeight= numberOfButtons * (buttonSpacing + buttonHeight) + cancelSpacing + outerSpacing - 1.0;
      
      if ((int)[[UIScreen mainScreen] nativeBounds].size.height >= 2436 || (int)[[UIScreen mainScreen] nativeBounds].size.height == 1792)    // iPhone X, XS, XS max
      {
         containerHeight += 28.0;
         realHeight += 28.0;
      }

      CGRect rect= CGRectMake(0.0,
                              self.frame.size.height - containerHeight,
                              self.frame.size.width,
                              containerHeight);
      
      self.pickerContainer= [[[UIScrollView alloc] initWithFrame:rect] autorelease];
      self.pickerContainer.contentSize= CGSizeMake(self.frame.size.width, realHeight);
      self.pickerContainer.contentOffset= CGPointMake(0.0, realHeight-containerHeight);
      
      // add buttons for all keys
      
      int n= 0;

      for (NSString* key in aValues)
      {
         CheckButton* button= [[[CheckButton alloc] initWithFrame:CGRectMake(outerSpacing, n * (buttonSpacing + buttonHeight), buttonWidth, buttonHeight)] autorelease];
         
         if (!n || n == aValues.count-1)
         {
            UIBezierPath* maskPath= [UIBezierPath bezierPathWithRoundedRect:button.bounds
                                                          byRoundingCorners:!n ? (UIRectCornerTopLeft | UIRectCornerTopRight) : (UIRectCornerBottomLeft | UIRectCornerBottomRight)
                                                                cornerRadii:CGSizeMake(13.0, 13.0)];

            CAShapeLayer* maskLayer = [CAShapeLayer layer];
            maskLayer.frame = button.bounds;
            maskLayer.path = maskPath.CGPath;
            button.layer.mask = maskLayer;
         }

         button.tag= n;
         button.backgroundColor= [UIColor colorNamed:@"cellBackground"];
         [button setTitleColor:MAINCOLORDARK forState:UIControlStateNormal];
         [button setTitle:key forState:UIControlStateNormal];
         [button setChecked:BITOP(selection, n, &)];

         [button addTarget:self action:@selector(buttonClicked:) forControlEvents:UIControlEventTouchUpInside];

         [self.pickerContainer addSubview:button];
         
         n++;
      }

      // add close button
      
      UIButton* button= [[[UIButton alloc] initWithFrame:CGRectMake(outerSpacing, n * (buttonSpacing + buttonHeight) + cancelSpacing, buttonWidth, buttonHeight)] autorelease];
      button.layer.cornerRadius = 13.0;
      button.layer.masksToBounds=YES;
      button.backgroundColor= [UIColor colorNamed:@"cellBackground"];
      [button.titleLabel setFont:[UIFont boldSystemFontOfSize:button.titleLabel.font.pointSize]];
      
      [button setTitleColor:MAINCOLORDARK forState:UIControlStateNormal];
      [button setTitle:NSLocalizedString(@"Cancel", nil) forState:UIControlStateNormal];
      [button addTarget:self action:@selector(dismiss) forControlEvents:UIControlEventTouchUpInside];
      
      // add views
      
      [self.pickerContainer addSubview:button];
      [self addSubview:self.pickerContainer];

      //self.backgroundColor= [UIColor colorWithRed:0.0 green:0.0 blue:0.0 alpha:0.4];
      [self setAlpha:0.0];
   }
   
   return self;
}

//************************************************************
// includes
//************************************************************

-(void)dealloc
{
   self.pickerContainer= nil;
   self.selectionChanged= nil;
   self.values= nil;
   
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

#pragma mark - Button clicked

//************************************************************
// dismiss
//************************************************************

-(void)buttonClicked:(id)sender
{
   CheckButton* button= sender;
   
   BITOP(selection, (int)button.tag, ^=);
   [button setChecked:BITOP(selection, (int)button.tag, &)];

   if (self.selectionChanged)
      self.selectionChanged(&selection);
}

@end
