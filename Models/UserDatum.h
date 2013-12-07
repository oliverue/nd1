//
//  UserDatum.h
//  Calculate
//
//  Created by Oliver Unter Ecker on 10/2/09.
//  Copyright 2009 Naive Design. All rights reserved.
//

#import <CoreData/CoreData.h>

@class UserDataCategory;

@interface UserDatum :  NSManagedObject  
{
}

@property (nonatomic, retain) NSNumber * displayOrder;
@property (nonatomic, retain) NSString * data;
@property (nonatomic, retain) NSString * name;
@property (nonatomic, retain) NSString * comment;
@property (nonatomic, retain) UserDataCategory * category;

@end



