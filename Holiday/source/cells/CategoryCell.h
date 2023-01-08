//
//  NumberInputCell.h
//  Vacation
//
//  Created by Patrick Fial on 28.05.10.
//  Copyright 2010 Patrick Fial. All rights reserved.
//

#import <UIKit/UIKit.h>


@interface CategoryCell : UITableViewCell {
   IBOutlet UILabel* mainText;
   IBOutlet UILabel* textReadOnly;
   IBOutlet UIImageView* firstImage;
   IBOutlet UIImageView* secondImage;
}

@property (nonatomic, retain) UILabel* mainText;
@property (nonatomic, retain) UILabel* textReadOnly;
@property (nonatomic, retain) UIImageView* firstImage;
@property (nonatomic, retain) UIImageView* secondImage;

@end
