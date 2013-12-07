//
//  Calculator.h
//  Calculate
//
//  Created by Oliver Unter Ecker on 9/13/09.
//  Copyright 2009 Naive Design. All rights reserved.
//

#import <CoreData/CoreData.h>

@class Key;
@class Menu;
@class Type;
@class Orientation;
@class Skin;

@interface Calculator :  NSManagedObject  
{
}

@property (nonatomic, retain) NSString * name;
@property (nonatomic, retain) NSString * notes;
@property (nonatomic, retain) NSString * assets;
@property (nonatomic, retain) NSString * injection;
@property (nonatomic, retain) NSString * overview;
@property (nonatomic, retain) id thumbnailImage;
@property (nonatomic, retain) NSSet* keys;
@property (nonatomic, retain) NSSet* menus;
@property (nonatomic, retain) NSManagedObject * image;
@property (nonatomic, retain) Type * type;
@property (nonatomic, retain) Orientation * orientation;
@property (nonatomic, retain) Skin * skin;
@property (nonatomic, retain) NSDate * uploadDate;
@property (nonatomic, retain) NSDate * downloadDate;
@property (nonatomic, retain) NSDate * lastUsedDate;

@end


@interface Calculator (CoreDataGeneratedAccessors)

- (void)addKeysObject:(Key *)value;
- (void)removeKeysObject:(Key *)value;
- (void)addKeys:(NSSet *)value;
- (void)removeKeys:(NSSet *)value;

- (void)addMenusObject:(Menu *)value;
- (void)removeMenusObject:(Menu *)value;
- (void)addMenus:(NSSet *)value;
- (void)removeMenus:(NSSet *)value;

@end

