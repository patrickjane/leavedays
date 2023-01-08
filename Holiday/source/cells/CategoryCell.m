//
//  NumberInputCell.m
//  Vacation
//
//  Created by Patrick Fial on 28.05.10.
//  Copyright 2010 Patrick Fial. All rights reserved.
//

#import "CategoryCell.h"


@implementation CategoryCell

@synthesize mainText;
@synthesize textReadOnly, firstImage, secondImage;


- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier {
    if ((self = [super initWithStyle:style reuseIdentifier:reuseIdentifier])) {
        // Initialization code
    }
    return self;
}


- (void)setSelected:(BOOL)selected animated:(BOOL)animated {

    [super setSelected:selected animated:animated];

    // Configure the view for the selected state
}


- (void)dealloc {
    [super dealloc];
}


@end
