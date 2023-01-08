//************************************************************
// LegendView.m
// Holiday
//************************************************************
// Created by Patrick Fial on 10.03.2019
// Copyright 2019-2019 Patrick Fial. All rights reserved.
//************************************************************

//************************************************************
// includes
//************************************************************

#import "LegendView.h"
#import "SplitFillView.h"

//************************************************************
// class LegendView
//************************************************************

@implementation LegendView

@synthesize legendHeight;

//************************************************************
// initWithFrame + height
//************************************************************

-(id)initWithFrame:(CGRect)frame andLegendHeight:(double)aLegendHeight
{
   self= [super initWithFrame:frame];
   
   if (!self)
      return self;
   
   self.legendHeight= aLegendHeight;
   
   return self;

}

//************************************************************
// initWithFrame
//************************************************************

-(id)initWithFrame:(CGRect)frame
{
   self= [super initWithFrame:frame];
   
   if (!self)
      return self;
   
   self.legendHeight= 15.0;
   
   return self;
}

//************************************************************
// addLegendItem
//************************************************************

-(double)addLegendItem:(NSString*)title color:(UIColor*)color offset:(double)offset otherColor:(UIColor*)color2 skipSpacing:(BOOL)skipSpacing
{
   double itemSpacing = 16.0;
   double symbolWidth = 14.0;
   double symbolSpacing = 3.0;
   double symbolSkipSpacing = 3.0;
   
   UIFont* font= [UIFont systemFontOfSize:9.0];
   NSMutableParagraphStyle* paragraphStyle = [[[NSParagraphStyle defaultParagraphStyle] mutableCopy] autorelease];
   paragraphStyle.alignment= NSTextAlignmentCenter;
   
   NSDictionary* attributes= @{ NSFontAttributeName:font, NSParagraphStyleAttributeName:paragraphStyle, NSForegroundColorAttributeName: [UIColor whiteColor] };
   CGRect boundingRect= [title boundingRectWithSize:self.frame.size options:(NSStringDrawingUsesLineFragmentOrigin|NSStringDrawingUsesFontLeading) attributes:attributes context:nil];
   
   SpitFillView* symbol = [[[SpitFillView alloc] initWithFrame:CGRectMake(offset + (skipSpacing ? symbolSkipSpacing : itemSpacing), self.legendHeight / 2 - (symbolWidth/2), symbolWidth, symbolWidth)] autorelease];
   symbol.layer.cornerRadius= 3.0;
   symbol.clipsToBounds= YES;
   symbol.backgroundColor = color;
   symbol.backgroundColor2 = color2;
   
   [self addSubview:symbol];
   
   UILabel* text = [[UILabel alloc] initWithFrame:CGRectMake(symbol.frame.origin.x + symbolWidth + symbolSpacing, 0.0, boundingRect.size.width, self.legendHeight)];
   text.font = font;
   text.text = title;
   text.textColor = [UIColor colorNamed:@"cellSubText"];
   
   [self addSubview:text];
   
   return text.frame.origin.x + boundingRect.size.width;
}

@end

