//************************************************************
// Service.m
// Annual Leave iPad
//************************************************************
// Created by Patrick Fial on 07.06.2010
// Copyright 2010-2012 Patrick Fial. All rights reserved.
//************************************************************

#import "Service.h"
#import "Settings.h"
#import <QuartzCore/QuartzCore.h>
#import "Category.h"
#import "YearSummary.h"
#import "AppDelegate.h"
#import "Pool.h"
#import "Timetable.h"
#import "User.h"
#import "AppDelegate.h"

#include <sys/types.h>
#include <sys/sysctl.h>

//************************************************************
// global
//************************************************************

int isEmpty(NSString* string)
{
   return (!string || !string.length);
}

#pragma mark - Class UIDevice(Hardware)

//************************************************************
// class UIDevice
//************************************************************

@implementation UIDevice(Hardware)

- (NSString *) platform
{
   int mib[2];
   size_t len;
   char *machine;
   
   mib[0] = CTL_HW;
   mib[1] = HW_MACHINE;
   sysctl(mib, 2, NULL, &len, NULL, 0);
   machine = malloc(len);
   sysctl(mib, 2, machine, &len, NULL, 0);
   
   NSString *platform = [NSString stringWithCString:machine encoding:NSASCIIStringEncoding];
   free(machine);
   
   if ([platform isEqualToString:@"iPhone1,1"]) return @"iPhone 1G";
   if ([platform isEqualToString:@"iPhone1,2"]) return @"iPhone 3G";
   if ([platform isEqualToString:@"iPhone2,1"]) return @"iPhone 3GS";
   if ([platform isEqualToString:@"iPhone3,1"]) return @"iPhone 4";
   if ([platform isEqualToString:@"iPhone3,2"]) return @"iPhone 4";
   if ([platform isEqualToString:@"iPhone4,1"])    return @"iPhone 4S";
   if ([platform isEqualToString:@"iPhone3,3"])    return @"Verizon iPhone 4";
   if ([platform isEqualToString:@"iPod1,1"])   return @"iPod Touch 1G";
   if ([platform isEqualToString:@"iPod2,1"])   return @"iPod Touch 2G";
   if ([platform isEqualToString:@"iPod3,1"])   return @"iPod Touch 3G";
   if ([platform isEqualToString:@"i386"])   return @"Simulator";
   if ([platform isEqualToString:@"iPad1,1"])      return @"iPad";
   if ([platform isEqualToString:@"iPad2,1"])      return @"iPad 2 (WiFi)";
   if ([platform isEqualToString:@"iPad2,2"])      return @"iPad 2 (GSM)";
   if ([platform isEqualToString:@"iPad2,3"])      return @"iPad 2 (CDMA)";
   if ([platform isEqualToString:@"x86_64"])       return @"Simulator";
   
   return platform;
}

@end

#pragma mark - Class Service

@implementation Service

// *****************************************
#pragma mark - statics
// *****************************************

static NSDateFormatter* dateFormatter= nil;
static NSNumberFormatter* numberFormatter= nil;
static NSDateFormatter* dateFormatterFreeday= nil;

static NSArray* defaultColors= nil;

// *****************************************
#pragma mark - formatters
// *****************************************

+(NSDateFormatter*)dateFormatter
{
   if (!dateFormatter)
   {
      dateFormatter = [[NSDateFormatter alloc] init];
      [dateFormatter setDateStyle:NSDateFormatterMediumStyle];
   }
   
   return dateFormatter;
}

+(NSNumberFormatter*)numberFormatter
{
   if (!numberFormatter)
   {
      numberFormatter = [[NSNumberFormatter alloc] init];
      [numberFormatter setNumberStyle:NSNumberFormatterDecimalStyle];
      [numberFormatter setMinimumIntegerDigits:1];
      [numberFormatter setMaximumFractionDigits:1];
   }
   
   return numberFormatter;
}

+(NSDateFormatter*)dateFormatterFreeday
{
   if (!dateFormatterFreeday)
   {
      dateFormatterFreeday = [[NSDateFormatter alloc] init];
      dateFormatterFreeday.locale = [NSLocale currentLocale];
      dateFormatterFreeday.dateFormat = [NSDateFormatter dateFormatFromTemplate:@"MMMMd" options:0 locale:[NSLocale currentLocale]];
   }
   
   return dateFormatterFreeday;
}

// *****************************************
#pragma mark - color utilities
// *****************************************

+(UIColor*) uiColor { 
   return RGB(0x42,0x5c, 0x8d);
}

+(UIColor*) uiDetailColor { 
   return RGB(0x42,0x5c, 0x8d);
}

+(UIColor*) countBackground {
   return RGB(0x8b, 0x98, 0xb3);
}

+(UIColor*) publicHolidayColor
{
   return RGB(0x77, 0x77, 0x77);   
}

+(BOOL)isColor:(UIColor*)color of:(float)r and:(float)g and:(float)b
{
   const CGFloat *components = CGColorGetComponents(color.CGColor);
   return components[0] == r && components[1] == g && components[2] == b;
}

+(BOOL)isStringColor:(NSString*)color of:(float)r and:(float)g and:(float)b
{
   NSArray* components = [color componentsSeparatedByString:@","];
   CGFloat cr = [[components objectAtIndex:0] floatValue];
   CGFloat cg = [[components objectAtIndex:1] floatValue];
   CGFloat cb = [[components objectAtIndex:2] floatValue];
   
   return cr == r && cg == g && cb == b;
}

+(NSString*)stringColor:(UIColor*)color {
   const CGFloat *components = CGColorGetComponents(color.CGColor);
   
   return [NSString stringWithFormat:@"%f,%f,%f,%f", components[0], components[1], components[2], components[3]];
}

+(UIColor*)colorString:(NSString*)string {
   NSArray *components = [string componentsSeparatedByString:@","];
   CGFloat r = [[components objectAtIndex:0] floatValue];
   CGFloat g = [[components objectAtIndex:1] floatValue];
   CGFloat b = [[components objectAtIndex:2] floatValue];
   CGFloat a = [[components objectAtIndex:3] floatValue];
   
   return [UIColor colorWithRed:r green:g blue:b alpha:a];
}

+(UIColor*) colorForState:(int)state {
   switch (state)
   {
      case 0: return [UIColor lightGrayColor];
         
      default: break;
   }
   
   return MAINCOLORDARK;
}

+(NSArray*)defaultColors
{
   if (!defaultColors)
      defaultColors= [[NSArray alloc] initWithObjects:
                      @"0.634241,0.764343,1.000000,1.000000",    // light blue
                      @"0.953333,0.612062,0.625805,1.000000",    // light red
                      @"0.675875,0.900000,0.687909,1.000000",    // light green
                      @"0.807453,0.816667,0.473476,1.000000",    // yellow
                      @"0.444877,0.734324,0.816667,1.000000",    // cyan
                      @"1.000000,0.630350,0.831301,1.000000",    // magenta
                      nil];

   return defaultColors;
}

static UIColor* whiteColor= nil;
static UIColor* blackColor= nil;
static UIColor* lightGreyColor= nil;
static UIColor* darkGreyColor= nil;

+(UIColor*)white
{
   if (!whiteColor)
      whiteColor= [[UIColor whiteColor] retain];
   
   return whiteColor;
}

+(UIColor*)black
{
   if (!blackColor)
      blackColor= [[UIColor blackColor] retain];
   
   return blackColor;
}

+(UIColor*)lightGrey
{
   if (!lightGreyColor)
      lightGreyColor= [[UIColor lightGrayColor] retain];
   
   return lightGreyColor;
}

+(UIColor*)darkGrey
{
   if (!darkGreyColor)
      darkGreyColor= [[UIColor darkGrayColor] retain];
   
   return darkGreyColor;
}

// *****************************************
#pragma mark - helper functions
// *****************************************

+(UIImage*) imageForStatus:(int)status {
   if (status == 0)
      return [UIImage imageNamed:@"planned.png"];
   
   return [UIImage imageNamed:@"approved.png"];
}

+(NSString*) titleForStatus:(int)status {
   if (status == 0)
      return NSLocalizedString(@"Planned", nil);
   
   return NSLocalizedString(@"Approved", nil);
}

+(NSString*) titleForCalendarOption:(int)status
{
   switch (status)
   {
      case calOff:     return NSLocalizedString(@"None", nil);
      case calHoliday: return NSLocalizedString(@"Holidays", nil);
      case calAll:     return NSLocalizedString(@"All", nil);
         
      default: break;
   }
   
   return nil;
}

+(UIImage*) imageForCalendarOption:(int)status
{
   switch (status)
   {
      case calOff:     return [UIImage imageNamed:@"83-calendar_small_some.png"];
      case calHoliday: return [UIImage imageNamed:@"83-calendar_small_all.png"];
      case calAll:     return [UIImage imageNamed:@"83-calendar_small.png"];
         
      default: break;
   }
   
   return nil;
}

+(NSString*) stringForDays:(int)days withFormatter:(NSDateFormatter*)formatter {
   
   NSArray* names = [formatter weekdaySymbols];
   
   NSString* res= [NSString stringWithFormat:@"%@", days & (1 << 0) ? [names objectAtIndex:0] : @""];
   
   for (int i = 1; i < 7; i++)
   {
      if (!(days & (1 << i)))
         continue;
      
      if ([res length])
         res= [NSString stringWithFormat:@"%@, %@", res, [names objectAtIndex:i]];
      else
         res= [NSString stringWithFormat:@"%@", [names objectAtIndex:i]];
   }
   
   if (![res length])
      return NSLocalizedString(@"None", nil);
   
   return res;
}

+(NSString*) stringForTimeTables:(NSMutableArray*)timeTables
{
   NSString* res= nil;
   
   if (!timeTables)
      return nil;
   
   for (int i= 0; i < timeTables.count; i++)
   {
      if ([res length])
         res= [NSString stringWithFormat:@"%@, %@", res, ((Timetable*)[timeTables objectAtIndex:i]).name];
      else
         res= [NSString stringWithFormat:@"%@", ((Timetable*)[timeTables objectAtIndex:i]).name];
   }
   
   return res;
}

+(NSString*) stringFromUUIDsForTimeTables:(NSMutableArray*)timeTables
{
   NSString* res= nil;
   
   if (!timeTables)
      return nil;
   
   for (int i= 0; i < timeTables.count; i++)
   {
      if ([res length])
         res= [NSString stringWithFormat:@"%@,%@", res, ((Timetable*)[timeTables objectAtIndex:i]).uuid];
      else
         res= [NSString stringWithFormat:@"%@", ((Timetable*)[timeTables objectAtIndex:i]).uuid];
   }
   
   return res;
}

+(int) getLeaveYearForDate:(NSDate*)date 
{
   NSCalendar* cal= [NSCalendar currentCalendar];
   
   // get year from date parameter
   
   int inYear= (int)[[cal components:NSCalendarUnitYear fromDate:date] year];
   int yearBeginMonth= [Settings userSettingInt:skYearBegin];
   NSDateComponents* comps= [[[NSDateComponents alloc] init] autorelease];
   comps.day = 1;
   comps.year = inYear;
   comps.month = yearBeginMonth;
   
   NSDate* yearStartDate= [cal dateFromComponents:comps];
   
//   // patch configured beginning of the year with date's year
//
//   NSDateComponents* outComps= [cal components:NSCalendarUnitMonth|NSCalendarUnitDay fromDate:yearBeginDate];
//   [outComps setYear:inYear];
//
//   NSDate* yearStartDate= [cal dateFromComponents:outComps];

   // check if (date >= yearBegin)
   
   if ([date timeIntervalSinceDate:yearStartDate] >= 0)
      return inYear;
   
   return inYear - 1;
}

+(NSDate*) getExpirationForYear:(int)year
{
   NSCalendar* cal= [NSCalendar currentCalendar];
   
   // patch configured beginning of the year with our own year
   
   NSDateComponents* comps= [cal components:NSCalendarUnitMonth|NSCalendarUnitDay fromDate:[Settings userSettingObject:skResidualExpiration]];
   [comps setYear:year];
   
   return [cal dateFromComponents:comps];
}

+(void) setRedCell:(UITableViewCell*)cell 
{
   cell.backgroundColor= [UIColor redColor];
   cell.textLabel.textColor= [UIColor whiteColor];
   [[cell textLabel] setTextAlignment: NSTextAlignmentCenter];
}

+(void) unsetRedCell:(UITableViewCell*)cell
{
   cell.backgroundColor= [UIColor whiteColor];
   cell.textLabel.textColor= [UIColor blackColor];
   [[cell textLabel] setTextAlignment: NSTextAlignmentLeft];
}

+(void) adjustLabel:(UILabel*)label withDetailLabel:(UILabel*) detailLabel {
   
   int padding = 20;
   int offset = 0;
   
   // resize main label
   
//   UIFont* font = label.font;
   CGRect rect = label.layer.frame;
   CGSize constraintSize = CGSizeMake(rect.size.width, MAXFLOAT);
//   CGSize labelSize = [label.text sizeWithFont:font constrainedToSize:constraintSize lineBreakMode:NSLineBreakByWordWrapping];
   
   CGSize labelSize= [label.text boundingRectWithSize:constraintSize options:0 attributes:nil context:nil].size;
   
   offset = (labelSize.width + 20) - rect.size.width;
   label.layer.frame = CGRectMake(rect.origin.x - offset, rect.origin.y,  labelSize.width + padding, rect.size.height);
   
   if (detailLabel)
   {
      // resize detail label
      
      [Service adjustLabel:detailLabel withDetailLabel:nil];
      
      // adjust to new offset of main label
      
      rect = detailLabel.layer.frame;
      rect.origin.x -= offset;
      
      detailLabel.layer.frame = rect;
   }
}

+(NSDate*) trunc:(NSDate*)date
{
   NSCalendar* cal = [NSCalendar currentCalendar];
   NSDateComponents* comps = [cal components:(NSCalendarUnitDay | NSCalendarUnitMonth | NSCalendarUnitYear) fromDate:date];
   
   return [cal dateFromComponents:comps];
}

+ (BOOL)date:(NSDate*)date isBetweenDate:(NSDate*)beginDate andDate:(NSDate*)endDate
{
   if (!date || !beginDate || !endDate)
      return NO;

   if ([date compare:beginDate] == NSOrderedAscending)
      return NO;
   
   if ([date compare:endDate] == NSOrderedDescending)
      return NO;
   
   return YES;
}

+(NSString*) pluralOfDouble:(double)value {
   if (value == 1.0 || value == -1.0)
      return @"";
   
   return @"s";
}

+(NSString*) pluralOfInt:(int)value {
   if (value == 1 || value == -1)
      return @"";
   
   return @"s";
}

+(NSString*)niceDays:(double)duration
{
   double days = duration;
   NSNumber* d = [NSNumber numberWithDouble:days];
   
   if (days == 1.0 || days == -1.0)
      return [NSString stringWithFormat:@"%@ %@", [[Service numberFormatter] stringFromNumber:d], NSLocalizedString(@"day", nil)];
   
   return [NSString stringWithFormat:@"%@ %@", [[Service numberFormatter] stringFromNumber:d], NSLocalizedString(@"days", nil)];
}

+(NSString*)niceHours:(double)duration
{
   double hours = duration;
   NSNumber* h = [NSNumber numberWithDouble:hours];
   
   if (hours == 1.0 || hours == -1.0)
      return [NSString stringWithFormat:@"%@ %@", [[Service numberFormatter] stringFromNumber:h], NSLocalizedString(@"hour", nil)];
   
   return [NSString stringWithFormat:@"%@ %@", [[Service numberFormatter] stringFromNumber:h], NSLocalizedString(@"hours", nil)];
}

+(NSString*)niceDuration:(double)duration
{
   if ([Settings userSettingInt:skUnit])
      return [Service niceHours:duration];
   
   return [Service niceDays:duration];
}

+(NSString*)niceDuration:(double)duration withCategory:(CategoryRef*)c
{
   bool hours= c ? [[c savedAsHours] boolValue] : [Settings userSettingInt:skUnit];
   
   if (hours)
      return [Service niceHours:duration];
   
   return [Service niceDays:duration];
}

+(NSString*) rangeStringForDate:(NSDate*)begin end:(NSDate*)end
{
   bool same= [begin isEqualToDate:end];
   
   if (same)
      return [NSString stringWithFormat:@"%@", [dateFormatter stringFromDate:begin]];
   
   return [NSString stringWithFormat:@"%@ - %@", [dateFormatter stringFromDate:begin], [dateFormatter stringFromDate:end]];
}

+ (NSString *)createUUID
{
   CFUUIDRef uuid = CFUUIDCreate(NULL);
   CFStringRef uuidStr = CFUUIDCreateString(NULL, uuid);
   CFRelease(uuid);
   [(NSString *)uuidStr autorelease];
  
   return (NSString *)uuidStr;
}

+(UIKeyboardType) keyboardTypeForType:(int)type
{
   switch (type)
   {
         
      case tpText:    return UIKeyboardTypeDefault;
      case tpDecimal:
      case tpNumber:  return UIKeyboardTypeNumbersAndPunctuation;
      case tpInteger: return UIKeyboardTypeNumbersAndPunctuation; 
         
      default: break;
   }
   return UIKeyboardTypeDefault;
}

// ************************************************************
//  groupObjectsInArray
// ************************************************************

+(NSDictionary*)groupObjectsInArray:(NSArray *)array byKey:(id<NSCopying> (^)(id item))keyForItemBlock
{
   NSMutableDictionary *groupedItems = [[NSMutableDictionary new] autorelease];
   
   for (id item in array)
   {
      id <NSCopying> key = keyForItemBlock(item);
      NSParameterAssert(key);
      
      NSMutableArray* arrayForKey = groupedItems[key];
      
      if (arrayForKey == nil)
      {
         arrayForKey = [[NSMutableArray new] autorelease];
         groupedItems[key] = arrayForKey;
      }
      
      [arrayForKey addObject:item];
   }
   
   return groupedItems;
}

// *****************************************
#pragma mark - error reporting
// *****************************************

+(void)alert:(NSString*) title withText:(NSString*)text andError:(NSError*)error forController:(UIViewController*)controller completion:(void (^)(void))completion
{
   AppDelegate* del= (AppDelegate*)[UIApplication sharedApplication].delegate;
   UIViewController* theController = controller ? controller : del.window.rootViewController;
   
   if (!title)
      return;
   
   if (error)
   {
      NSString* errortext;
      
      if (text)
         errortext= [NSString stringWithFormat:@"%@, '%@' - '%@' - '%@'", text, [error localizedDescription], [error localizedFailureReason], [error localizedRecoverySuggestion]];
      else
         errortext= [NSString stringWithFormat:@"'%@' - '%@' - '%@'", [error localizedDescription], [error localizedFailureReason], [error localizedRecoverySuggestion]];
   
      if (!controller)
         NSLog(@"ERROR: '%@' - '%@'", title, errortext);
      else
      {
         UIAlertController* alert= [UIAlertController alertControllerWithTitle:title message:errortext preferredStyle:UIAlertControllerStyleAlert];
         [alert addAction:[UIAlertAction actionWithTitle:NSLocalizedString(@"Okay", nil) style:UIAlertActionStyleCancel handler:nil]];
         [theController presentViewController:alert animated:YES completion:completion];
         alert.view.tintColor = MAINCOLORDARK;
      }

      NSLog(@"%@", [error userInfo]);
   }
   else
   {
      if (!controller)
         NSLog(@"ERROR: '%@' - '%@'", title, text);
      else
      {
         UIAlertController* alert= [UIAlertController alertControllerWithTitle:title message:text preferredStyle:UIAlertControllerStyleAlert];
         [alert addAction:[UIAlertAction actionWithTitle:NSLocalizedString(@"Okay", nil) style:UIAlertActionStyleCancel handler:nil]];
         [theController presentViewController:alert animated:YES completion:completion];
         alert.view.tintColor = MAINCOLORDARK;
      }
   }
}

+(void)message:(NSString*) title withText:(NSString*)text forController:(UIViewController*)controller completion:(void (^)(void))completion
{
   AppDelegate* del= (AppDelegate*)[UIApplication sharedApplication].delegate;
   UIViewController* theController = controller ? controller : del.window.rootViewController;
   
   if (!title)
      return;
   
   if (!controller)
      NSLog(@"INFO: '%@' - '%@'", title, text);
   else
   {
      UIAlertController* alert= [UIAlertController alertControllerWithTitle:title message:text preferredStyle:UIAlertControllerStyleAlert];
      [alert addAction:[UIAlertAction actionWithTitle:NSLocalizedString(@"Okay", nil) style:UIAlertActionStyleCancel handler:nil]];
      
      [theController presentViewController:alert animated:YES completion:completion];
      alert.view.tintColor = MAINCOLORDARK;
   }
}


+(void)alertQuestion:(NSString*)title message:(NSString*) message cancelButtonTitle:(NSString*)cancelButtonTitle okButtonTitle:(NSString*)okButtonTitle action:(void(^)(UIAlertAction* action))action
{
   AppDelegate* del= (AppDelegate*)[UIApplication sharedApplication].delegate;
   UIAlertController* actionSheet= [UIAlertController alertControllerWithTitle:title message:message preferredStyle:UIAlertControllerStyleAlert];
   
   [actionSheet addAction:[UIAlertAction actionWithTitle:okButtonTitle style:UIAlertActionStyleDefault handler:action]];
   [actionSheet addAction:[UIAlertAction actionWithTitle:cancelButtonTitle style:UIAlertActionStyleCancel handler:nil]];
   
   [del.window.rootViewController presentViewController:actionSheet animated:YES completion:nil];
   actionSheet.view.tintColor = MAINCOLORDARK;
}

// *****************************************
#pragma mark - Cell specific
// *****************************************

+(BOOL)textField:(UITextField *)aTextField shouldChangeCharactersInRange:(NSRange)range replacementString:(NSString *)string andType:(int)type andFormatter:(NSNumberFormatter*)formatter andDelegate:(id<TextInputCellDelegate>)aDelegte 
{
   if (!aDelegte)
      return NO;
   
   if (![string length] || type == tpText || (isnumber([string characterAtIndex:0]) && type == tpNumber))
   {
      [aDelegte saveText:[aTextField.text stringByReplacingCharactersInRange:range withString:string] fromTextField:aTextField];
      
      return YES;
   }
   
   if (!formatter)
      return NO;
   
   char c = [string characterAtIndex:0]; 
   BOOL isSep = [string isEqualToString:[formatter decimalSeparator]];
   BOOL isMinus = [string isEqualToString:@"-"];
   NSRange sep;
   sep.location = NSNotFound;
   sep.length = 0;
   
   if ([aTextField.text length])
      sep = [aTextField.text rangeOfString:[formatter decimalSeparator]];
   
   if (isMinus)
   {
      // allow '-' only if type is tpNumber and field is empty
      
      if (type != tpNumber)
         return NO;
      
      if ([aTextField.text length])
         return NO;
      
      [aDelegte saveText:[aTextField.text stringByReplacingCharactersInRange:range withString:string] fromTextField:aTextField];
      return YES;
   }
   
   if (isnumber(c) || ((type == tpDecimal || type == tpNumber) && isSep && sep.location == NSNotFound))
   {
      // allow separator for decimal and number, but only if not in text already
      
      if (!isSep && sep.location != NSNotFound && type == tpDecimal)
      {
         // round after , (only for decimal type)
         
         NSString* text = [NSString stringWithFormat:@"%@%@", aTextField.text, string];
         double num = [[formatter numberFromString:text] doubleValue];
         double res = ((int)(num / 0.5)) * 0.5;
         aTextField.text = [formatter stringFromNumber:[NSNumber numberWithDouble:res]];
         
         [aDelegte saveText:aTextField.text fromTextField:aTextField];
         
         return NO;
      }
      
      [aDelegte saveText:[NSString stringWithFormat:@"%@%@", aTextField.text, string] fromTextField:aTextField];
      
      return YES;
   }
   
   [aDelegte saveText:[NSString stringWithFormat:@"%@%@", aTextField.text, string] fromTextField:aTextField];
   
   return NO;
}

@end



