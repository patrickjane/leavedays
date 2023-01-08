//************************************************************
// MailPrefController.m
// Holiday
//************************************************************
// Created by Patrick Fial on 18.07.2010
// Copyright 2010-2015 Patrick Fial. All rights reserved.
//************************************************************

//************************************************************
// includes
//************************************************************

#import "MailPrefController.h"
#import "TextInputMultilineCell.h"
#import "Service.h"
#import "Settings.h"

//************************************************************
// class MailPrefController
//************************************************************

@implementation MailPrefController

@synthesize menuItems;
@synthesize mailTo;
@synthesize mailCc;
@synthesize mailBcc;
@synthesize mailSubject;
@synthesize mailBody;
@synthesize editedIndex;

#pragma mark - Initialization

//************************************************************
// initWithStyle
//************************************************************

- (id)initWithStyle:(UITableViewStyle)style 
{
   if ((self = [super initWithStyle:UITableViewStyleGrouped])) 
   {
      self.editedIndex = nil;
      
      toField= ccField= bccField= subjectField= nil;
      bodyField= nil;
   }
   
   return self;
}

//************************************************************
// dealloc
//************************************************************

- (void)dealloc
{
   self.menuItems = nil;
   self.mailTo = nil;
   self.mailCc = nil;
   self.mailBcc = nil;
   self.mailSubject = nil;
   self.mailBody = nil;
   self.editedIndex = nil;
   
   [super dealloc];
}

//************************************************************
// viewDidLoad
//************************************************************

- (void)viewDidLoad 
{
   [super viewDidLoad];

   // save button
   
   self.navigationItem.title = NSLocalizedString(@"E-Mail template", nil);
   
   // menu items
   
   self.menuItems = [NSArray arrayWithObjects:
                      NSLocalizedString(@"To:", nil),
                      NSLocalizedString(@"Cc:", nil),
                      NSLocalizedString(@"Bcc:", nil),
                      NSLocalizedString(@"Subject:", nil),
                      NSLocalizedString(@"Body:", nil), nil];
   
   self.tableView.backgroundColor= DARKTABLEBACKCOLOR;
   self.tableView.separatorColor= DARKTABLESEPARATORCOLOR;
}

//************************************************************
// viewWillDisappear
//************************************************************

-(void)viewWillDisappear:(BOOL)animated
{
   [self saveMailPrefs];
   
   [super viewWillDisappear:animated];
}

#pragma mark - Table view data source

//************************************************************
// numberOfSectionsInTableView
//************************************************************

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
   return 1;
}

//************************************************************
// numberOfRowsInSection
//************************************************************

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
   return [menuItems count];
}

//************************************************************
// cellForRowAtIndexPath
//************************************************************

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
   if (indexPath.row < 4)
   {
      // title
      
      TextCell* textCell = (TextCell*)[tableView dequeueReusableCellWithIdentifier:@"TextCell"];
      
      if (textCell == nil)
      {
         NSArray* nibContents = [[NSBundle mainBundle] loadNibNamed:@"TextCell_Small" owner:self options:nil];
         textCell = [nibContents lastObject]; 
         textCell.selectionStyle = UITableViewCellSelectionStyleNone;
         textCell.textField.delegate = self;
      }
      
      textCell.textField.keyboardType= [Service keyboardTypeForType:tpText];
      textCell.label.text = [menuItems objectAtIndex:indexPath.row];
      
      textCell.backgroundColor= DARKTABLEBACKCOLOR;
      textCell.label.textColor= DARKTABLETEXTCOLOR;
      textCell.textField.textColor= UIColorFromRGB(0x8e8e93);
      
      switch (indexPath.row)
      {
         case 0: 
         {
            toField= textCell.textField;
            textCell.textField.text = self.mailTo; 
            toField.attributedPlaceholder = [[[NSAttributedString alloc] initWithString:NSLocalizedString(@"Enter receiver address", nil) attributes:@{NSForegroundColorAttributeName:[UIColor darkGrayColor]}] autorelease];
            break;
         }

         case 1:
         {
            ccField= textCell.textField;
            textCell.textField.text = self.mailCc;
            ccField.attributedPlaceholder = [[[NSAttributedString alloc] initWithString:NSLocalizedString(@"Enter cc address", nil) attributes:@{NSForegroundColorAttributeName:[UIColor darkGrayColor]}] autorelease];
            break;
         }

         case 2:
         {
            bccField= textCell.textField;
            textCell.textField.text = self.mailBcc; 
            bccField.attributedPlaceholder = [[[NSAttributedString alloc] initWithString:NSLocalizedString(@"Enter bcc address", nil) attributes:@{NSForegroundColorAttributeName:[UIColor darkGrayColor]}] autorelease];
            break;
         }

         case 3:
         {
            subjectField= textCell.textField;
            textCell.textField.text = self.mailSubject;
            subjectField.attributedPlaceholder = [[[NSAttributedString alloc] initWithString:NSLocalizedString(@"Enter subject", nil) attributes:@{NSForegroundColorAttributeName:[UIColor darkGrayColor]}] autorelease];
            break;
         }
            
         default: break;
      }
      
      return textCell;
   }
   
   // body text multiline
   
   TextInputMultilineCell* textMultilineCell = (TextInputMultilineCell*)[tableView dequeueReusableCellWithIdentifier:@"TextInputMultilineCell"];
   
   if (textMultilineCell == nil)
   {
      NSArray* nibContents = [[NSBundle mainBundle] loadNibNamed:@"TextInputMultilineCell" owner:self options:nil];
      textMultilineCell = [nibContents lastObject]; 
      textMultilineCell.selectionStyle = UITableViewCellSelectionStyleNone;
      textMultilineCell.textView.delegate = self;

      textMultilineCell.backgroundColor= DARKTABLEBACKCOLOR;
      textMultilineCell.mainText.textColor= DARKTABLETEXTCOLOR;
      textMultilineCell.textView.textColor= UIColorFromRGB(0x8e8e93);
   }
   
   bodyField= textMultilineCell.textView;
   textMultilineCell.mainText.text = [menuItems objectAtIndex:indexPath.row];
   textMultilineCell.textView.text = self.mailBody;
   
   return textMultilineCell;
}

//************************************************************
// titleForHeaderInSection
//************************************************************

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
   if (section == 0)
      return NSLocalizedString(@"E-Mail details", nil);
   
   return nil;
}

//************************************************************
// titleForFooterInSection
//************************************************************

- (NSString *)tableView:(UITableView *)tableView titleForFooterInSection:(NSInteger)section
{
   if (section == 0)
      return NSLocalizedString(@"Note: Details can be included by adding variables to the body text: $begin, $end, $duration, $title, $comment. Will be replaced before sending.", nil);
   
   return nil;
}

//************************************************************
// heightForRowAtIndexPath
//************************************************************

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
   if (indexPath.section == 0 && indexPath.row == 4)
   {
      // comments-box
      return 210;
   }
   
   // default
   
   return tableView.rowHeight;
}

//************************************************************
// didSelectRowAtIndexPath
//************************************************************

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath 
{
   switch (indexPath.section)
   {
      case 0:
      {
         // general section
         
         if (indexPath.row < 4)
         {
//            TextCell* cell = (TextCell*)[[self tableView] cellForRowAtIndexPath:indexPath];            
//            [cell startEditing];
         }
      }
         
      default: break;
   }
}

#pragma mark - save stuff

//************************************************************
// fill
//************************************************************

-(void)fill
{
   self.mailTo = [Settings userSettingObject:skMailTo];
   self.mailCc = [Settings userSettingObject:skMailCc];
   self.mailBcc = [Settings userSettingObject:skMailBcc];
   self.mailSubject = [Settings userSettingObject:skMailSubject];
   self.mailBody = [Settings userSettingObject:skMailBody];
}

//************************************************************
// saveMailPrefs
//************************************************************

-(void) saveMailPrefs
{
   [Settings transaction:tactBegin completion:nil];
   [Settings setUserSetting:skMailTo withObject:self.mailTo];
   [Settings setUserSetting:skMailCc withObject:self.mailCc];
   [Settings setUserSetting:skMailBcc withObject:self.mailBcc];
   [Settings setUserSetting:skMailSubject withObject:self.mailSubject];
   [Settings setUserSetting:skMailBody withObject:self.mailBody];

   [Settings transaction:tactEnd completion:^(BOOL success)
    {
       [[self navigationController] popViewControllerAnimated:YES];
    }];
}

#pragma mark - UITextField delegate

//************************************************************
// textFieldShouldBeginEditing
//************************************************************

-(BOOL)textFieldShouldBeginEditing:(UITextField *)textField
{
   UITableViewCell* v = (UITableViewCell*)[[textField superview] superview];
   
   self.editedIndex = [[self tableView] indexPathForCell:v];
   return YES;
}

//************************************************************
// shouldChangeCharactersInRange
//************************************************************

- (BOOL)textField:(UITextField *)aTextField shouldChangeCharactersInRange:(NSRange)range replacementString:(NSString *)string
{
   return [Service textField:aTextField shouldChangeCharactersInRange:range replacementString:string andType:tpText andFormatter:nil andDelegate:self];
}

//************************************************************
// textFieldShouldReturn
//************************************************************

- (BOOL)textFieldShouldReturn:(UITextField *)field 
{
   if (field == toField)
   {
      [ccField becomeFirstResponder];
      return NO;
   }
   
   if (field == ccField)
   {
      [bccField becomeFirstResponder];
      return NO;
   }
   
   if (field == bccField)
   {
      [subjectField becomeFirstResponder];
      return NO;
   }
   
   if (field == subjectField)
   {
      [bodyField becomeFirstResponder];
      return NO;
   }
   
   [field resignFirstResponder];
   return YES;
}

#pragma mark - UITextView delegate

//************************************************************
// textViewDidChange
//************************************************************

- (void)textViewDidChange:(UITextView *)aTextView 
{
   self.mailBody = aTextView.text;
}

#pragma mark - TextInputCell delegate

//************************************************************
// saveText
//************************************************************

-(void)saveText:(NSString *)newText fromTextField:(UITextField*)aTextField
{
   switch (self.editedIndex.row)
   {
      case 0: self.mailTo = newText;      break;
      case 1: self.mailCc = newText;      break;
      case 2: self.mailBcc = newText;     break;
      case 3: self.mailSubject = newText; break;
         
      default: break;
   }
}

@end

