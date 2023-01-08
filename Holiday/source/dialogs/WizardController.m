//************************************************************
// WizardController.m
// Holiday
//************************************************************
// Created by Patrick Fial on 03.10.2015
// Copyright 2015-2015 Patrick Fial. All rights reserved.
//************************************************************

//************************************************************
// includes
//************************************************************

#import "WizardController.h"
#import "Settings.h"
#import "SessionManager.h"
#import "User.h"
#import "YearSummary.h"
#import "Pool.h"
#import "Service.h"
#import "EventService.h"
#import "PublicHoliday.h"
#import "Calculation.h"

//************************************************************
// class WizardController
//************************************************************

@implementation WizardController

@synthesize textFieldDaysPerYear, textFieldPassword, textFieldResidual;
@synthesize textFieldUser, textViewNotes, scrollView, pageControl;
@synthesize labelCreateUser, labelICloud, switchICloud, textViewICloudInfo;
@synthesize buttonBack, buttonNext, labelICloudLoading, activityICloud;
@synthesize switchSingleUserMode, pages, pageTitles, textViewIntro;
@synthesize activityHoliday, labelPublicHoliday, buttonSelectHoliday;
@synthesize textFieldPublicHoliday, labelHolidayLoading;

#pragma mark - LifeCycle

//************************************************************
// initWithNibName
//************************************************************

-(id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
   self= [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
   
   if (self)
   {
      [self baseInit];
   }
   
   return self;
}

//************************************************************
// initWithCoder
//************************************************************

-(id)initWithCoder:(NSCoder *)aDecoder
{
   self= [super initWithCoder:aDecoder];
   
   if (self)
   {
      [self baseInit];
   }
   
   return self;
}

//************************************************************
// baseInit
//************************************************************

-(void)baseInit
{
   currentPage= 0;
   
   self.pages= [NSMutableArray array];
   self.pageTitles= [NSArray arrayWithObjects:
                     NSLocalizedString(@"Welcome", nil),
//                     NSLocalizedString(@"iCloud sync", nil),
                     NSLocalizedString(@"User settings", nil),
                     NSLocalizedString(@"Annual leave", nil),
                     NSLocalizedString(@"Finish", nil),
                     nil];
}

//************************************************************
// deallocncludes
//************************************************************

-(void)dealloc
{
   self.pageTitles= nil;
   self.pages= nil;
   
   [super dealloc];
}

//************************************************************
// viewDidLoad
//************************************************************

- (void)viewDidLoad
{
   [super viewDidLoad];

   // layout scrollview sub-pages
   
   self.scrollView.frame = CGRectMake(self.scrollView.frame.origin.x, self.scrollView.frame.origin.y, [[UIScreen mainScreen] bounds].size.width, self.scrollView.frame.size.height);
   self.scrollView.contentSize= CGSizeMake(4 * self.scrollView.frame.size.width, self.scrollView.frame.size.height);

   for (int i= 0; i < 5; i++)
   {
      if (i == 1)
         continue;
      
      NSString* nibName= [NSString stringWithFormat:@"WizardPage%d", i+1];
      UIView* page =[[[NSBundle mainBundle] loadNibNamed:nibName owner:self options:nil] lastObject];
      
      if (!page)
      {
         NSLog(@"ERROR: Could not find wizard page %d with nib name '%@'", i ,nibName);
         continue;
      }
      
      page.frame= CGRectMake((i > 1 ? i-1 : i) * self.scrollView.frame.size.width, 0.0, self.scrollView.frame.size.width, self.scrollView.frame.size.height);
      
      [self.scrollView addSubview:page];
   }
   
   self.pageControl.numberOfPages = self.pageTitles.count;
   
   // inital states

   self.navigationItem.hidesBackButton= YES;
   self.navigationItem.title= [self.pageTitles objectAtIndex:currentPage];

   self.textFieldPassword.delegate= self;
   self.textFieldUser.delegate= self;
   self.textFieldDaysPerYear.delegate= self;
   self.textFieldResidual.delegate= self;
   
   self.buttonBack.hidden= YES;
   
   self.activityICloud.hidden= YES;
   self.labelICloudLoading.hidden= YES;
   
   if (![Settings globalSettingBool:skICloudAvailable])
   {
      self.switchICloud.enabled= NO;
      self.labelICloud.text= NSLocalizedString(@"iCloud not available", nil);
   }
   
   self.labelCreateUser.hidden= YES;
   self.textFieldPassword.hidden= YES;
   self.textFieldUser.hidden= YES;
   self.textViewNotes.hidden= YES;
   
   self.segmentUnit.selectedSegmentTintColor = MAINCOLORDARK;
   
   // localized button/label/etc titles
   
   [self.buttonBack setTitle:NSLocalizedString(@"Back", nil) forState:UIControlStateNormal];
   [self.buttonBack setTitle:NSLocalizedString(@"Back", nil) forState:UIControlStateHighlighted];
   [self.buttonBack setTitle:NSLocalizedString(@"Back", nil) forState:UIControlStateDisabled];
   [self.buttonBack setTitle:NSLocalizedString(@"Back", nil) forState:UIControlStateSelected];

   [self.buttonNext setTitle:NSLocalizedString(@"Next", nil) forState:UIControlStateNormal];
   [self.buttonNext setTitle:NSLocalizedString(@"Next", nil) forState:UIControlStateHighlighted];
   [self.buttonNext setTitle:NSLocalizedString(@"Next", nil) forState:UIControlStateDisabled];
   [self.buttonNext setTitle:NSLocalizedString(@"Next", nil) forState:UIControlStateSelected];

   [self.buttonFinish setTitle:NSLocalizedString(@"Finish", nil) forState:UIControlStateNormal];
   [self.buttonFinish setTitle:NSLocalizedString(@"Finish", nil) forState:UIControlStateHighlighted];
   [self.buttonFinish setTitle:NSLocalizedString(@"Finish", nil) forState:UIControlStateDisabled];
   [self.buttonFinish setTitle:NSLocalizedString(@"Finish", nil) forState:UIControlStateSelected];

//   self.textViewIntro.text= NSLocalizedString(@"This wizard will guide you through the basic settings of the app to get you started.\n\nYou can always just skip this step and configure all options in the app settings.\n\nContents:\n\n• iCloud sync\n• User setup\n• Annual leave\n", nil);
   self.textViewIntro.text= NSLocalizedString(@"This wizard will guide you through the basic settings of the app to get you started.\n\nYou can always just skip this step and configure all options in the app settings.\n\nContents:\n\n• User setup\n• Annual leave\n", nil);
   self.textViewIntro.textColor= [UIColor darkGrayColor];
   self.textViewICloudInfo.text= NSLocalizedString(@"Enabling iCloud will sync your data across all devices using iCloud.", nil);
   
   self.textViewICloudInfo.textColor= [UIColor darkGrayColor];
   self.labelCreateUser.text= NSLocalizedString(@"Create first user", nil);
   self.textFieldUser.placeholder= NSLocalizedString(@"Username", nil);
   self.textFieldPassword.placeholder= NSLocalizedString(@"Password", nil);
   self.textViewNotes.text= NSLocalizedString(@"Please note that all data is only stored on THIS DEVICE, not online.\n\nPlease safely store your password, there is no way to recover it if it gets lost.", nil);
   self.textViewNotes.textColor= [UIColor darkGrayColor];
   
   self.labelDaysPerYear.text= NSLocalizedString(@"Days per year", nil);
   self.labelResidual.text= NSLocalizedString(@"Residual leave", nil);
   self.textFieldDaysPerYear.placeholder= NSLocalizedString(@"Number of days per year", nil);
   self.textFieldResidual.placeholder= NSLocalizedString(@"Number of days from previous year", nil);
   self.labelUnit.text= NSLocalizedString(@"Unit", nil);
   [self.segmentUnit setTitle:NSLocalizedString(@"Days", nil) forSegmentAtIndex:0];
   [self.segmentUnit setTitle:NSLocalizedString(@"Hours", nil) forSegmentAtIndex:1];
   
   self.labelPublicHoliday.text = NSLocalizedString(@"Public holiday", nil);
   self.labelHolidayLoading.text = NSLocalizedString(@"Loading events ...", nil);
   
   [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(refreshPublicHolidayDisplay) name:kPublicHolidayEntriesLoaded object:nil];
}

//************************************************************
// viewWillAppear
//************************************************************

-(void)viewWillAppear:(BOOL)animated
{
   if (editPublicHoliday)
   {
      editPublicHoliday= NO;
      
      [Settings setUserSetting:skUsePublicHolidayCalendar withBool:NO];
      [Settings setUserSetting:skPublicHolidayCountry withObject:nil];
      [Settings setUserSetting:skPublicHolidayIndentifier withObject:nil];
      
      [EventService setPublicHolidayCalendar:nil];
      [[PublicHoliday instance] clearCache];
      self.textFieldPublicHoliday.text= nil;
   }
}

#pragma mark - Interaction

//************************************************************
// switchSingleUser
//************************************************************

-(IBAction)switchSingleUser:(id)sender
{
   User* user= [SessionManager wizardUser];
   UISwitch* vSwitch= sender;
   
   [Settings setGlobalSetting:skSingleUser withBool:vSwitch.on];
   
   if ([Storage userlist].count)
      return;
   
   textFieldUser.hidden= vSwitch.on;
   textFieldPassword.hidden= vSwitch.on;
   textViewNotes.hidden= vSwitch.on;
   labelCreateUser.hidden= vSwitch.on;
   user.isSingleUser = vSwitch.on;
   
   if (vSwitch.on)
   {
      user.name= NSLocalizedString(@"Default user", nil);
      user.password= nil;
   }
}

//************************************************************
// switchICloud
//************************************************************

-(IBAction)switchICloud:(id)sender
{
   UISwitch* vSwitch= sender;
   
   [Settings setGlobalSetting:skUseICloud withBool:vSwitch.on];
   
   if (vSwitch.on)
   {
      self.buttonNext.enabled= NO;
      self.buttonBack.enabled= NO;
      
      self.switchICloud.enabled= NO;
      self.activityICloud.hidden= NO;
      [self.activityICloud startAnimating];
      
      self.labelICloudLoading.hidden= NO;
      self.labelICloudLoading.text= NSLocalizedString(@"Loading existing users from iCloud ...", nil);

      [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(iCloudStorageInitialized:) name:kICloudStorageInitialized object:nil];
      
      NSLog(@"Before iCloud load: %d users in storage", (int)[Storage userlist].count);
      
      [[Storage currentStorage] reloadUsers:nil];
   }
   else
   {
      [[Storage currentStorage] forgetUsers];
      
      self.activityICloud.hidden= YES;
      [self.activityICloud stopAnimating];
      
      self.labelICloudLoading.hidden= YES;
      
      self.textFieldDaysPerYear.text= nil;
      self.textFieldResidual.text= nil;
   }
}

//************************************************************
// segmentUnit
//************************************************************

-(IBAction)segmentUnit:(id)sender
{
   UISegmentedControl* segment= sender;
   
   [Settings setTempUserSetting:skUnit withInt:(int)segment.selectedSegmentIndex ofUser:[SessionManager wizardUser]];

   if (segment.selectedSegmentIndex)
   {
      self.textFieldDaysPerYear.placeholder= NSLocalizedString(@"Number of hours per year", nil);
      self.textFieldResidual.placeholder= NSLocalizedString(@"Number of hours from previous year", nil);
   }
   else
   {
      self.textFieldDaysPerYear.placeholder= NSLocalizedString(@"Number of days per year", nil);
      self.textFieldResidual.placeholder= NSLocalizedString(@"Number of days from previous year", nil);
   }
}

//************************************************************
// popPage
//************************************************************

-(IBAction)popPage:(id)sender
{
   [self.navigationController popViewControllerAnimated:YES];
}

//************************************************************
// finish
//************************************************************

-(IBAction)finish:(id)sender
{
   [Settings setGlobalSetting:skFirstRun withBool:NO];

   User* wizardUser= [SessionManager wizardUser];
   
   NSLog(@"WIZARD FINISHED");
   
   if ([Settings globalSettingBool:skUseICloud])
   {
      NSLog(@"WIZARD FINISHED - use iCloud");
      
      if ([Storage userlist].count)
      {
         NSLog(@"WIZARD FINISHED - use iCloud - existing users");
         
         // pre-existing users incoming via iCloud
         
         [SessionManager setWizardUser:nil];       // evaporate, you!
         
         wizardUser= [Storage userlist].firstObject;
         wizardUser.isSingleUser = [Settings globalSettingBool:skSingleUser];
         
         NSLog(@"WIZARD FINISHED - use iCloud - saving user back to icloud....");
         
         [wizardUser saveDocument:^(BOOL success) {
            NSLog(@"WIZARD FINISHED - use iCloud - saved user back to icloud");
            [[SessionManager session] login:wizardUser withAutoLogin:NO];
            
            [Calculation recalculateYearSummary:[SessionManager currentYear] withLastYearRemain:0.0 setRemain:false completion:^(BOOL success)
             {
                [self.navigationController dismissViewControllerAnimated:YES completion:nil];
             }];
         }];
      }
      else
      {
         // no pre-existing users. save dummy wizard user to iCloud NOW
         
         NSLog(@"WIZARD FINISHED - use iCloud - create initial user");
         
         [wizardUser saveToICloud:^(BOOL success)
          {
             if (success)
             {
                [[SessionManager session] login:wizardUser withAutoLogin:NO];
                
                [Calculation recalculateYearSummary:[SessionManager currentYear] withLastYearRemain:0.0 setRemain:false completion:^(BOOL success)
                 {
                    [self.navigationController dismissViewControllerAnimated:YES completion:nil];
                 }];
             }
             else
             {
                [Service alert:NSLocalizedString(@"Error", nil) withText:NSLocalizedString(@"Failed to save data", nil) andError:nil forController:self completion:nil];
             }
          }];
      }
   }
   else
   {
      // local storage only. create first user.
      
      NSLog(@"WIZARD FINISHED - DONT use iCloud. create first local user");
      
      [[Storage currentStorage] addUser:wizardUser];
      
      [wizardUser saveDocument:^(BOOL success)
       {
          if (success)
          {
             [[SessionManager session] login:wizardUser withAutoLogin:NO];
             
             [Calculation recalculateYearSummary:[SessionManager currentYear] withLastYearRemain:0.0 setRemain:false completion:^(BOOL success)
              {
                 [self.navigationController dismissViewControllerAnimated:YES completion:nil];
              }];
          }
          else
          {
             [Service alert:NSLocalizedString(@"Error", nil) withText:NSLocalizedString(@"Failed to save data", nil) andError:nil forController:self completion:nil];
          }
       }];
   }
}

#pragma mark - iCloud/Storage callbacks

// ************************************************************
// iCloudStorageInitialized
// ************************************************************

-(void)iCloudStorageInitialized:(id)sender
{
   self.buttonNext.enabled= YES;
   self.buttonBack.enabled= YES;
   
   self.switchICloud.enabled= YES;
   self.activityICloud.hidden= YES;
   [self.activityICloud stopAnimating];
   
   self.labelICloudLoading.text= [NSString stringWithFormat:@"%d %@", (int)[Storage userlist].count, NSLocalizedString(@"existing users loaded from iCloud", nil)];
   
   if ([Storage userlist])
   {
      User* existingICloudUser= [Storage userlist].firstObject;
      YearSummary* year= existingICloudUser.years.firstObject;
      Pool* residual= year.pools.firstObject;
      
      if (year)
         self.textFieldDaysPerYear.text= [[Service numberFormatter] stringFromNumber:year.days_per_year];
      
      if (residual)
         self.textFieldResidual.text= [[Service numberFormatter] stringFromNumber:residual.pool];
   }
   else
   {
      self.textFieldDaysPerYear.text= nil;
      self.textFieldResidual.text= nil;
   }
}

#pragma mark - TextField delegate

// ************************************************************
// textFieldShouldReturn
// ************************************************************

- (BOOL)textFieldShouldReturn:(UITextField *)textField
{
   User* user= [SessionManager wizardUser];
   
   if (textField == self.textFieldUser)
   {
      [self.textFieldPassword becomeFirstResponder];
      
      user.name= self.textFieldUser.text;
      return NO;
   }
   else if (textField == self.textFieldPassword)
   {
      user.password= self.textFieldPassword.text;
   }
   else if (textField == self.textFieldDaysPerYear)
   {
      [self.textFieldResidual becomeFirstResponder];
   }
   
   [textField resignFirstResponder];
   
   return YES;
}

// ************************************************************
// textFieldShouldBeginEditing
// ************************************************************

-(BOOL)textFieldShouldBeginEditing:(UITextField *)textField
{
   if (textField != self.textFieldDaysPerYear && textField != self.textFieldResidual)
      return YES;
   
   if ([textField.text isEqualToString:@"0"])
      textField.text= nil;
   
   return YES;
}

// ************************************************************
// textFieldDidEndEditing
// ************************************************************

-(void)textFieldDidEndEditing:(UITextField *)textField
{
   if (textField != self.textFieldDaysPerYear && textField != self.textFieldResidual)
      return;

   if (!textField.text || !textField.text.length)
      textField.text= @"0";
}

// ************************************************************
// shouldChangeCharactersInRange
// ************************************************************

- (BOOL)textField:(UITextField *)textField shouldChangeCharactersInRange:(NSRange)range replacementString:(NSString *)string
{
   if (textField != self.textFieldDaysPerYear && textField != self.textFieldResidual)
      return YES;

   return [Service textField:textField shouldChangeCharactersInRange:range replacementString:string andType:tpDecimal andFormatter:[Service numberFormatter] andDelegate:self];
}

#pragma mark - TextInputCellDelegate

// ************************************************************
// saveText
// ************************************************************

-(void)saveText:(NSString *)newText fromTextField:(UITextField *)textField
{
   User* user= [SessionManager wizardUser];
   YearSummary* sum= user.years.firstObject;
   Pool* residual= sum.pools.firstObject;
   
   if (textField == self.textFieldDaysPerYear)
   {
      sum.days_per_year= [[Service numberFormatter] numberFromString:newText];
   }
   else if (textField == self.textFieldResidual)
   {
      residual.pool= [[Service numberFormatter] numberFromString:newText];
   }
   
   double total= [sum.days_per_year doubleValue];
   total += [[sum.pools valueForKeyPath:@"@sum.pool"] doubleValue];
   
   [sum setAmount_with_pools:[NSNumber numberWithDouble:total]];
}

#pragma mark - Navigation

// ************************************************************
// prevPage
// ************************************************************

-(IBAction)nextPage:(id)sender
{
   currentPage++;
   
   if (![EventService haveCalendarAccess])
   {
      self.buttonSelectHoliday.enabled= NO;
      self.textFieldPublicHoliday.placeholder= NSLocalizedString(@"Access to calendars must be granted", nil);
   }
   else
   {
      self.buttonSelectHoliday.enabled= YES;
      self.textFieldPublicHoliday.placeholder= NSLocalizedString(@"Please select a calendar", nil);
   }
   
   if (currentPage == 3)
   {
      self.buttonNext.hidden= YES;
      self.pageControl.hidden= YES;
   }

   self.navigationItem.title= [self.pageTitles objectAtIndex:currentPage];
   self.buttonBack.hidden= NO;
   self.pageControl.currentPage= currentPage;
   
   [self.scrollView scrollRectToVisible:CGRectMake(self.scrollView.frame.size.width * currentPage, 0.0, self.scrollView.frame.size.width, self.scrollView.frame.size.height) animated:YES];
}

// ************************************************************
// prevPage
// ************************************************************

-(IBAction)prevPage:(id)sender
{
   currentPage--;
   
   if (currentPage == 0)
      self.buttonBack.hidden= YES;

   self.navigationItem.title= [self.pageTitles objectAtIndex:currentPage];
   self.buttonNext.hidden= NO;
   self.pageControl.hidden= NO;
   self.pageControl.currentPage= currentPage;
   
   [self.scrollView scrollRectToVisible:CGRectMake(self.scrollView.frame.size.width * currentPage, 0.0, self.scrollView.frame.size.width, self.scrollView.frame.size.height) animated:YES];
}

#pragma mark - Public Holiday

// ************************************************************
// countriesLoaded
// ************************************************************

-(void)refreshPublicHolidayDisplay
{
   self.buttonSelectHoliday.enabled = YES;
   self.labelHolidayLoading.hidden = YES;
   self.activityHoliday.hidden = YES;
}

// ************************************************************
// selectCountry
// ************************************************************

-(IBAction)selectCountry:(id)sender
{
   EKCalendarChooser* picker= [[[EKCalendarChooser alloc] initWithSelectionStyle:EKCalendarChooserSelectionStyleSingle displayStyle:EKCalendarChooserDisplayAllCalendars entityType:EKEntityTypeEvent eventStore:[EventService eventStore]] autorelease];
   
   picker.delegate= self;
   picker.selectedCalendars = [NSSet set];
   
   [self.navigationController pushViewController:picker animated:YES];
   editPublicHoliday= YES;
}

#pragma mark - EKCalendarChooserDelegate

// ************************************************************
// calendarChooserSelectionDidChange
// ************************************************************

-(void)calendarChooserSelectionDidChange:(EKCalendarChooser*)calendarChooser
{
   editPublicHoliday= FALSE;
   
   [self.navigationController popViewControllerAnimated:YES];
   
   EKCalendar* cal= [[calendarChooser.selectedCalendars allObjects] firstObject];
   
   if (!cal)
   {
      [Settings setUserSetting:skUsePublicHolidayCalendar withBool:NO];
      [Settings setUserSetting:skPublicHolidayCountry withObject:nil];
      [Settings setUserSetting:skPublicHolidayIndentifier withObject:nil];
      
      [EventService setPublicHolidayCalendar:nil];
      [[PublicHoliday instance] clearCache];
      self.textFieldPublicHoliday.text= nil;
      
      return;
   }
   
   [Settings setUserSetting:skUsePublicHolidayCalendar withBool:YES];
   [Settings setUserSetting:skPublicHolidayIndentifier withObject:cal.calendarIdentifier];
   [Settings setUserSetting:skPublicHolidaySource withObject:cal.source.sourceIdentifier];
   
   [EventService setPublicHolidayCalendar:cal];
   [[PublicHoliday instance] reloadEntries];
   
   self.textFieldPublicHoliday.text= cal.title;
   
   self.buttonSelectHoliday.enabled = NO;
   self.labelHolidayLoading.hidden = NO;
   self.activityHoliday.hidden = NO;
}

//// ************************************************************
//// refreshCountry
//// ************************************************************
//
//-(void)refreshCountry
//{
//   NSString* country = [Settings userSettingObject:skPublicHolidayCountry];
//   NSString* title= country ? [[NSLocale currentLocale] displayNameForKey:NSLocaleIdentifier value:[NSString stringWithFormat:@"_%@", country]] : nil;
//   NSString* stateCd = [Settings userSettingObject:skPublicHolidayState];
//   NSDictionary* countryDict = [.countries objectForKey:country];
//
//   if (title)
//      self.textFieldCountry.text = title;
//
//   if (stateCd && countryDict && [countryDict objectForKey:@"states"])
//   {
//      NSDictionary* stateDict = [countryDict objectForKey:@"states"];
//      NSString* stateTitle = [stateDict objectForKey:stateCd];
//      self.textFieldState.text = stateTitle;
//   }
//   else
//   {
//      self.textFieldState.text = @"";
//   }
//
//}

@end
