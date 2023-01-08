//************************************************************
// WizardController.h
// Holiday
//************************************************************
// Created by Patrick Fial on 03.10.2015
// Copyright 2015-2015 Patrick Fial. All rights reserved.
//************************************************************

//************************************************************
// includes
//************************************************************

#import <UIKit/UIKit.h>
#import <EventKitUI/EventKitUI.h>

#import "Service.h"

//************************************************************
// class WizardController
//************************************************************

@interface WizardController : UIViewController<UITextFieldDelegate, TextInputCellDelegate, EKCalendarChooserDelegate>
{
   int currentPage;
   bool editPublicHoliday;
}

@property (nonatomic, retain) IBOutlet UITextField* textFieldUser;
@property (nonatomic, retain) IBOutlet UITextField* textFieldPassword;
@property (nonatomic, retain) IBOutlet UITextField* textFieldDaysPerYear;
@property (nonatomic, retain) IBOutlet UITextField* textFieldResidual;
@property (nonatomic, retain) IBOutlet UITextField* textFieldPublicHoliday;
//@property (nonatomic, retain) IBOutlet UITextField* textFieldState;
@property (nonatomic, retain) IBOutlet UILabel* labelPublicHoliday;
//@property (nonatomic, retain) IBOutlet UILabel* labelState;
@property (nonatomic, retain) IBOutlet UITextView* textViewIntro;
@property (nonatomic, retain) IBOutlet UITextView* textViewICloudInfo;
@property (nonatomic, retain) IBOutlet UITextView* textViewNotes;          // user creation data storage note
@property (nonatomic, retain) IBOutlet UILabel* labelCreateUser;
@property (nonatomic, retain) IBOutlet UILabel* labelICloud;
@property (nonatomic, retain) IBOutlet UILabel* labelICloudLoading;
@property (nonatomic, retain) IBOutlet UILabel* labelDaysPerYear;
@property (nonatomic, retain) IBOutlet UILabel* labelResidual;
@property (nonatomic, retain) IBOutlet UILabel* labelUnit;
@property (nonatomic, retain) IBOutlet UISegmentedControl* segmentUnit;

@property (nonatomic, retain) IBOutlet UIActivityIndicatorView* activityHoliday;
@property (nonatomic, retain) IBOutlet UILabel* labelHolidayLoading;
@property (nonatomic, retain) IBOutlet UIButton* buttonSelectHoliday;


@property (nonatomic, retain) IBOutlet UISwitch* switchICloud;
@property (nonatomic, retain) IBOutlet UISwitch* switchSingleUserMode;
@property (nonatomic, retain) IBOutlet UIActivityIndicatorView* activityICloud;

@property (nonatomic, retain) NSMutableArray* pages;
@property (nonatomic, retain) NSArray* pageTitles;

@property (nonatomic, retain) IBOutlet UIScrollView* scrollView;
@property (nonatomic, retain) IBOutlet UIPageControl* pageControl;
@property (nonatomic, retain) IBOutlet UIButton* buttonNext;
@property (nonatomic, retain) IBOutlet UIButton* buttonBack;
@property (nonatomic, retain) IBOutlet UIButton* buttonFinish;


-(IBAction)switchSingleUser:(id)sender;
-(IBAction)switchICloud:(id)sender;
-(IBAction)segmentUnit:(id)sender;
-(IBAction)finish:(id)sender;
-(IBAction)selectCountry:(id)sender;

-(IBAction)nextPage:(id)sender;
-(IBAction)prevPage:(id)sender;

@end
