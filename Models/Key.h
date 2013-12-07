//
//  Key.h
//  Calculate
//
//  Created by Oliver Unter Ecker on 9/12/09.
//  Copyright 2009 Naive Design. All rights reserved.
//

#import <CoreData/CoreData.h>

@class Calculator;

@interface Key :  NSManagedObject  
{
}

@property (nonatomic, retain) NSNumber * displayOrder;
@property (nonatomic, retain) NSString * function;
@property (nonatomic, retain) NSString * name;
@property (nonatomic, retain) Calculator * calculator;

@end



