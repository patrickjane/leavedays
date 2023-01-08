//
//  TextCell.m
//  Annual Leave iPad
//
//  Created by Patrick Fial on 05.01.12.
//  Copyright (c) 2012 Informationsdesign AG. All rights reserved.
//

#import "TextCell.h"

@implementation TextCell

@synthesize textField;
@synthesize label;

- (void) startEditing
{
   [self.textField becomeFirstResponder];
}

@end
