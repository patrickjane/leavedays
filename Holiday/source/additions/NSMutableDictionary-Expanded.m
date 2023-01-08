//************************************************************
// NSMutableDictionary-Expanded.h
// Holiday
//************************************************************
// Created by Patrick Fial on 02.01.2015
// Copyright 2015-2015 Patrick Fial. All rights reserved.
//************************************************************

//************************************************************
// includes
//************************************************************

#import "NSMutableDictionary-Expanded.h"

//************************************************************
// class NSMutableDictionary(SettingsAdditions)
//************************************************************

@implementation NSMutableDictionary(SettingsAdditions)

- (BOOL)boolForKey:(NSString *)key
{
   return [[self valueForKey:key] boolValue];
}

- (double)doubleForKey:(NSString *)key
{
   return [[self valueForKey:key] doubleValue];
}

- (NSInteger)integerForKey:(NSString *)key
{
   return [[self valueForKey:key] intValue];
}

- (void)setBool:(BOOL)value forKey:(NSString *)key
{
   [self setValue:[NSString stringWithFormat:@"%d", value] forKey:key];
}

- (void)setDouble:(double)value forKey:(NSString *)key
{
   [self setValue:[NSString stringWithFormat:@"%f", value] forKey:key];
}

- (void)setInteger:(NSInteger)value forKey:(NSString *)key
{
   [self setValue:[NSString stringWithFormat:@"%ld", (long)value] forKey:key];
}

@end