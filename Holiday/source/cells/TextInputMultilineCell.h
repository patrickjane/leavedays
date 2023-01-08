//
//  TextInputMultilineCell.h
//  Annual leave
//
//  Created by Winston Churchill on 17.06.10.
//  Copyright 2010 Patrick Fial. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "TextCell.h"

@interface TextInputMultilineCell : UITableViewCell <UITextViewDelegate> {
   IBOutlet UILabel* mainText;
   IBOutlet UITextView* textView;
//   id <TextInputCellDelegate> delegate;
}

//- (void) initDelegate;
- (void) startEditing;

@property (nonatomic, retain) UILabel* mainText;
@property (nonatomic, retain) UITextView* textView;
//@property (nonatomic, assign) id <TextInputCellDelegate> delegate;

@end
