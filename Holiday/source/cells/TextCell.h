//
//  TextCell.h
//  Annual Leave iPad
//
//  Created by Patrick Fial on 05.01.12.
//  Copyright (c) 2012 Informationsdesign AG. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface TextCell : UITableViewCell

@property (nonatomic, retain) IBOutlet UITextField* textField;
@property (nonatomic, retain) IBOutlet UILabel* label;

- (void) startEditing;

@end
