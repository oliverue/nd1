
/*
     File: CalculateAppDelegate.m
 Abstract: Application delegate that sets the managed object context and a tab bar controller.
 
  Version: 1.0
 
 Copyright: 2009 Naive Design. All rights reserved.
 
 */

#import "Type.h"
#import "Orientation.h"
#import "Skin.h"
#import "Calculator.h"
#import "CalculatorListTableViewController.h"
#import "CalculatorDetailViewController.h" // for directly setting details views in Calculator products
#import "UserDataCategoryListTableViewController.h"
#import "JS_CalcViewController.h"
#import "DataSharingController.h"
#import "UserDataCategory.h"

#import "CalculateAppDelegate.h"

@implementation CalculateAppDelegate

@synthesize window;
@synthesize tabBarController;
@synthesize calculatorListController;
@synthesize userDataCategoryListController;
@synthesize calcViewController;
@synthesize helpWebView;


+ (void)initialize {
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    NSMutableDictionary *appDefaults = [NSMutableDictionary dictionary];

#ifdef IS_ND1
	[appDefaults setObject:@"ND1" forKey:@"CurrentCalculator"];
	[appDefaults setObject:@"Calculator" forKey:@"CurrentView"];
#else
	[appDefaults setObject:@"ND1" forKey:@"CurrentCalculator"];
	[appDefaults setObject:@"CalculatorList" forKey:@"CurrentView"];
#endif
    [appDefaults setObject:[NSNumber numberWithBool:NO] forKey:@"hasRunDemo"];
    [appDefaults setObject:[NSNumber numberWithBool:NO] forKey:@"DontTellAboutDoubleTapToReturn_preference"];

    [appDefaults setObject:[NSNumber numberWithBool:YES] forKey:@"firstLaunch_preference"];

    [appDefaults setObject:[NSNumber numberWithBool:YES] forKey:@"tips_preference"];
    [appDefaults setObject:[NSNumber numberWithBool:YES] forKey:@"status_preference"];
    [appDefaults setObject:[NSNumber numberWithBool:NO] forKey:@"wantsAutoExpand"];
	[appDefaults setObject:@"2pi, 360deg" forKey:@"anglemodeshow_preference"];
    [appDefaults setObject:@"Light" forKey:@"skin_preference"];
    [appDefaults setObject:@"left" forKey:@"align_preference"];
	[appDefaults setObject:@"" forKey:@"uploadURL_preference"];
	[appDefaults setObject:@"<auto>" forKey:@"uploadUUID_preference"];
	[appDefaults setObject:@"" forKey:@"email_preference"];
    [appDefaults setObject:[NSNumber numberWithBool:NO] forKey:@"injection_preference"];
    [appDefaults setObject:[NSNumber numberWithBool:NO] forKey:@"hasPurchasedCAS"];

    [defaults registerDefaults:appDefaults];
}

- (BOOL)setCalculator:(NSString *)calculatorName {
	// no need to take any action if the desired calculator is already set
	if (self.calcViewController.calculator && [calculatorName isEqualToString:self.calcViewController.calculator.name])
		return YES;

/* was:
	NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] init];
	NSEntityDescription *entity = [NSEntityDescription entityForName:@"Calculator" inManagedObjectContext:[self managedObjectContext]];
	[fetchRequest setEntity:entity];
	[fetchRequest setPredicate:[NSPredicate predicateWithFormat:@"name == %@", calculatorName]];
	NSError *error = nil;
	NSArray *calculators = [managedObjectContext executeFetchRequest:fetchRequest error:&error];
	[fetchRequest release];

	Calculator *calculator;
	if (calculators && [calculators count])
		calculator = [calculators objectAtIndex:0];
	else
		return NO;
*/
    Calculator *calculator = [self calculatorNamed:calculatorName];
    if (calculator == nil)
        return NO;
    
	// set calculator into calculator controller
	self.calcViewController.calculator = calculator;
	
	// make calculator's detail view and set as first view of the tab bar controller
	[calculatorListController showCalculator:calculator animated:NO];
	calculatorListController.title = NSLocalizedString(@"CalculatorDefinition", nil);

	NSString *name = NSLocalizedString(calculatorName, nil);
#ifdef IS_ALSO_ND0
	name = [name stringByReplacingOccurrencesOfString:@"ND1" withString:@"ND0"];
#endif
	calcViewController.title = name;

	return YES;
}

- (void)alertView:(UIAlertView *)alertView didDismissWithButtonIndex:(NSInteger)buttonIndex {
	// this is only ever called by the alert view launched in -applicationDidFinishLaunching
	[self setCalculator:(buttonIndex == 0 ? @"ND1 (Classic)" : @"ND1")];
	tabBarController.selectedIndex = 0; // deselect current calculator view
	tabBarController.selectedIndex = 1; // and re-set it; this is needed to refresh it

	[calcViewController performSelector:@selector(showQuickTourReminder) withObject:nil afterDelay:3.0];
}

- (Calculator *)calculatorNamed:(NSString *)calculatorName {
	NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] init];
	NSEntityDescription *entity = [NSEntityDescription entityForName:@"Calculator" inManagedObjectContext:[self managedObjectContext]];
	[fetchRequest setEntity:entity];
	[fetchRequest setPredicate:[NSPredicate predicateWithFormat:@"name == %@", calculatorName]];
	NSError *error = nil;
	NSArray *calculators = [managedObjectContext executeFetchRequest:fetchRequest error:&error];
	[fetchRequest release];

	return (calculators && [calculators count] ? [calculators objectAtIndex:0] : nil);
}

- (UserDataCategory *)dataCategoryForFolderNamed:(NSString *)folderName {
	NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] init];
	NSEntityDescription *entity = [NSEntityDescription entityForName:@"UserDataCategory" inManagedObjectContext:[self managedObjectContext]];
	[fetchRequest setEntity:entity];
	[fetchRequest setPredicate:[NSPredicate predicateWithFormat:@"name == %@", folderName]];
	NSError *error = nil;
	NSArray *dataCategories = [managedObjectContext executeFetchRequest:fetchRequest error:&error];
	[fetchRequest release];
	
	return (dataCategories && [dataCategories count] ? [dataCategories objectAtIndex:0] : nil);
}

- (BOOL)installDemoFolder {
	BOOL ok = NO;

	if (![self dataCategoryForFolderNamed:@"Demos"]) { // check if demo folder already exists
		// obtain folder contents
		NSString *demoFolder_json = [NSString stringWithContentsOfFile:[[NSBundle mainBundle] pathForResource:@"UserData_Demos" ofType:@"txt"] encoding:NSUTF8StringEncoding error:NULL];
		assert(demoFolder_json);

		// create "Demos" folder
		UserDataCategory *userDataCategory = [NSEntityDescription insertNewObjectForEntityForName:@"UserDataCategory" inManagedObjectContext:self.managedObjectContext];
		userDataCategory.name = NSLocalizedString(@"Demos", nil);
		
		// populate folder
		DataSharingController *dataService = [[DataSharingController alloc] initWithNibName:@"DataSharing" bundle:nil];
		((DataSharingController *)dataService).calculator = nil;
		((DataSharingController *)dataService).userDataCategory = userDataCategory;
		ok = [dataService recreateCategoryWithJSONString:demoFolder_json]; // this will also save into context
		[dataService release];
	}

	return ok;
}

- (void)applicationDidFinishLaunching:(UIApplication *)application {
    window.frame = [[UIScreen mainScreen] bounds];

	createdPersistentStoreFromScratch = NO;
    calculatorListController.managedObjectContext = self.managedObjectContext;
    userDataCategoryListController.managedObjectContext = self.managedObjectContext;
    calcViewController.managedObjectContext = self.managedObjectContext;
/* not working, as nothing can be written into resource folder
	// make sure "extensions" link exists
	NSFileManager *fileManager = [NSFileManager defaultManager];
	NSString *extensionsPath = [[[NSBundle mainBundle] resourcePath] stringByAppendingPathComponent:@"extensions"];
	if (![fileManager fileExistsAtPath:extensionsPath]) // if the link doesn't exist, create it
		[fileManager createSymbolicLinkAtPath:extensionsPath pathContent:[self applicationDocumentsDirectory]];
*/

	// show/hide status bar
	NSNumber *showStatusBar = [[NSUserDefaults standardUserDefaults] objectForKey:@"status_preference"];
	if (showStatusBar)
		[[UIApplication sharedApplication] setStatusBarHidden:![showStatusBar boolValue] withAnimation:YES];

	// load calculator
		
	NSString *calculatorName = [[NSUserDefaults standardUserDefaults] objectForKey:@"CurrentCalculator"];

#ifdef IS_ND1

	/* tmp'ly no longer asking for mode; if this is re-enabled, disable display of demo html
	if ([[[NSUserDefaults standardUserDefaults] objectForKey:@"firstLaunch_preference"] boolValue]) {
		NSString *msg = NSLocalizedString(@"WelcomeMsg", nil);
#ifdef IS_ALSO_ND0
		msg = [msg stringByReplacingOccurrencesOfString:@"ND1" withString:@"ND0"];
#endif
#ifndef IS_ALSO_ND0 // ND0 no longer asks for configuration choice
		UIAlertView *alert = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Welcome", nil) message:msg delegate:self cancelButtonTitle:nil otherButtonTitles:NSLocalizedString(@"Classic", nil), NSLocalizedString(@"Modern", nil), nil];
		[alert show];
		[alert release];
#endif
	}
	*/
    
    //// For v1.6, determine if cache needs to be deleted on first launch
    //// [NSFetchedResultsController deleteCacheWithName:@"Root"]

	[self setCalculator:calculatorName];

	///	calculatorListController.tabBarItem = [[UITabBarItem alloc] initWithTitle:NSLocalizedString(@"CalculatorDefinition", nil) image:[UIImage imageNamed:@"table_gray.png"] tag:0];
	/*
	 CalculatorDetailViewController *detailViewController = [[CalculatorDetailViewController alloc] initWithStyle:UITableViewStyleGrouped];
	 detailViewController.calculator = calculator;
	 detailViewController.title = NSLocalizedString(@"CalculatorDefinition", nil);
	 ///	detailViewController.icon = [UIImage imageNamed:@"table_gray.png"];
	 userDataCategoryListController.title = @"Hallo";
	 
	 tabBarController.viewControllers = [NSArray arrayWithObjects:detailViewController, calcViewController, userDataCategoryListController, nil];
	 */
	userDataCategoryListController.title = NSLocalizedString(@"My Data", nil);
	((UIViewController *)[helpWebView nextResponder]).title = NSLocalizedString(@"Help", nil);
	
#else // Calculate case
	calcViewController.title = NSLocalizedString(calculatorName, nil);
#endif

	NSString *currentView = [[NSUserDefaults standardUserDefaults] objectForKey:@"CurrentView"];
	if (currentView) {
		if ([currentView isEqualToString:@"Calculator"])
			tabBarController.selectedIndex = 1;/// ViewController = calcViewController;
		else if ([currentView isEqualToString:@"CalculatorList"])
			tabBarController.selectedIndex = 0;/// ViewController = calculatorListController;
		else if ([currentView isEqualToString:@"UserData"])
			tabBarController.selectedIndex = 3;///ViewController = userDataCategoryListController;
	}

#ifdef IS_ND1
	// install the Demo folder if there is none, and we're about to do the demo
	if (![[[NSUserDefaults standardUserDefaults] objectForKey:@"hasRunDemo"] boolValue])
		[self installDemoFolder];
#endif

    [self.window setRootViewController:tabBarController];
    [window makeKeyAndVisible];
}

- (BOOL)tabBarController:(UITabBarController *)controller shouldSelectViewController:(UIViewController *)viewController {
#ifdef IS_ND1
	if (viewController == calcViewController) {
		// if we re-select calculator, hide the tab bar
		// this is done here and not in tabBarController:didSelectViewController: because here the selectedViewController is still the previous one
		if (controller.selectedViewController == calcViewController || [[[NSUserDefaults standardUserDefaults] objectForKey:@"wantsAutoExpand"] boolValue]) {
			[calcViewController toggleTabBar];
			[calcViewController showMenus:[NSNumber numberWithBool:NO]];
		}
		else if (controller.tabBar.alpha < 1.0f) // if tab bar is not fully opaque, (re-)schedule "hide" // todo: remove as no longer active due to always toggling tab bar in else block below
			[calcViewController performSelector:@selector(showTabBar:) withObject:[NSNumber numberWithBool:NO] afterDelay:2.0];
	}
	else if (controller.selectedViewController == calcViewController && controller.tabBar.alpha < 1.0f) { // we're selecting a tab other than calculator and we're coming from the expanded calculator
/// was: cancel any pending requests to make the tab bar invisible
///		[NSObject cancelPreviousPerformRequestsWithTarget:calcViewController selector:@selector(showTabBar:) object:[NSNumber numberWithBool:NO]];
		// shrink calculator (and make tab bar fully visible)
		[calcViewController toggleTabBar];
	}

	return (!(controller.selectedIndex == 0 && viewController == [controller.viewControllers objectAtIndex:0])); // don't permit selecting first controller if already selected, as this would push the stack back to calculators list, as per tab bar built-in behavior
#else
	return YES;
#endif
}

- (void)webViewDidFinishLoad:(UIWebView *)theWebView {
	// NSLog(@"Finsihed Loading %@", [[[theWebView request] URL] relativeString]);
#ifdef USE_ANCHOR_FOR_HELP_ITEM
	NSRange r = [[[[theWebView request] URL] relativeString] rangeOfString:@"#"];
	if (r.length) { // anchor in URL
		NSString *anchor = [[[[theWebView request] URL] relativeString] substringFromIndex:r.location];
		// NSLog(@"Anchor found: %@", anchor);
		NSString *jsURLString = [NSString stringWithFormat:@"javascript:function%%20show(name)%%20%%7Bname%%20=%%20decodeURIComponent(name).escapeHTML();var%%20elem,%%20rows%%20=%%20document.getElementsByTagName(%%22iframe%%22)%%5B0%%5D.contentDocument.documentElement.getElementsByTagName(%%22tr%%22);%%09for%%20(var%%20i=0;%%20i%%3Crows.length;%%20i++)%%20%%7Belem%%20=%%20rows%%5Bi%%5D.firstChild.nextSibling;if%%20(elem.textContent.indexOf(name)%%20!=%%20-1)break;%%20%%7Dif%%20(elem)%%20elem.scrollIntoView();%%7Dshow(%%22%@%%22)", anchor];
		// NSLog(@"Amazing JS string: %@", jsURLString);
		///[helpWebView loadRequest:[NSURLRequest requestWithURL:[NSURL URLWithString:jsURLString]]];
	}
#else
	NSRange r = [[[[theWebView request] URL] relativeString] rangeOfString:@"item="];
	if (r.length) { // item in URL
		NSString *item = [[[[theWebView request] URL] relativeString] substringFromIndex:r.location+5];
		// NSLog(@"Item found: %@", item);
		[theWebView stringByEvaluatingJavaScriptFromString:[NSString stringWithFormat:@"function show(name) {name = decodeURIComponent(name).escapeHTML();var elem, rows = document.getElementsByTagName('iframe')[0].contentDocument.documentElement.getElementsByTagName('tr');	for (var i=0; i<rows.length; i++) {elem = rows[i].firstChild.nextSibling;if (elem.textContent.indexOf(name) != -1)break; }if (elem) elem.scrollIntoView();}show('%@')", item]];
	}
#endif
}

- (void)showHelpFor:(NSString *)item inMenu:(NSString *)menuTitle {
	// NSLog(@"Help for %@ in menu %@", item, menuTitle);
	if (helpWebView /*&& ![helpWebView request]*/) {
		[tabBarController setSelectedIndex:2]; // help tab
#ifdef USE_ANCHOR_FOR_HELP_ITEM
		NSString *docBaseURLString = @"https://m.naivedesign.com/pages";
		NSString *docURLString = [NSString stringWithFormat:@"%@/f_%@.html#%@", docBaseURLString, [menuTitle lowercaseString], [item stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding]];
#else
		NSString *docBaseURLString = @"https://m.naivedesign.com/ND1/docs";
//		NSString *docBaseURLString = @"http://zinc.local/~oliver/docs";
		NSString *language = [[NSLocale preferredLanguages] objectAtIndex:0];
		NSString *docURLString = [NSString stringWithFormat:@"%@?lang=%@&menu=%@&item=%@", docBaseURLString, language, menuTitle, [item stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding]];
#endif
		// NSLog(@"Setting URL: %@", docURLString);
		[helpWebView loadRequest:[NSURLRequest requestWithURL:[NSURL URLWithString:docURLString]]];
        
        // make sure tabs will show and allow navigation
        if (tabBarController.tabBar.alpha < 1.0f) // if tab bar is not fully opaque, toggle tab bar
            [calcViewController toggleTabBar];
	}
}

- (void)tabBarController:(UITabBarController *)controller didSelectViewController:(UIViewController *)viewController {
#ifdef IS_ND1
	if (viewController.view == helpWebView && ![helpWebView request]) {
		NSString *docBaseURLString = @"http://m.naivedesign.com/ND1/docs";
//		NSString *docBaseURLString = @"http://zinc.local/~oliver/docs";
		NSString *language = [[NSLocale preferredLanguages] objectAtIndex:0];
		NSString *docURLString = [NSString stringWithFormat:@"%@?lang=%@", docBaseURLString, language];
		[helpWebView loadRequest:[NSURLRequest requestWithURL:[NSURL URLWithString:docURLString]]];
	}
	if (viewController != calcViewController) {
		////controller.alpha == 1.0f;
	}
#endif
}

/**
 applicationWillTerminate: saves changes in the application's managed object context before the application terminates.
 */
- (void)applicationWillTerminate:(UIApplication *)application {
    NSError *error;
    if (managedObjectContext != nil) {
        if ([managedObjectContext hasChanges] && ![managedObjectContext save:&error]) {
			// todo: better action
			NSLog(@"Unresolved error %@, %@", error, [error userInfo]);
			abort();
        } 
    }

	[[NSUserDefaults standardUserDefaults] setObject:(tabBarController.selectedIndex == 1 ? @"Calculator" : (tabBarController.selectedIndex == 2 ? @"UserData" : @"CalculatorList")) forKey:@"CurrentView"];
	[[NSUserDefaults standardUserDefaults] setObject:[[NSUserDefaults standardUserDefaults] objectForKey:@"CurrentCalculator"] forKey:@"PreviousCalculator"];
	[[NSUserDefaults standardUserDefaults] setObject:[NSNumber numberWithBool:NO] forKey:@"firstLaunch_preference"];	
	[[NSUserDefaults standardUserDefaults] setObject:[NSNumber numberWithBool:NO] forKey:@"tips_preference"];	
	[[NSUserDefaults standardUserDefaults] synchronize];
}

- (void)applicationWillEnterForeground:(UIApplication *)application {
#ifdef IS_ND1
	[[NSUserDefaults standardUserDefaults] synchronize];
	NSString *calculatorName = [[NSUserDefaults standardUserDefaults] objectForKey:@"CurrentCalculator"];
	if (![calculatorName isEqualToString:[[NSUserDefaults standardUserDefaults] objectForKey:@"PreviousCalculator"]]) {
		[self setCalculator:calculatorName]; // a no-op, if calculator didn't change
		tabBarController.selectedIndex = 0; // deselect current calculator view
		tabBarController.selectedIndex = 1; // and re-set it; this is needed to refresh it
	}
#endif

	// show/hide status bar
	NSNumber *showStatusBar = [[NSUserDefaults standardUserDefaults] objectForKey:@"status_preference"];
	if (showStatusBar)
		[[UIApplication sharedApplication] setStatusBarHidden:![showStatusBar boolValue] withAnimation:YES];
}

- (void)applicationDidEnterBackground:(UIApplication *)application {
	[self applicationWillTerminate:application]; // on iOS 4, we happen to need here the same set of things done as for truly quitting
}

#pragma mark -
#pragma mark Core Data stack

/**
 Returns the managed object context for the application.
 If the context doesn't already exist, it is created and bound to the persistent store coordinator for the application.
 If the persistent store has to be created from scratch, its defaults are populated.
 */
- (NSManagedObjectContext *)managedObjectContext {
    if (managedObjectContext != nil)
        return managedObjectContext;
	
    NSPersistentStoreCoordinator *coordinator = [self persistentStoreCoordinator];
    if (coordinator != nil) {
        managedObjectContext = [NSManagedObjectContext new];
        [managedObjectContext setPersistentStoreCoordinator: coordinator];

		if (createdPersistentStoreFromScratch) {
			// created a db from scratch; now insert default objects
			Type *type;
			type = [NSEntityDescription insertNewObjectForEntityForName:@"Type" inManagedObjectContext:managedObjectContext];
			type.name = @"Web Front-end";
			type = [NSEntityDescription insertNewObjectForEntityForName:@"Type" inManagedObjectContext:managedObjectContext];
			type.name = @"RPN";
			type = [NSEntityDescription insertNewObjectForEntityForName:@"Type" inManagedObjectContext:managedObjectContext];
			type.name = @"Normal";
			
			Orientation *orientation;
			orientation = [NSEntityDescription insertNewObjectForEntityForName:@"Orientation" inManagedObjectContext:managedObjectContext];
			orientation.name = @"Landscape";
			orientation = [NSEntityDescription insertNewObjectForEntityForName:@"Orientation" inManagedObjectContext:managedObjectContext];
			orientation.name = @"Portrait";

			Skin *skin;
			skin = [NSEntityDescription insertNewObjectForEntityForName:@"Skin" inManagedObjectContext:managedObjectContext];
			skin.name = @"Default";
			skin = [NSEntityDescription insertNewObjectForEntityForName:@"Skin" inManagedObjectContext:managedObjectContext];
			skin.name = @"Metal";
			skin = [NSEntityDescription insertNewObjectForEntityForName:@"Skin" inManagedObjectContext:managedObjectContext];
			skin.name = @"Light";
			
			// save the managed object context
			NSError *error = nil;
			if (![managedObjectContext save:&error]) {
				// todo: better action
				NSLog(@"Unresolved error %@, %@", error, [error userInfo]);
				abort();
			}
		}		
    }
    return managedObjectContext;
}


/**
 Returns the managed object model for the application.
 If the model doesn't already exist, it is created by merging all of the models found in the application bundle.
 */
- (NSManagedObjectModel *)managedObjectModel {
    if (managedObjectModel != nil)
        return managedObjectModel;

    managedObjectModel = [[NSManagedObjectModel mergedModelFromBundles:nil] retain];    
    return managedObjectModel;
}


/**
 Returns the persistent store coordinator for the application.
 If the coordinator doesn't already exist, it is created and the application's store added to it.
 */
- (NSPersistentStoreCoordinator *)persistentStoreCoordinator {
    if (persistentStoreCoordinator != nil)
        return persistentStoreCoordinator;

	NSString *storePath = [[self applicationDocumentsDirectory] stringByAppendingPathComponent:@"Calculate.sqlite"];

	// set up the store
	NSFileManager *fileManager = [NSFileManager defaultManager];
// [fileManager removeItemAtPath:storePath error:NULL];
// createdPersistentStoreFromScratch = YES;
// NSLog(@"Store located at %@", storePath);
// if (0) { // if the expected store doesn't exist, copy the default store
	if (![fileManager fileExistsAtPath:storePath]) { // if the expected store doesn't exist, copy the default store
		NSString *defaultStorePath = [[NSBundle mainBundle] pathForResource:@"Calculate" ofType:@"sqlite"];
		if (defaultStorePath)
			[fileManager copyItemAtPath:defaultStorePath toPath:storePath error:NULL];
	}

	NSURL *storeUrl = [NSURL fileURLWithPath:storePath];

	NSError *error;
    persistentStoreCoordinator = [[NSPersistentStoreCoordinator alloc] initWithManagedObjectModel:[self managedObjectModel]];

#ifdef MIGRATE_STORE
	NSDictionary *options = [NSDictionary dictionaryWithObjectsAndKeys:
							 [NSNumber numberWithBool:YES], NSMigratePersistentStoresAutomaticallyOption,
							 [NSNumber numberWithBool:YES], NSInferMappingModelAutomaticallyOption, nil];
    if (![persistentStoreCoordinator addPersistentStoreWithType:NSSQLiteStoreType configuration:nil URL:storeUrl options:options error:&error]) {
#else
    if (![persistentStoreCoordinator addPersistentStoreWithType:NSSQLiteStoreType configuration:nil URL:storeUrl options:nil error:&error]) {
#endif
		// Typical reasons for an error here include:
		// - The persistent store is not accessible
		// - The schema for the persistent store is incompatible with current managed object model
		NSLog(@"Error %@, %@", error, [error userInfo]);
		
		// wipe db; attempt to start fresh
		NSLog(@"Starting with fresh (empty) DB.");
		[fileManager removeItemAtPath:storePath error:NULL];
		if ([persistentStoreCoordinator addPersistentStoreWithType:NSSQLiteStoreType configuration:nil URL:storeUrl options:nil error:&error])
			createdPersistentStoreFromScratch = YES;
		else {
			NSLog(@"Error %@, %@\nGiving up.", error, [error userInfo]);
			abort();
		}
    }    
		
    return persistentStoreCoordinator;
}


#pragma mark -
#pragma mark Application's documents directory

/**
 Returns the path to the application's documents directory.
 */
- (NSString *)applicationDocumentsDirectory {
	return [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) lastObject];
}


#pragma mark -
#pragma mark Memory management

- (void)dealloc {
    [managedObjectContext release];
    [managedObjectModel release];
    [persistentStoreCoordinator release];

	[calcViewController release];
    [calculatorListController release];
	[userDataCategoryListController release];
    [tabBarController release];
    [helpWebView release];
    [window release];
    
    [super dealloc];
}

@end
