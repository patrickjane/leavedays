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

#import <Foundation/Foundation.h>

//************************************************************
// class NSMutableDictionary(SettingsAdditions)
//************************************************************

@interface NSMutableDictionary(SettingsAdditions)

- (BOOL)boolForKey:(NSString *)key;
- (double)doubleForKey:(NSString *)key;

- (NSInteger)integerForKey:(NSString *)key;
- (void)setBool:(BOOL)value forKey:(NSString *)key;

- (void)setDouble:(double)value forKey:(NSString *)key;
- (void)setInteger:(NSInteger)value forKey:(NSString *)key;

@end