//************************************************************
// DaysView.h
// Holiday
//************************************************************
// Created by Patrick Fial on 24.07.2018
// Copyright 2018-2018 Patrick Fial. All rights reserved.
//************************************************************

//************************************************************
// includes
//************************************************************

#import "DaysView.h"
#import "Service.h"

#pragma mark - View Lifecycle

//************************************************************
// class DaysView (private)
//************************************************************

@interface DaysView()
{
   double amount;
   double spent;
   double remain;
   double earned;
}

@property (nonatomic, retain) UILabel* labelAmount;
@property (nonatomic, retain) UILabel* labelSpent;
@property (nonatomic, retain) UILabel* labelRemain;
@property (nonatomic, retain) UILabel* labelEarned;

@end

//************************************************************
// class DaysView
//************************************************************

@implementation DaysView

@synthesize labelAmount, labelSpent, labelRemain, modeShort;
@synthesize maxLengthSpent, maxLengthAmount, maxLengthEarned, maxLengthRemain;

//************************************************************
// initWithCoder
//************************************************************

-(id)initWithCoder:(NSCoder *)aDecoder
{
   self= [super initWithCoder:aDecoder];
   
   if (self)
   {
      modeShort= NO;
      amount= spent= remain= earned = 0.0;
      self.labelAmount= self.labelSpent= self.labelRemain= nil;
      self.maxLengthRemain= self.maxLengthEarned= self.maxLengthAmount= self.maxLengthSpent= nil;
   }
   
   return self;
}

//************************************************************
// dealloc
//************************************************************

-(void)dealloc
{
   [super dealloc];

   self.labelAmount= self.labelSpent= self.labelRemain= nil;
   self.maxLengthRemain= self.maxLengthEarned= self.maxLengthAmount= self.maxLengthSpent= nil;
}

//************************************************************
// setDays
//************************************************************

-(void)setValues:(double)aAmount and:(double)aSpent and:(double)aRemain and:(double)aEarned
{
   amount= aAmount;
   spent= aSpent;
   remain= aRemain;
   earned= aEarned;
   
   [self setNeedsDisplay];
}

//************************************************************
// drawRect
//************************************************************

-(void)drawRect:(CGRect)rect
{
   // calculate sizes etc.

   UIFont* font= [UIFont systemFontOfSize:12.0];
   NSMutableParagraphStyle* paragraphStyle = [[[NSParagraphStyle defaultParagraphStyle] mutableCopy] autorelease];
   paragraphStyle.alignment= NSTextAlignmentCenter;
   
   NSDictionary* attributes= @{ NSFontAttributeName:font, NSParagraphStyleAttributeName:paragraphStyle, NSForegroundColorAttributeName: [UIColor whiteColor] };

   NSString* textAmount= modeShort ? @"=" : [[Service numberFormatter] stringFromNumber:[NSNumber numberWithDouble:amount]];
   NSString* textSpent= [[Service numberFormatter] stringFromNumber:[NSNumber numberWithDouble:spent]];
   NSString* textRemain= [[Service numberFormatter] stringFromNumber:[NSNumber numberWithDouble:remain]];
   NSString* textEarned= [[Service numberFormatter] stringFromNumber:[NSNumber numberWithDouble:earned]];

   CGRect boundingRectAmountMax= [self.maxLengthAmount boundingRectWithSize:rect.size options:(NSStringDrawingUsesLineFragmentOrigin|NSStringDrawingUsesFontLeading) attributes:attributes context:nil];
   CGRect boundingRectSpentMax= [self.maxLengthSpent boundingRectWithSize:rect.size options:(NSStringDrawingUsesLineFragmentOrigin|NSStringDrawingUsesFontLeading) attributes:attributes context:nil];
   CGRect boundingRectRemainMax= [self.maxLengthRemain boundingRectWithSize:rect.size options:(NSStringDrawingUsesLineFragmentOrigin|NSStringDrawingUsesFontLeading) attributes:attributes context:nil];
   CGRect boundingRectEarnedMax= [self.maxLengthEarned boundingRectWithSize:rect.size options:(NSStringDrawingUsesLineFragmentOrigin|NSStringDrawingUsesFontLeading) attributes:attributes context:nil];
   
   CGRect boundingRectAmount= [textAmount boundingRectWithSize:rect.size options:(NSStringDrawingUsesLineFragmentOrigin|NSStringDrawingUsesFontLeading) attributes:attributes context:nil];
   CGRect boundingRectSpent= [textSpent boundingRectWithSize:rect.size options:(NSStringDrawingUsesLineFragmentOrigin|NSStringDrawingUsesFontLeading) attributes:attributes context:nil];
   CGRect boundingRectRemain= [textRemain boundingRectWithSize:rect.size options:(NSStringDrawingUsesLineFragmentOrigin|NSStringDrawingUsesFontLeading) attributes:attributes context:nil];
   CGRect boundingRectEarned= [textEarned boundingRectWithSize:rect.size options:(NSStringDrawingUsesLineFragmentOrigin|NSStringDrawingUsesFontLeading) attributes:attributes context:nil];

   double offset= 0.0;
   
   offset= [self addItem:textRemain color:remain >= 0.0 ? MAINCOLORDARK : [UIColor redColor] offset:offset andFont:font withBounding:boundingRectRemain andMaxBounding:boundingRectRemainMax within:rect textOnly:NO];
   offset= [self addItem:textSpent color:DETAILCOLOR offset:offset andFont:font withBounding:boundingRectSpent andMaxBounding:boundingRectSpentMax within:rect textOnly:NO];
   
   if (!modeShort)
      offset= [self addItem:textAmount color:[UIColor lightGrayColor] offset:offset andFont:font withBounding:boundingRectAmount andMaxBounding:boundingRectAmountMax within:rect textOnly:NO];

   if (earned > 0.0 || modeShort)
      offset= [self addItem:textEarned color:EARNCOLOR offset:offset andFont:font withBounding:boundingRectEarned andMaxBounding:boundingRectEarnedMax within:rect textOnly:NO];
}

//************************************************************
// addItem
//************************************************************

-(double)addItem:(NSString*)text color:(UIColor*)color offset:(double)offset andFont:(UIFont*)font withBounding:(CGRect)bounding andMaxBounding:(CGRect)maxBounding within:(CGRect)within textOnly:(BOOL)textOnly
{
   double spacing= 7.5;
   double minWidth = 20.0;
   
   double labelWidth = bounding.size.width + spacing;
//   double boundingDiff = maxBounding.size.width - bounding.size.width;

   if (labelWidth < minWidth)
      labelWidth= minWidth;
   
   if (textOnly)
      labelWidth -= spacing;
   
   CGRect targetRect= CGRectMake(within.size.width - offset - labelWidth - spacing,
                                 within.size.height/2 - bounding.size.height/2 - spacing/2,
                                 labelWidth,
                                 bounding.size.height + spacing);
   
   UILabel* label= [[[UILabel alloc] initWithFrame:targetRect] autorelease];
   label.text= text;
   label.font= font;
   
   if (textOnly)
      label.textColor= GREYINPUTCOLOR;
   else
      label.textColor= [UIColor whiteColor];
   
   label.textAlignment= NSTextAlignmentCenter;
   
   if (!textOnly)
      label.backgroundColor= color;
   
   label.layer.cornerRadius= 8.0;
   label.clipsToBounds= YES;

   [self addSubview:label];
   
   return within.size.width - targetRect.origin.x;
}

@end
