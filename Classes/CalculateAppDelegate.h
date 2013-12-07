
/*
     File: CalculateAppDelegate.h
 Abstract: Application delegate that sets up a tab bar controller with two view controllers
 
  Version: 1.0
 
 //  Copyright 2009 Naive Design. All rights reserved.
 
 */

#import <UIKit/UIKit.h>

@class CalculatorListTableViewController;
@class Calculator;
@class UserDataCategoryListTableViewController;
@class UserDataCategory;
@class JS_CalcViewController;

@interface CalculateAppDelegate : NSObject <UIApplicationDelegate, UITabBarControllerDelegate, UIAlertViewDelegate, UIWebViewDelegate> {
    NSManagedObjectModel *managedObjectModel;
    NSManagedObjectContext *managedObjectContext;	    
    NSPersistentStoreCoordinator *persistentStoreCoordinator;

	BOOL createdPersistentStoreFromScratch;
	
    UIWindow *window;
    UITabBarController *tabBarController;
    CalculatorListTableViewController *calculatorListController;
	UserDataCategoryListTableViewController *userDataCategoryListController;
    JS_CalcViewController *calcViewController;
	UIWebView *helpWebView;
}

@property (nonatomic, retain) IBOutlet UIWindow *window;
@property (nonatomic, retain) IBOutlet UITabBarController *tabBarController;
@property (nonatomic, retain) IBOutlet CalculatorListTableViewController *calculatorListController;
@property (nonatomic, retain) IBOutlet UserDataCategoryListTableViewController *userDataCategoryListController;
@property (nonatomic, retain) IBOutlet JS_CalcViewController *calcViewController;
@property (nonatomic, retain) IBOutlet UIWebView *helpWebView;

@property (nonatomic, retain, readonly) NSManagedObjectModel *managedObjectModel;
@property (nonatomic, retain, readonly) NSManagedObjectContext *managedObjectContext;
@property (nonatomic, retain, readonly) NSPersistentStoreCoordinator *persistentStoreCoordinator;

- (NSString *)applicationDocumentsDirectory;
- (Calculator *)calculatorNamed:(NSString *)name;
- (UserDataCategory *)dataCategoryForFolderNamed:(NSString *)folderName;
- (void)showHelpFor:(NSString *)item inMenu:(NSString *)menuTitle; 

@end

