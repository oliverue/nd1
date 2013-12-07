//
//  UserDataCategory.h
//  Calculate
//
//  Created by Oliver Unter Ecker on 10/2/09.
//  Copyright 2009 Naive Design. All rights reserved.
//

#import <CoreData/CoreData.h>

@class UserDatum;

@interface UserDataCategory :  NSManagedObject  
{
}

@property (nonatomic, retain) NSString * overview;
@property (nonatomic, retain) NSString * name;
@property (nonatomic, retain) NSString * notes;
@property (nonatomic, retain) NSSet* data;
@property (nonatomic, retain) NSDate * uploadDate;
@property (nonatomic, retain) NSDate * downloadDate;
@property (nonatomic, retain) NSDate * lastUsedDate;
@property (nonatomic, retain) NSNumber * visibleToPublic;
@property (nonatomic, retain) NSNumber * useCustomURL;

@end


@interface UserDataCategory (CoreDataGeneratedAccessors)
- (void)addDataObject:(UserDatum *)value;
- (void)removeDataObject:(UserDatum *)value;
- (void)addData:(NSSet *)value;
- (void)removeData:(NSSet *)value;

@end

