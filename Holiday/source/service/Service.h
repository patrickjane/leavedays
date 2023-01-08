//************************************************************
// Service.h
// Annual Leave iPad
//************************************************************
// Created by Patrick Fial on 07.06.2010
// Copyright 2010-2012 Patrick Fial. All rights reserved.
//************************************************************

#import <Foundation/Foundation.h>
#import <EventKit/EventKit.h>

#define RGB(r, g, b) [UIColor colorWithRed:r/255.0 green:g/255.0 blue:b/255.0 alpha:1]

#define PROVERSION 1
#define SECONDS_PER_DAY 86400

static int iCloudAvailable;
static int iCloudReady;
static int coreDataReady;

int isEmpty(NSString* string);

// cell specific

enum Type
{
   tpText = 0,
   tpInteger,
   tpDecimal,
   tpNumber
};

enum Unit
{
   uDays,
   uHours
};

enum LeaveMode
{
   lmSpend,
   lmEarn
};

enum CalendarOptions
{
   calFirst= 0,
   
   calOff= calFirst,
   calHoliday,
   calAll,
   
   calLast
};

enum PoolMode
{
   pmEdit,
   pmDisplayAvail,
   pmDisplaySpent,
   pmDisplayRemaining
};

enum CalendarColoring
{
   ccByUser= 0,
   ccByCategory,
   ccAuto
};

enum LeaveOption
{
   loFirst= 0,
   
   loCategory= loFirst,        // 0
   loTimetable,                // 1
   loYear,                     // 2
   loLocation,                 // 3
   loState,                    // 4
   loComment,                  // 5
   loMail,                     // 6
   loUnknown,                  // 7
   loCalc,                     // 8
   loOwner,                    // 9
   
   cntLeaveOptions
};

//************************************************************
// tableview functions (implemented in main.cc)
//************************************************************

typedef struct StructRowInfo
{
   int index;
   int row;
   int section;
   
   NSString* title;
   NSString* image;
   
} RowInfo;

typedef struct StructSectionInfo
{
   int index;
   int rows;
   
   NSString* header;
   NSString* footer;
   
} SectionInfo;

SectionInfo* sectInit(SectionInfo* ifo, int rows, NSString* header, NSString* footer);
RowInfo* rowInit(RowInfo* ifo, int idx, int section, int row, NSString* title, NSString* image);

int isCell(int index, NSIndexPath* indexPath, RowInfo** infos);
int toCell(NSIndexPath* indexPath, RowInfo** infos);
NSIndexPath* toIndexPath(int index, RowInfo** infos);
NSString* cellText(NSIndexPath* index, RowInfo** infos);
NSString* cellTextFromIndex(int index, RowInfo** infos);
NSString* deviceName(void);

#define ISCELL(a) isCell(a, indexPath, rowInfos)
#define CELLTEXT cellText(indexPath, rowInfos)

//************************************************************


@protocol TextInputCellDelegate <NSObject>
@required
- (void)saveText:(NSString*)newText fromTextField:(UITextField*)textField;
@end


@class Pool;
@class CategoryRef;
@class YearSummary;
@class NSManagedObjectContext;
@class Timetable;
@class User;

@interface UIDevice(Hardware)

- (NSString *) platform;

@end

@interface Service : NSObject 

// formatters

+(NSDateFormatter*)dateFormatter;
+(NSNumberFormatter*)numberFormatter;
+(NSDateFormatter*)dateFormatterFreeday;

// color utilities

+(UIColor*) uiColor;
+(UIColor*) uiDetailColor;
+(UIColor*) countBackground;
+(UIColor*) publicHolidayColor;

+(BOOL)isColor:(UIColor*)color of:(float)r and:(float)g and:(float)b;
+(BOOL)isStringColor:(NSString*)color of:(float)r and:(float)g and:(float)b;
+(NSString*)stringColor:(UIColor*)color;
+(UIColor*) colorString:(NSString*)string;
+(UIColor*) colorForState:(int)state;

+(NSArray*)defaultColors;

+(UIColor*)white;
+(UIColor*)black;
+(UIColor*)darkGrey;
+(UIColor*)lightGrey;

// helpers

+(UIImage*) imageForStatus:(int)status;
+(NSString*) titleForStatus:(int)status;
+(NSString*) titleForCalendarOption:(int)status;
+(UIImage*) imageForCalendarOption:(int)status;


+(NSString*) stringForDays:(int)days withFormatter:(NSDateFormatter*)formatter;
+(NSString*) stringForTimeTables:(NSMutableArray*)timeTables;
+(NSString*) stringFromUUIDsForTimeTables:(NSMutableArray*)timeTables;

+(int) getLeaveYearForDate:(NSDate*)date;
+(NSDate*) getExpirationForYear:(int)year;
+(void) setRedCell:(UITableViewCell*)cell;
+(void) unsetRedCell:(UITableViewCell*)cell;
+(void) adjustLabel:(UILabel*)label withDetailLabel:(UILabel*) detailLabel;

+(NSDate*) trunc:(NSDate*)date;
+ (BOOL)date:(NSDate*)date isBetweenDate:(NSDate*)beginDate andDate:(NSDate*)endDate;

+(NSString*)pluralOfDouble:(double)value;
+(NSString*)pluralOfInt:(int)value;

+(NSString*)niceDuration:(double)duration withCategory:(CategoryRef*)c;
+(NSString*)niceDuration:(double)duration;
+(NSString*)niceHours:(double)duration;
+(NSString*)niceDays:(double)duration;

+(NSString*) rangeStringForDate:(NSDate*)begin end:(NSDate*)end;

+(NSString*)createUUID;

+(UIKeyboardType) keyboardTypeForType:(int)type;

+(NSDictionary*)groupObjectsInArray:(NSArray *)array byKey:(id<NSCopying> (^)(id item))keyForItemBlock;

// error reporting

+(void)alert:(NSString*) title withText:(NSString*)text andError:(NSError*)error forController:(UIViewController*)controller completion:(void (^)(void))completion;
+(void)message:(NSString*) title withText:(NSString*)text forController:(UIViewController*)controller completion:(void (^)(void))completion;
+(void)alertQuestion:(NSString*)title message:(NSString*) message cancelButtonTitle:(NSString*)cancelButtonTitle okButtonTitle:(NSString*)okButtonTitle action:(void(^)(UIAlertAction* action))action;

// cell specific

+(BOOL)textField:(UITextField *)aTextField shouldChangeCharactersInRange:(NSRange)range replacementString:(NSString *)string andType:(int)type andFormatter:(NSNumberFormatter*)formatter andDelegate:(id<TextInputCellDelegate>)aDelegte;


@end

