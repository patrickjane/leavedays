//
//  ILGeoNamesLookup.m
//
//  Created by Claus Broch on 20/06/10.
//  Copyright 2010-2011 Infinite Loop. All rights reserved.
//
//  Redistribution and use in source and binary forms, with or without modification, are permitted
//  provided that the following conditions are met:
//
//  - Redistributions of source code must retain the above copyright notice, this list of conditions 
//    and the following disclaimer.
//  - Redistributions in binary form must reproduce the above copyright notice, this list of 
//    conditions and the following disclaimer in the documentation and/or other materials provided 
//    with the distribution.
//  - Neither the name of Infinite Loop nor the names of its contributors may be used to endorse or 
//    promote products derived from this software without specific prior written permission.
//
//  THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY EXPRESS OR 
//  IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND 
//  FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR 
//  CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL 
//  DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, 
//  DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, 
//  WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY 
//  WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
//  

#import "ILGeoNamesLookup.h"

static NSString *kILGeoNamesSearchURL = @"http://api.geonames.org/searchJSON?q=%@&maxRows=%d&startRow=%d&lang=%@&isNameRequired=true&style=FULL&username=%@";
NSString *const kILGeoNamesErrorDomain = @"org.geonames";

@interface ILGeoNamesLookup ()
@property (nonatomic, retain) NSURLSessionDataTask* dataTask;

- (void)connectionDidFinishLoadingwithError:(NSError*)error;
- (void)connectionDidFinishLoading:(NSData*)data;

@end

@implementation ILGeoNamesLookup

@synthesize userID;
@synthesize dataTask;
@synthesize delegate;

#pragma mark -
#pragma mark Data request handling

- (id)initWithUserID:(NSString*)aUserID
{
   self = [super init];
   
   if (self)
   {
      userID = [aUserID copyWithZone:nil];
   }
   
   return self;
}

- (void)dealloc
{
   [userID release];
   self.dataTask = nil;
   [super dealloc];
}

- (void)search:(NSString*)query maxRows:(NSInteger)maxRows startRow:(NSUInteger)startRow language:(NSString*)langCode
{
   NSString	*urlString;
   
   // Sanitize parameters
   
   if (!langCode)
   {
      NSBundle *bundle = [NSBundle bundleForClass:[self class]];
      NSArray	*localizations = [bundle preferredLocalizations];
      
      if([localizations count])
         langCode = [localizations objectAtIndex:0];
      else
         langCode = @"en";
   }
   
   if(maxRows > 1000)
      maxRows = 1000;
   
   // Request formatted according to http://www.geonames.org/export/geonames-search.html
   
   NSString* escQuery = [query stringByAddingPercentEncodingWithAllowedCharacters:[NSCharacterSet URLHostAllowedCharacterSet]];
   
   urlString = [NSString stringWithFormat:kILGeoNamesSearchURL, escQuery, maxRows, startRow, langCode, userID];
   
   NSURLSession* session = [NSURLSession sharedSession];
   
   if (self.dataTask)
      [self.dataTask cancel];
   
   self.dataTask = [session dataTaskWithURL:[NSURL URLWithString:urlString] completionHandler:^(NSData* data, NSURLResponse* response, NSError* error) {
      if (error)
         [self performSelectorOnMainThread:@selector(connectionDidFinishLoadingwithError:) withObject:error waitUntilDone:NO];
      else
         [self performSelectorOnMainThread:@selector(connectionDidFinishLoading:) withObject:data waitUntilDone:NO];
   }];
   
   [self.dataTask resume];
}

- (void)cancel
{
   if (self.dataTask)
      [self.dataTask cancel];
   
   self.dataTask = nil;
}


- (void)connectionDidFinishLoadingwithError:(NSError*)error {
   [self.delegate geoNamesLookup:self didFailWithError:error];
}

- (void)connectionDidFinishLoading:(NSData*)data
{
   NSDictionary* resultDict = [NSJSONSerialization JSONObjectWithData:data options:0 error:nil];
   
   if (resultDict)
   {
      NSArray *geoNames = [resultDict objectForKey:kILGeoNamesResultsKey];
      
      if (geoNames)
      {
         if (self.delegate != nil && [self.delegate respondsToSelector:@selector(geoNamesLookup:didFindGeoNames:totalFound:)])
         {
            NSArray *geoNames = [resultDict objectForKey:kILGeoNamesResultsKey];
            NSUInteger total = [geoNames count];
            
            if ([resultDict objectForKey:kILGeoNamesTotalResultsCountKey])
               total = [[resultDict objectForKey:kILGeoNamesTotalResultsCountKey] intValue];
            
            [self.delegate geoNamesLookup:self didFindGeoNames:geoNames totalFound:total];
         }
      }
      else
      {
         NSDictionary *status = [resultDict objectForKey:kILGeoNamesErrorResponseKey];
         
         if (status)
         {
            // Geonames failed to provide a result - return the status supplied in the response
            
            NSString* message = [status objectForKey:kILGeoNamesErrorMessageKey];
            NSString* value = [status objectForKey:kILGeoNamesErrorCodeKey];
            NSError* error = [NSError errorWithDomain:kILGeoNamesErrorDomain code:[value intValue] userInfo:[NSDictionary dictionaryWithObject:message forKey:NSLocalizedDescriptionKey]];
            
            [self.delegate geoNamesLookup:self didFailWithError:error];
         }
         else
         {
            // Geonames just failed on us - use a default error code
            
            NSString* message = NSLocalizedStringFromTable(@"ILGEONAMES_UNKNOWN_LOOKUP_ERR", @"ILGeoNames", @"");
            NSError* error = [NSError errorWithDomain:kILGeoNamesErrorDomain code:kILGeoNamesNoResultsFoundError userInfo:[NSDictionary dictionaryWithObject:message forKey:NSLocalizedDescriptionKey]];
            
            [self.delegate geoNamesLookup:self didFailWithError:error];
         }
      }
   }
   else
   {
      [self.delegate geoNamesLookup:self didFailWithError:nil];
   }
}

@end


NSString *const kILGeoNamesResultsKey = @"geonames";
NSString *const kILGeoNamesTotalResultsCountKey = @"totalResultsCount";

NSString *const kILGeoNamesAdminCode1Key = @"adminCode1";
NSString *const kILGeoNamesAdminCode2Key = @"adminCode2";
NSString *const kILGeoNamesAdminCode3Key = @"adminCode3";
NSString *const kILGeoNamesAdminName1Key = @"adminName1";
NSString *const kILGeoNamesAdminName2Key = @"adminName2";
NSString *const kILGeoNamesAdminName3Key = @"adminName3";
NSString *const kILGeoNamesAdminName4Key = @"adminName4";
NSString *const kILGeoNamesNameKey = @"name";
NSString *const kILGeoNamesToponymNameKey = @"toponymName";
NSString *const kILGeoNamesContinentCodeKey = @"continentCode";
NSString *const kILGeoNamesCountryCodeKey = @"countryCode";
NSString *const kILGeoNamesCountryNameKey = @"countryName";
NSString *const kILGeoNamesPopulationKey = @"population";
NSString *const kILGeoNamesTitleKey = @"title";
NSString *const kILGeoNamesSummaryKey = @"summary";
NSString *const kILGeoNamesWikipediaURLKey = @"wikipediaUrl";

NSString *const kILGeoNamesAlternateNamesKey = @"alternameNames";
NSString *const kILGeoNamesAlternateNameKey = @"name";
NSString *const kILGeoNamesAlternateLanguageKey = @"lang";

NSString *const kILGeoNamesIDKey = @"geonameId";
NSString *const kILGeoNamesFeatureKey = @"feature";
NSString *const kILGeoNamesFeatureClassKey = @"fcl";
NSString *const kILGeoNamesFeatureCodeKey = @"fcode";
NSString *const kILGeoNamesFeatureClassNameKey = @"fclName";
NSString *const kILGeoNamesFeatureNameKey = @"fcodeName";
NSString *const kILGeoNamesScoreKey = @"score";

NSString *const kILGeoNamesLatitudeKey = @"lat";
NSString *const kILGeoNamesLongitudeKey = @"lng";
NSString *const kILGeoNamesDistanceKey = @"distance";
NSString *const kILGeoNamesElevationKey = @"elevation";
NSString *const kILGeoNamesLanguageKey = @"lang";
NSString *const kILGeoNamesRankKey = @"rank";

NSString *const kILGeoNamesTimeZoneInfoKey = @"timezone";
NSString *const kILGeoNamesTimeZoneDSTOffsetKey = @"dstOffset";
NSString *const kILGeoNamesTimeZoneGMTOffsetKey = @"gmtOffset";
NSString *const kILGeoNamesTimeZoneIDKey = @"timeZoneId";

NSString *const kILGeoNamesErrorResponseKey = @"status";
NSString *const kILGeoNamesErrorMessageKey = @"message";
NSString *const kILGeoNamesErrorCodeKey = @"value";
