//
//  DarkDisclosureIndicator.h
//  Holiday
//
//  Created by Winston Churchill on 28.11.20.
//  Copyright © 2020 Patrick Fial. All rights reserved.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface DarkDisclosureIndicator : UIView

@property (nonatomic, retain) UIColor* color;

-(id)initWithFrame:(CGRect)frame;
-(id)initWithFrame:(CGRect)frame andColor:(UIColor*)color;

+(DarkDisclosureIndicator*)indicatorWithColor:(UIColor*)color forCell:(UITableViewCell*)cell;

@end

NS_ASSUME_NONNULL_END
