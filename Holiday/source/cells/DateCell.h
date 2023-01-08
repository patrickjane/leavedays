//
//  DateCell.h
//  Holiday
//
//  Created by Winston Churchill on 26.11.20.
//  Copyright © 2020 Patrick Fial. All rights reserved.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface DateCell : UITableViewCell

@property (nonatomic, retain) IBOutlet UILabel* label;
@property (nonatomic, retain) IBOutlet UIDatePicker* picker;
@property (nonatomic, retain) IBOutlet UIButton* button;
@property (copy) void(^valueChanged)(NSDate*);
@property (copy) void(^halfDayValueChanged)(void);

-(IBAction)onValueChanged:(id)sender;
-(IBAction)onButtonPressed:(id)sender;

@end

NS_ASSUME_NONNULL_END
