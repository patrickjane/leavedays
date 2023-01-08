//
//  TextInputMultilineCell.m
//  Annual leave
//
//  Created by Winston Churchill on 17.06.10.
//  Copyright 2010 Patrick Fial. All rights reserved.
//

#import "TextInputMultilineCell.h"


@implementation TextInputMultilineCell

@synthesize mainText;
@synthesize textView;
//@synthesize delegate;


//- (void) initDelegate {
//  textView.delegate = self;   
//}

//- (void)textViewDidChange:(UITextView *)aTextView {
//   UITableView* view = (UITableView*)[self superview];
//   NSIndexPath* index =  [view indexPathForCell:self];
//
//   if (delegate)
//      [delegate setNewText:aTextView.text forIndex:index];
//}

- (void)dealloc 
{
   [mainText release];
   [textView release];
   
   [super dealloc];
}

- (void) startEditing {
   
   [self.textView becomeFirstResponder];
}

//- (BOOL)textViewShouldEndEditing:(UITextView *)aTextView {
//   
////   NSLog(@"should end");
//   
//   if ([aTextView becomeFirstResponder])
//      [aTextView	 resignFirstResponder];
//   
//   return YES;
//}

@end
