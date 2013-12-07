//
//  Skin.h
//  Calculate
//
//  Created by Oliver Unter Ecker on 10/2/09.
//  Copyright 2009 Naive Design. All rights reserved.
//

#import <CoreData/CoreData.h>

@class Calculator;

@interface Skin :  NSManagedObject  
{
}

@property (nonatomic, retain) NSString * name;
@property (nonatomic, retain) NSSet* calculators;

@end


@interface Skin (CoreDataGeneratedAccessors)
- (void)addCalculatorsObject:(Calculator *)value;
- (void)removeCalculatorsObject:(Calculator *)value;
- (void)addCalculators:(NSSet *)value;
- (void)removeCalculators:(NSSet *)value;

@end

