//
//  JS_CalcViewController.m
//  JS Calc
//
//  Created by Oliver Unter Ecker on 9/8/09.
//  Copyright Naive Design 2009. All rights reserved.
//

#import "JSON.h"

#import "Calculator.h"
#import "UserDataCategory.h"
#import "UserDatum.h"
#import "Key.h"
#import "Menu.h"
#import "Type.h"
#import "Skin.h"
#import "Orientation.h"
#import "SlideButton.h"

#import "CalculateAppDelegate.h" // for -applicationDocumentsDirectory and its tabBarController

#import "JS_CalcViewController.h"

/*
// http://dev.ragfield.com/2009/09/insert-text-at-current-cursor-location.html
@interface UIResponder(UIResponderInsertTextAdditions)
- (void)insertText:(NSString*) text;
@end
@implementation UIResponder(UIResponderInsertTextAdditions)
- (void)insertText:(NSString*) text {
	// NSLog(@"insert: %@", text);
	UIPasteboard* generalPasteboard = [UIPasteboard generalPasteboard];
	NSArray* items = [generalPasteboard.items copy];
	generalPasteboard.string = text;
	[self paste: self];
	generalPasteboard.items = items;
	[items release];
}
@end
*/

@implementation JS_CalcViewController

@synthesize managedObjectContext;
@synthesize calculator;
@synthesize userDataCategory;
@synthesize currentMenuTitle;
@synthesize previousMenuTitle;
@synthesize lastPushedEditLine;

#define DEFAULT_VAR_STORE_NAME @"My Vars"
#define DEMO_STORE_NAME @"Demos"


- (NSString *)stringWithinDelimiters:(NSString *)beg :(NSString *)end withString:(NSString *)from {
	NSRange r = [from rangeOfString:beg];
	if (r.length) {
		NSRange r2 = [from rangeOfString:end];
		if (r2.length) {
			r.location += 1;
			r.length = r2.location - r.location;
			return [from substringWithRange:r];
		}
	}
	return nil;
}

- (NSString *)stringInParenthesesWithString:(NSString *)from {
	return [self stringWithinDelimiters:@"(" :@")" withString:from];
}

- (NSString *)stringInBracketsWithString:(NSString *)from {
	return [self stringWithinDelimiters:@"[" :@"]" withString:from];
}

- (NSString *)stringByCompletingEditString:(NSString *)input hadErrorAtLocation:(NSInteger *)errorLocation {
	const unichar singleQuote = [@"'" characterAtIndex:0];
	const unichar doubleQuote = [@"\"" characterAtIndex:0];
	
	const BOOL isAlgebraicMode = ([input characterAtIndex:0] == singleQuote);

	const unichar openingCharacters[] = { singleQuote, doubleQuote, [@"≪" characterAtIndex:0], [@"(" characterAtIndex:0], [@"[" characterAtIndex:0] };
	const unichar closingCharacters[] = { singleQuote, doubleQuote, [@"≫" characterAtIndex:0], [@")" characterAtIndex:0], [@"]" characterAtIndex:0] };
	NSArray *closingStrings = [NSArray arrayWithObjects:@"'", @"\"", @"≫", @")", @"]", nil]; // in sync with closingCharacters
	const NSUInteger n_special_characters = [closingStrings count];
	NSMutableArray *neededClosingCharacters = [NSMutableArray array];
	const NSUInteger length = [input length];

	BOOL hasBegunSingleQuote = NO;
	BOOL hasBegunDoubleQuote = NO;

	for (NSUInteger i=0; i<length; i++) {
		unichar c = [input characterAtIndex:i];
		for (NSUInteger j=0; j<n_special_characters; j++) {
			if (c == closingCharacters[j] && !(c == singleQuote && !hasBegunSingleQuote) && !(c == doubleQuote && !hasBegunDoubleQuote)) {
				if (c == singleQuote && isAlgebraicMode && i && i < length-1) { // check for errant single quote in middle of algebraic expression
					*errorLocation = i;
					return nil;
				}
				
				// find character in "needed" array; if not present we lack the matching opening character, which is an error
				NSUInteger index = [neededClosingCharacters indexOfObject:[NSString stringWithCharacters:&c length:1]];
				if (index == NSNotFound) {
					*errorLocation = i;
					return nil;
				}
				
				[neededClosingCharacters removeObjectAtIndex:index];

				if (c == singleQuote)
					hasBegunSingleQuote = NO;
				else if (c == doubleQuote)
					hasBegunDoubleQuote = NO;
			}
			else if (c == openingCharacters[j]) {
				[neededClosingCharacters insertObject:[closingStrings objectAtIndex:j] atIndex:0];

				if (c == singleQuote)
					hasBegunSingleQuote = YES;
				else if (c == doubleQuote)
					hasBegunDoubleQuote = YES;
			}
		}
	}

    BOOL closeWithSingleRPLEnd = [neededClosingCharacters isEqualToArray:[NSArray arrayWithObject:@"≫"]];
	return [input stringByAppendingString:[NSString stringWithFormat:@"%@%@",
                                                    closeWithSingleRPLEnd ? @" " : @"",
                                                    [neededClosingCharacters componentsJoinedByString:@""]]];
}

- (BOOL)stringHasOpenQuote:(NSString *)input {
	const unichar singleQuote = [@"'" characterAtIndex:0];
	const unichar doubleQuote = [@"\"" characterAtIndex:0];
	
	BOOL hasBegunSingleQuote = NO;
	BOOL hasBegunDoubleQuote = NO;
	
	const NSUInteger length = input.length;
	for (NSUInteger i=0; i<length; i++) {
		unichar c = [input characterAtIndex:i];
		if (c == singleQuote)
			hasBegunSingleQuote = !hasBegunSingleQuote;
		else if (c == doubleQuote)
			hasBegunDoubleQuote = !hasBegunDoubleQuote;
	}
	
	return (hasBegunDoubleQuote || hasBegunSingleQuote);
}				

- (NSUInteger)numberOfOccurrencesOfString:(NSString *)needle inString:(NSString *)haystack inRange:(NSRange)searchRange {
	NSUInteger numFinds = 0;
	NSUInteger originalSearchLength = searchRange.length;
	NSRange r;
	while ((r = [haystack rangeOfString:needle options:NSLiteralSearch range:searchRange]).length > 0) {
		++numFinds;
		if (r.location >= originalSearchLength-1)
			break;
		searchRange.location = r.location+1;
		searchRange.length = originalSearchLength - searchRange.location;
	}
	
	return numFinds;
}

- (BOOL)stringHasOpenBrace:(NSString *)input inRange:(NSRange)range {
	NSArray *openingBraces = [NSArray arrayWithObjects:@"(", @"[", @"{"/*, @"'", @"\""*/, nil];
	NSArray *closingBraces = [NSArray arrayWithObjects:@")", @"]", @"}"/*, @"'", @"\""*/, nil];
	
	BOOL foundOpenBrace = NO;

	for (NSUInteger i=0; i<[openingBraces count] && !foundOpenBrace; i++) {
/*was: (this doesn't count number of braces at all
		NSString *brace = [openingBraces objectAtIndex:i];
		NSRange rBrace = [input rangeOfString:brace options:NSBackwardsSearch range:range];
		if (rBrace.length) { // found a brace
			// find out if it's open
			NSString *closingBrace = [closingBraces objectAtIndex:i];
			NSRange rClosingBrace = [input rangeOfString:closingBrace options:NSLiteralSearch range:NSMakeRange(rBrace.location, range.length + range.location - rBrace.location)];
			if (!rClosingBrace.length) {
				foundOpenBrace = YES;
				break;
			}
		}
*/
		NSUInteger numOpen = [self numberOfOccurrencesOfString:[openingBraces objectAtIndex:i] inString:input inRange:range];
		if (numOpen) {
			NSUInteger numClosed = [self numberOfOccurrencesOfString:[closingBraces objectAtIndex:i] inString:input inRange:range];
			if (numOpen != numClosed)
				foundOpenBrace = YES;
		}
	}

	return foundOpenBrace;
}				

- (BOOL)stringHasOpenBrace:(NSString *)input {
	return [self stringHasOpenBrace:input inRange:NSMakeRange(0, [input length])];
}

/*
 * Like NSString's -componentsSeparatedByString but not separating open braces ("(", "[", "{")
 */
- (NSArray *)completedComponentsIn:(NSString *)input separatedByString:(NSString *)separator {
	NSMutableArray *array = [NSMutableArray array];
	BOOL hasEncounteredEnd = NO;
	NSUInteger inputLength = [input length];
	NSRange searchRange = NSMakeRange(0, inputLength);
	NSRange copyRange = searchRange;
/*	
	NSArray *openingBraces = [NSArray arrayWithObjects:@"(", @"[", @"{", nil];
	NSArray *closingBraces = [NSArray arrayWithObjects:@")", @"]", @"}", nil];
*/
	do {
		NSRange r = [input rangeOfString:separator options:NSLiteralSearch range:searchRange];
		if (r.length) { // found a separator
			// now make sure it doesn't lie within an open brace
			NSRange braceSearchRange = NSMakeRange(copyRange.location, r.location - copyRange.location);
			BOOL foundOpenBrace = [self stringHasOpenBrace:input inRange:braceSearchRange];
/*
			BOOL foundOpenBrace = NO;
			NSRange braceSearchRange = NSMakeRange(copyRange.location, r.location - copyRange.location);
			for (NSUInteger i=0; i<[openingBraces count]; i++) {
				NSString *brace = [openingBraces objectAtIndex:i];
				NSRange rBrace = [input rangeOfString:brace options:NSBackwardsSearch range:braceSearchRange];
				if (rBrace.length) { // found a brace
					// find out if it's open
					NSString *closingBrace = [closingBraces objectAtIndex:i];
					NSRange rClosingBrace = [input rangeOfString:closingBrace options:NSLiteralSearch range:NSMakeRange(rBrace.location, r.location - rBrace.location)];
					if (!rClosingBrace.length) {
						foundOpenBrace = YES;
						break;
					}
				}
			}
*/			
			searchRange.location += r.location - searchRange.location + 1; // setup to continue search past the separator
			searchRange.length = inputLength - searchRange.location; // make sure search doesn't go beyond range

			if (foundOpenBrace) {
				// don't copy substring into array; just continue search
			}
			else {
				// add component string (from last copy start location to separator) to array, and update copy start location
				NSRange componentRange = NSMakeRange(copyRange.location, r.location - copyRange.location);
				[array addObject:[input substringWithRange:componentRange]];
				copyRange = searchRange;
			}
		}
		else { // no more separators found
			[array addObject:[input substringFromIndex:copyRange.location]];
			hasEncounteredEnd = YES;
		}

	}
	while (!hasEncounteredEnd);
	
	return array;
}

- (BOOL)installUserMenuWithStartIndex:(NSInteger)startIndex showCategories:(BOOL)shouldShowCategories {
	if (![currentMenuTitle isEqualToString:@"User"])
		self.previousMenuTitle = self.currentMenuTitle;
	self.currentMenuTitle = @"User";

	// get all user data categories, or data for a given category sorted by displayOrder

	NSSortDescriptor *sortDescriptor = [[NSSortDescriptor alloc] initWithKey:@"displayOrder" ascending:YES];
	NSArray *sortDescriptors = [[NSArray alloc] initWithObjects:&sortDescriptor count:1];	
	
	NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] init];
	[fetchRequest setEntity:[NSEntityDescription entityForName:(shouldShowCategories ? @"UserDataCategory" : @"UserDatum") inManagedObjectContext:calculator.managedObjectContext]];
	if (shouldShowCategories)
		[fetchRequest setPredicate:[NSPredicate predicateWithFormat:@"name != %@ && name != %@", @"My Skin", @"Units"]];
	else {
		[fetchRequest setPredicate:[NSPredicate predicateWithFormat:@"category.name == %@ && !(name BEGINSWITH '.')", userDataCategory.name]];
        [fetchRequest setSortDescriptors:sortDescriptors];
	}

	NSError *error = nil;
	NSArray *userData = [calculator.managedObjectContext executeFetchRequest:fetchRequest error:&error];
	[fetchRequest release];

	[sortDescriptor release];
	[sortDescriptors release];
	
	NSUInteger maxSoftKeys = [userData count];
	
	// wrap startIndex
	if (startIndex < 0) {
		startIndex = (maxSoftKeys / [softKeys count]) * [softKeys count];
		if (startIndex == maxSoftKeys)
			startIndex = maxSoftKeys-[softKeys count];
	}
	else if (startIndex > maxSoftKeys-1)
		startIndex = 0;
	currentMenuStartIndex = startIndex;
	
	NSUInteger runningCount = startIndex;
	for (UIButton *button in softKeys) {
		NSString *name = @"";
		NSString *function = @"";
		if (runningCount < maxSoftKeys) {
			name = [[userData objectAtIndex:runningCount] valueForKey:@"name"];
			if (shouldShowCategories) {
				function = [@"@select_category:" stringByAppendingString:name];
				name = NSLocalizedString(name, nil); // category names to appear localized
			}
			else {
				NSString *data = [[userData objectAtIndex:runningCount] valueForKey:@"data"];
				function = ([data hasPrefix:@"http:"] ? data : name);
			}
///			function = (shouldShowCategories ? @"@select_category" : [[userData objectAtIndex:runningCount] valueForKey:@"data"]);
			++runningCount;
		}
		[button setTitle:name forState:UIControlStateNormal];
		[button setTitle:function forState:UIControlStateApplication];
	}

	hasLastShownCategories = shouldShowCategories;

	return YES;
}
- (BOOL)installUserMenuWithStartIndex:(NSInteger)startIndex {
	return [self installUserMenuWithStartIndex:startIndex showCategories:NO];
}


- (BOOL)selectCategory:(NSString *)categoryName andShow:(BOOL)shouldShow {
	NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] init];
	[fetchRequest setEntity:[NSEntityDescription entityForName:@"UserDataCategory" inManagedObjectContext:calculator.managedObjectContext]];
	[fetchRequest setPredicate:[NSPredicate predicateWithFormat:@"name == %@", categoryName]];
	
	NSError *error = nil;
	NSArray *userData = [calculator.managedObjectContext executeFetchRequest:fetchRequest error:&error];
	
	[fetchRequest release];

	if (userData && [userData count]) {
		self.userDataCategory = [userData objectAtIndex:0];
		NSString *localizedCategoryName = NSLocalizedString(self.userDataCategory.name, nil);
		// show to user
		dataCategoryLabel.text = localizedCategoryName;
		// inform webview of new data category
		[webView stringByEvaluatingJavaScriptFromString:[NSString stringWithFormat:@"calculator.setCurrentDataCategory(\"%@\")", localizedCategoryName]];
		if (shouldShow)
			[self installUserMenuWithStartIndex:currentMenuStartIndex];
		return YES;
	}
	else
		return NO;
}

- (BOOL)injectData:(NSString *)data forName:(NSString *)name {
	if (!(name && name.length))
		return NO;

	NSString *injectionPrefix = [NSString stringWithFormat:@"/*%@*/", name];
	NSString *injectionSuffix = @"/*end*/";

	NSMutableString *injection = ((calculator.injection && [calculator.injection class] != [NSNull class] && calculator.injection.length > 0) 
								  ? [[calculator.injection mutableCopy] autorelease]
								  : [NSMutableString string]);
	
	// delete any pre-existing injection with given name
	if (injection && injection.length) { /// todo: should account for null object, too?
		NSRange range = [injection rangeOfString:injectionPrefix];
		if (range.length > 0) { // found beginning of injection
			range.length = injection.length - range.location; // extend range to end of injection
			NSRange r = [injection rangeOfString:injectionSuffix options:NSLiteralSearch range:range];
			if (r.length > 0) // found end of injection
				range.length = (r.location - range.location) + r.length; // size range to end of injection
			
			// delete
			[injection deleteCharactersInRange:range];
		}
	}

	if (data && data.length)
		injection = [NSMutableString stringWithFormat:@"\n%@\n%@\n%@\n%@\n", injection, injectionPrefix, data, injectionSuffix];

	calculator.injection = injection;

	// save the managed object context
	NSError *error = nil;
	if (![calculator.managedObjectContext save:&error]) {
		// todo: better action
		NSArray* detailedErrors = [[error userInfo] objectForKey:NSDetailedErrorsKey];
		if (detailedErrors != nil && [detailedErrors count] > 0) {
			for(NSError* detailedError in detailedErrors) {
				NSLog(@"  DetailedError: %@", [detailedError userInfo]);
			}
		}
		else
			NSLog(@"Unresolved error %@, %@", error, [error userInfo]);

///		abort();
	}

	return YES;
}

- (BOOL)storeData:(NSString *)data forName:(NSString *)name {
	BOOL isCurrentlyShowingUserMenu = [currentMenuTitle isEqualToString:@"User"];
	if (!userDataCategory && ![self selectCategory:DEFAULT_VAR_STORE_NAME andShow:NO])
		return NO;
	else {
		NSManagedObjectContext *context = [userDataCategory managedObjectContext];
		
		NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] init];
		[fetchRequest setEntity:[NSEntityDescription entityForName:@"UserDatum" inManagedObjectContext:context]];
		[fetchRequest setPredicate:[NSPredicate predicateWithFormat:@"category.name == %@ && name == %@", userDataCategory.name, name]];
		
		NSError *error = nil;
		NSArray *userData = [calculator.managedObjectContext executeFetchRequest:fetchRequest error:&error];
		
		[fetchRequest release];
		
		if (userData && [userData count]) {
			UserDatum *datum = [userData objectAtIndex:0];
			datum.data = data;
		}
		else {
			UserDatum *userDatum = [NSEntityDescription insertNewObjectForEntityForName:@"UserDatum" inManagedObjectContext:context];
			userDatum.name = name;
			userDatum.data = data;
			userDatum.displayOrder = [NSNumber numberWithInteger:[[userDataCategory data] count]];
			userDatum.category = userDataCategory;
			
			// assign special case comments
			if ([name isEqualToString:@"eq"])
				userDatum.comment = NSLocalizedString(@"CurrentEQ", nil);
			if ([name isEqualToString:@"PPAR"])
				userDatum.comment = NSLocalizedString(@"PlotParams", nil);
			if ([name isEqualToString:@"∑DAT"])
				userDatum.comment = NSLocalizedString(@"StatData", nil);
			if ([name isEqualToString:@"∑PAR"])
				userDatum.comment = NSLocalizedString(@"StatParams", nil);
			
			if (isCurrentlyShowingUserMenu)
				[self installUserMenuWithStartIndex:currentMenuStartIndex];
		}
		
		// save the managed object context
		error = nil;
		if (![context save:&error]) {
			// todo: better action
			NSArray* detailedErrors = [[error userInfo] objectForKey:NSDetailedErrorsKey];
			if (detailedErrors != nil && [detailedErrors count] > 0) {
				for(NSError* detailedError in detailedErrors) {
					NSLog(@"  DetailedError: %@", [detailedError userInfo]);
				}
			}
			else
				NSLog(@"Unresolved error %@, %@", error, [error userInfo]);
			
			abort();
		}
		
		return YES;
	}
}

- (BOOL)deleteDataForName:(NSString *)name {
	if (!userDataCategory)
		return NO;

	NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] init];
	[fetchRequest setEntity:[NSEntityDescription entityForName:@"UserDatum" inManagedObjectContext:managedObjectContext]];
	NSError *error = nil;
	[fetchRequest setPredicate:[NSPredicate predicateWithFormat:@"category.name == %@ && name == %@", userDataCategory.name, name]];
	
	NSArray *userData = [calculator.managedObjectContext executeFetchRequest:fetchRequest error:&error];
	
	[fetchRequest release];
	
	if (userData && [userData count]) {
		UserDatum *datum = [userData objectAtIndex:0];
		[managedObjectContext deleteObject:datum];
		// save the managed object context
		NSError *error = nil;
		if (![managedObjectContext save:&error]) {
			// todo: better action
			NSLog(@"Unresolved error %@, %@", error, [error userInfo]);
			abort();
		}
		BOOL isCurrentlyShowingUserMenu = [currentMenuTitle isEqualToString:@"User"];
		if (isCurrentlyShowingUserMenu)
			[self installUserMenuWithStartIndex:currentMenuStartIndex];
	}
	
	return YES;
}

/*
- (NSString *)dataForName:(NSString *)name {
	NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] init];
	[fetchRequest setEntity:[NSEntityDescription entityForName:@"UserDatum" inManagedObjectContext:calculator.managedObjectContext]];
	NSError *error = nil;
	[fetchRequest setPredicate:[NSPredicate predicateWithFormat:@"name like %@", name]];
	
	NSArray *userData = [calculator.managedObjectContext executeFetchRequest:fetchRequest error:&error];
	
	[fetchRequest release];
	
	if (userData && [userData count]) {
		UserDatum *datum = [userData objectAtIndex:0];
		return datum.data;
	}
	else
		return nil;
}
*/

- (void)playKeyClickSound {
	AudioServicesPlaySystemSound(keyClickSoundID);
}

- (BOOL)installMenu:(NSString *)menuTitle withStartIndex:(NSInteger)startIndex {
	for (Menu *menu in calculator.menus) {
		if ([menu.title isEqualToString:menuTitle]) {
			if (![currentMenuTitle isEqualToString:@"User"])
				self.previousMenuTitle = self.currentMenuTitle;
			self.currentMenuTitle = menuTitle;

			NSArray *softKeyNames = [menu.name componentsSeparatedByString:@", "];
			NSArray *softKeyFunctions = [menu.function componentsSeparatedByString:@", "];
			NSUInteger maxSoftKeys = MIN([softKeyNames count], [softKeyFunctions count]);

			// wrap startIndex
			if (startIndex < 0) {
				startIndex = (maxSoftKeys / [softKeys count]) * [softKeys count];
				if (startIndex == maxSoftKeys)
					startIndex = maxSoftKeys-[softKeys count];
			}
			else if (startIndex > maxSoftKeys-1)
				startIndex = 0;
			currentMenuStartIndex = startIndex;

			NSUInteger runningCount = startIndex;
			for (UIButton *button in softKeys) {
				NSString *name = @"";
				NSString *function = @"";
				if (runningCount < maxSoftKeys) {
					name = [softKeyNames objectAtIndex:runningCount];
					function = [softKeyFunctions objectAtIndex:runningCount];
					++runningCount;
				}
				
				// special case treatment for certain keys
				if ([function isEqualToString:@"@mode_radians"] || [function isEqualToString:@"@mode_degrees"]) { // angle mode
					BOOL wantsDegrees = [[webView stringByEvaluatingJavaScriptFromString:@"calculator.mode.angle.inRadians"] isEqualToString:@"false"];
					if (wantsDegrees == [function isEqualToString:@"@mode_degrees"])
						name = [NSString stringWithFormat:@"%@ ■", name];
				}
				else if ([function isEqualToString:@"@mode_rect"] || [function isEqualToString:@"@mode_polar"] || [function isEqualToString:@"@mode_spherical"]) { // vector display mode
					NSString *vecMode = [webView stringByEvaluatingJavaScriptFromString:@"calculator.mode.angle.vectors"];
					NSString *keyMode = [function stringByReplacingOccurrencesOfString:@"@mode_" withString:@""];
					if ([vecMode isEqualToString:keyMode])
						name = [NSString stringWithFormat:@"%@ ■", name];
				}
				else if ([function isEqualToString:@"@toNormal"] || [function isEqualToString:@"@toFixed"] || [function isEqualToString:@"@toExponential"] || [function isEqualToString:@"@toEngineering"]) { // number representation keys
					NSString *numRep = [webView stringByEvaluatingJavaScriptFromString:@"calculator.mode.number_representation.type"];
					if (   ([function isEqualToString:@"@toNormal"] && [numRep isEqualToString:@"normal"])
						|| ([function isEqualToString:@"@toFixed"] && [numRep isEqualToString:@"fixed"])
						|| ([function isEqualToString:@"@toExponential"] && [numRep isEqualToString:@"scientific"])
						|| ([function isEqualToString:@"@toEngineering"] && [numRep isEqualToString:@"engineering"])
						)
						name = [NSString stringWithFormat:@"%@ ■", name];
				}
				
				[button setTitle:name forState:UIControlStateNormal];
				[button setTitle:function forState:UIControlStateApplication];
			}
			return YES;
		}
	}
	
	return NO;
}

- (BOOL)installMenu:(NSString *)menuTitle {
	if ([menuTitle isEqualToString:@"User"])
		return [self installUserMenuWithStartIndex:0 showCategories:[currentMenuTitle isEqualToString:@"User"]];
	else {
		if ([menuTitle isEqualToString:@"Previous"])
			menuTitle = [previousMenuTitle copy];
		return [self installMenu:menuTitle withStartIndex:0];
	}
}

- (BOOL)showNextBatchOfSoftKeys:(int)sense {
	NSInteger index = currentMenuStartIndex + ([softKeys count] * sense);
	return (currentMenuTitle ? ([currentMenuTitle isEqualToString:@"User"] ? [self installUserMenuWithStartIndex:index showCategories:hasLastShownCategories] : [self installMenu:currentMenuTitle withStartIndex:index]) : NO);
}

- (void)showMenus:(NSNumber *)shouldShow {
	[NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(showMenus:) object:[NSNumber numberWithBool:NO]];

	[UIView beginAnimations:nil context:NULL];
	[UIView setAnimationDuration:0.3];
	
	menusView.alpha = [shouldShow floatValue];
	if ([shouldShow boolValue])
		[self performSelector:@selector(showMenus:) withObject:[NSNumber numberWithBool:NO] afterDelay:10.0];

	[UIView commitAnimations];
}

- (void)updateDeleteUndoButton {
	if (inputTextField.text.length || inputTextUI == (UITextField *)inputTextView) {
		// show delete symbol
		if (deleteButtonIsShowingUndo) {
			[deleteButton setTitle:@"⌫" forState:UIControlStateNormal];
			deleteButtonIsShowingUndo = NO;
			// also set drop symbol
			if ([calculator.type.name isEqualToString:@"Normal"]) // isInAlgebraicMode
				[dropButton setTitle:NSLocalizedString(@"Ans", nil) forState:UIControlStateNormal];
		}
		if (calcButtonIsShowingEnter && [calculator.type.name isEqualToString:@"Normal"] && [inputTextField.text rangeOfCharacterFromSet:operatorCharacterSet].length) {
			[calcButton setTitle:@"=" forState:UIControlStateNormal];
			calcButtonIsShowingEnter = NO;
		}
	}
	else {
		// show undo symbol
		if (!deleteButtonIsShowingUndo) {
			[deleteButton setTitle:(isShowingGraphics ? @"✓↶" : @"↶") forState:UIControlStateNormal]; // todo: if pressing will result in redo, use ↪
			deleteButtonIsShowingUndo = YES;
			// also set drop symbol
			if ([calculator.type.name isEqualToString:@"Normal"]) // isInAlgebraicMode
				[dropButton setTitle:dropButtonString forState:UIControlStateNormal];
		}
		// show enter symbol
		if (!calcButtonIsShowingEnter) {
			[calcButton setTitle:calcButtonString forState:UIControlStateNormal]; // todo: if pressing will result in redo, use ↪
			calcButtonIsShowingEnter = YES;
		}
	}
}

- (IBAction)installMenuFromButton:(id)sender {
	[self playKeyClickSound];
	[self installMenu:[sender titleForState:UIControlStateNormal]];
	[self showMenus:[NSNumber numberWithBool:NO]];

	// also hide tab bar, if not fully visible
	UITabBar *tabBar = ((CalculateAppDelegate *)[[UIApplication sharedApplication] delegate]).tabBarController.tabBar;
	if (tabBar.alpha < 1.0)
		[self showTabBar:[NSNumber numberWithBool:NO]];
}

- (void)setState:(BOOL)b forSpecialButton:(UIButton *)button {
    const BOOL wantsClassicLook = (floor(NSFoundationVersionNumber) <= NSFoundationVersionNumber_iOS_6_1); // is pre-iOS 7 ?
    if (!wantsClassicLook) {
        if ([skinName isEqualToString:@"Light"])
            skinName = @"iOS";
        else if ([skinName isEqualToString:@"Dark"])
            skinName = @"iOSDark";
    }

	UIImage *backgroundImage = [UIImage imageNamed:[NSString stringWithFormat:@"%@Button%@%@.png", skinName, @"_special", (keyLevel ? @"H" : @"")]];
	
	// load image from alternative location, if necessary (this is where "Custom" will always be found)
	if (!backgroundImage) {
		NSString *imagePath = [[(CalculateAppDelegate *)[[UIApplication sharedApplication] delegate] applicationDocumentsDirectory] stringByAppendingPathComponent:[NSString stringWithFormat:@"%@Button%@%@.png", skinName, @"_special", (keyLevel ? @"H" : @"")]];
		backgroundImage = [UIImage imageWithContentsOfFile:imagePath];
	}
	
	[button setBackgroundImage:backgroundImage forState:UIControlStateNormal];
}

- (void)setEditLineToText:(NSString *)text {
	if ([text rangeOfString:@"\n"].length > 0 && inputTextUI != (UITextField *)inputTextView) { // contains NLs
		text = [text stringByReplacingOccurrencesOfString:@"\t" withString:@"    "]; // replace TABs with spaces
		[self morphInputUI];
	}
	inputTextUI.text = text;	
}

- (void)insertString:(NSString *)insertingString intoTextView:(UITextView *) textView {
    NSRange range = textView.selectedRange;  
    NSString * firstHalfString = [textView.text substringToIndex:range.location];
    NSString * secondHalfString = [textView.text substringFromIndex: range.location];
    textView.scrollEnabled = NO;

    textView.text = [NSString stringWithFormat: @"%@%@%@",
					 firstHalfString,
					 insertingString,
					 secondHalfString];
    range.location += [insertingString length];
    textView.selectedRange = range;
    textView.scrollEnabled = YES;
}

-(void)hideKeyboard:(NSNotification *)notification {
/*
    for (UIWindow *windows in [[UIApplication sharedApplication] windows]) {
        for (UIView *view in [windows subviews]) {
            if([[view description] hasPrefix:@"<UIKeyboard"] == YES
            || [[view description] hasPrefix:@"<UIPeripheralHostView"])
                view.alpha = 0;
        }
    }
*/
    // Locate non-UIWindow.
    UIWindow *keyboardWindow = nil;
    for (UIWindow *testWindow in [[UIApplication sharedApplication] windows]) {
        if (![[testWindow class] isEqual:[UIWindow class]]) {
           keyboardWindow = testWindow;
           break;
       }
    }

    // Locate UIKeyboard.  
    for (UIView *possibleKeyboard in [keyboardWindow subviews]) {

        // iOS 4 sticks the UIKeyboard inside a UIPeripheralHostView.
        if ([[possibleKeyboard description] hasPrefix:@"<UIPeripheralHostView"]) {
            possibleKeyboard = [[possibleKeyboard subviews] objectAtIndex:0];
        }                                                                                

        if ([[possibleKeyboard description] hasPrefix:@"<UIKeyboard"]) {
            possibleKeyboard.alpha = 0;
           break;
        }
    }
}

- (void)addToInputUI:(NSString *)insertString {
	if (inputTextUI == (UITextField *)inputTextView) {
		[self insertString:insertString intoTextView:inputTextView]; // this will insert at insertion point, if any
		[inputTextView scrollRangeToVisible:inputTextView.selectedRange]; // scroll to insert
	}
	else {
		// todo: insert instead of append; attempted: [inputTextField insertText:insertString];
/***
        if (![inputTextUI isFirstResponder]) {
            [inputTextUI becomeFirstResponder];
            [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(hideKeyboard:) name:UIKeyboardWillShowNotification object:nil];
        }
*/
        if ([inputTextUI isFirstResponder]) {
            UIPasteboard* lPasteBoard = [UIPasteboard generalPasteboard];
            NSArray* lPasteBoardItems = [lPasteBoard.items copy];

            lPasteBoard.string = insertString;

            [inputTextUI paste:self];

            lPasteBoard.items = lPasteBoardItems;
            [lPasteBoardItems release];
        }
        else {
            // this is needed (on iOS 6, at least) to ensure initially typed text (after app launch) appears in the edit line
            if (inputTextUI.text == nil)
                inputTextUI.text = @"";

            inputTextUI.text = [inputTextUI.text stringByAppendingString:insertString]; // todo: really want to insert instead of append
///            NSUInteger lastPos = 0;///inputTextUI.text.length-1;
///            [inputTextUI setSelectedTextRange:[inputTextUI textRangeFromPosition:lastPos toPosition:lastPos]];
        }
	}
	[self updateDeleteUndoButton];
}

- (void)pressAlternateButton {
	if (alternateButton)
		[alternateButton sendActionsForControlEvents:UIControlEventTouchUpInside];
}

- (void)onButtonTouchDown:(UIButton *)sender {
	[self performSelector:@selector(pressAlternateButton) withObject:nil afterDelay:0.4];
}

- (void)onButtonPress:(UIButton *)sender {
	[NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(pressAlternateButton) object:nil];

	[self playKeyClickSound];

///was:	NSArray *keyFunctions = [[sender titleForState:UIControlStateApplication] componentsSeparatedByString:@", "];
	NSArray *keyFunctions = [self completedComponentsIn:[sender titleForState:UIControlStateApplication] separatedByString:@", "];

	if (sender == alternateButton/*was: [[keyFunctions objectAtIndex:0] isEqualToString:@"@alternate"]*/) {
		[self setState:(keyLevel = !keyLevel) forSpecialButton:alternateButton];
		return;
	}

	BOOL isAlternatedSoftkey = ((keyLevel != 0) && [softKeys containsObject:sender]);
	if (isAlternatedSoftkey)
		keyLevel = 0;

	if ([sender superview] == menusView) // is a @key on a menu?
		[self showMenus:[NSNumber numberWithBool:NO]]; // hide pop-up menu

	NSString *keyFunction = (keyLevel < [keyFunctions count] ? [keyFunctions objectAtIndex:keyLevel] : nil);
	if (keyFunction)
		keyFunction = [keyFunction stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];

	[self setState:(keyLevel = 0) forSpecialButton:alternateButton]; // reset to normal key level after one use

	// stop if this is not an alternated soft key and there's no key function
	if (!isAlternatedSoftkey && !(keyFunction && keyFunction.length))
		return;

	// fast-track number keys for best response
	if ((keyFunction.length == 1 && [[NSCharacterSet decimalDigitCharacterSet] characterIsMember:[keyFunction characterAtIndex:0]])) {
		[self addToInputUI:keyFunction];
		return;
	}
	
	if (isAlternatedSoftkey && ![currentMenuTitle isEqualToString:@"User"] && ![keyFunction hasPrefix:@"≪"]) {
		[((CalculateAppDelegate *)[[UIApplication sharedApplication] delegate]) showHelpFor:keyFunction inMenu:currentMenuTitle];
	}
																						
	// special case detection for space character
	BOOL isSpaceKey = (sender == spaceButton && [keyFunction isEqualToString:@"\" \""]);	
	// special case ending graphics display if space or del are pressed
	if (isSpaceKey || (sender == deleteButton && [keyFunction isEqualToString:@"@del"] && deleteButtonIsShowingUndo)) {
		if ([[webView stringByEvaluatingJavaScriptFromString:@"display.wantsStackDisplay"] isEqualToString:@"false"]) {
			[webView stringByEvaluatingJavaScriptFromString:@"display.showGraphics(false); calculator.show()"];
			if (isSpaceKey)
				return;
		}
		if (isSpaceKey)
			keyFunction = @" ";
	}

	BOOL isCalcKey = [keyFunction isEqualToString:@"@calc"];
	////static BOOL lastCommandWasCalc = NO;

	NSString *inputText = inputTextUI.text;

	// figure if we're in algebraic (and implied string) mode
	BOOL isInAlgebraicMode = [calculator.type.name isEqualToString:@"Normal"];
	BOOL isInStringMode = isInAlgebraicMode;

	// figure if this is a RPL program or we're in program entry mode
	BOOL isRPLProgram = ([keyFunction hasPrefix:@"≪"] && [keyFunction hasSuffix:@"≫"]);
	BOOL isEmptyRPLProgram = (isRPLProgram && keyFunction.length == 2);
	if (isEmptyRPLProgram && inputTextUI == inputTextField)
		[self performSelector:@selector(morphInputUI) withObject:nil afterDelay:0.0];
	BOOL isInRPLProgramMode = (isEmptyRPLProgram || (!isRPLProgram && ((inputText.length && [inputText hasPrefix:@"≪"]) || [keyFunction isEqualToString:@"≪"]))); // note: if keyFunction is a full RPL program, we do not switch into this mode
/*
	if (isInAlgebraicMode && inputText.length) { // special algebraic mode behavior
		NSCharacterSet *operators = [NSCharacterSet characterSetWithCharactersInString:@"+*-/%"];
		if (keyFunction.length > 1) {
			if (![operators characterIsMember:[inputText characterAtIndex:inputText.length-1]])
				isInStringMode = NO;
		}
		else if (lastCommandWasCalc && [operators characterIsMember:[keyFunction characterAtIndex:0]]) {
			inputTextUI.text = @"";
		}
	}
	lastCommandWasCalc = NO;
*/
	if (!isInAlgebraicMode && inputText.length) { // special RPN behavior
/*
- (NSInteger)locationOfLastSeparatingCommaInString:(NSString *)input {
NSRange r = [input rangeOfString:@"," options:NSBackwardsSearch];
return (r.length ? r.location : -1);
}
NSInteger commmaLocation = [self locationOfLastSeparatingCommaInString:inputText];
		if (commmaLocation >= 0 && commmaLocation < inputText.length-1) // there's a comma and it's not at the last position
			isInStringMode = [self stringHasOpenQuote:[inputText substringFromIndex:commmaLocation]];
		else
			isInStringMode = [self stringHasOpenQuote:inputText];
*/
		NSArray *inputComponents = [self completedComponentsIn:inputText separatedByString:@","];
		isInStringMode = [self stringHasOpenQuote:[inputComponents lastObject]];

/*		// special case treatment for "-":
		if (!isInStringMode && [keyFunction isEqualToString:@"-"] && [self stringHasOpenBrace:[inputComponents lastObject]])
			isInStringMode = YES; */
	}
	if (!isInAlgebraicMode && ([keyFunction isEqualToString:@"'"]))
		isInStringMode = !isInStringMode;
	else // in string mode, remove any pre-existing string delimiters from non-"'" key functions
		if (isInStringMode && ([keyFunction hasPrefix:@"'"] || [keyFunction hasSuffix:@"'"]))
			keyFunction = [keyFunction stringByTrimmingCharactersInSet:[NSCharacterSet punctuationCharacterSet]];

	if (isInStringMode)
		isInRPLProgramMode = false; // string mode precedes program mode

	if (isInRPLProgramMode) { // still in program mode?
		// do special mappings
		if ([keyFunction isEqualToString:@"["])
			keyFunction = @"⇢";
		else if ([keyFunction isEqualToString:@"("])
			keyFunction = @"x";
		else if ([keyFunction isEqualToString:@")"])
			keyFunction = @"y";
	}

	NSString *aliasedKeyFunction = keyFunction;
	if (keyFunction.length >= 2 && [calculator.name rangeOfString:@"Classic"].length) { // if this is a Classic calc, see if this is an alias for a function
		// see if there
		NSString *unaliasedFunctionName = [webView stringByEvaluatingJavaScriptFromString:[NSString stringWithFormat:@"calculator.function_aliases['%@']", keyFunction]];
		if (unaliasedFunctionName && unaliasedFunctionName.length) {
			// NSLog(@"Switching to internal name %@ for %@", unaliasedFunctionName, keyFunction);
			keyFunction = unaliasedFunctionName;
		}
	}

	if ([keyFunction hasPrefix:@"@"] || [keyFunction isEqualToString:@"drop"]) { // a calculator internal function (or drop -> Ans() in non-RPN mode)
		BOOL isDone = YES;
/*
		if ([keyFunction isEqualToString:@"@visit"]) {
			if (!inputText.length) {
				[webView stringByEvaluatingJavaScriptFromString:@"calculator.push('@var_recall')"];
				keyFunction = @"@edit";
			}
		}
*/	
		if ([keyFunction isEqualToString:@"@edit"]) {
			if (!inputText.length) {
				NSString *text = [webView stringByEvaluatingJavaScriptFromString:@"calculator.stringOfFirstStackItem()"];
				if (text.length) {
					[webView stringByEvaluatingJavaScriptFromString:@"calculator.pop()"];
					[self setEditLineToText:text];
				}
			}
		}
		else if ([keyFunction isEqualToString:@"@command"]) {
			if (!inputText.length && lastPushedEditLine) {
				inputTextUI.text = lastPushedEditLine;
			}
		}
		else if ([keyFunction isEqualToString:@"@sign"]) {
			if (!isInRPLProgramMode && inputText.length) {
				NSString *replacementString = @"-";
				NSRange range = NSMakeRange(isInStringMode && !isInAlgebraicMode ? 1 : 0, 0);
				NSMutableCharacterSet *mutableNumberFormattingCharacterSet = [[[NSCharacterSet decimalDigitCharacterSet] mutableCopy] autorelease];
				[mutableNumberFormattingCharacterSet addCharactersInString:@"."];
				[mutableNumberFormattingCharacterSet invert];
				NSRange numberRange = [inputText rangeOfCharacterFromSet:mutableNumberFormattingCharacterSet options:NSBackwardsSearch];
				if (numberRange.length != 0) {
					range.location = numberRange.location+1;
					unichar c = [inputText characterAtIndex:range.location-1];
					if (c == [@"+" characterAtIndex:0] || c == [@"-" characterAtIndex:0]) {
						range.location = range.location-1;
						range.length = 1; // will cause that character to be replaced
						if (c == [@"-" characterAtIndex:0])
							replacementString = @"+";
					}
				}
				inputTextUI.text = [inputText stringByReplacingCharactersInRange:range withString:replacementString];
			}
			else {
				keyFunction = @"neg";
				aliasedKeyFunction = keyFunction;
				isDone = NO;
			}
		}
		else if ([keyFunction isEqualToString:@"@del"]) {
			if (inputText.length)
				inputTextUI.text = [inputText substringToIndex:[inputText length]-1];
			else {
				[webView stringByEvaluatingJavaScriptFromString:@"calculator.undo()"];
				if (isInAlgebraicMode) {
					// do a @command
					if (lastPushedEditLine)
						inputTextUI.text = lastPushedEditLine;
				}
			}
		}
		else if (!isInRPLProgramMode && ([keyFunction isEqualToString:@"@drop"] || [keyFunction isEqualToString:@"drop"])) {
			if (inputText.length) {
				if (isInAlgebraicMode)
#ifdef WANTS_CHEAP_CALC_ALGEBRAIC
					inputTextUI.placeholder = @"0";
#else
					[self addToInputUI:@"Ans(1)"];
#endif
				else
					inputTextUI.text = @"";
			}
			else
				isDone = NO;
		}
		else if ([keyFunction isEqualToString:@"@mode_degrees"] || [keyFunction isEqualToString:@"@mode_radians"]) {
			BOOL wantsDegrees = [keyFunction isEqualToString:@"@mode_degrees"];
			[webView stringByEvaluatingJavaScriptFromString:[NSString stringWithFormat:@"calculator.setToRadians(%@); calculator.show()", (wantsDegrees ? @"false" : @"true")]];
			NSString *angleShowPref = [[NSUserDefaults standardUserDefaults] stringForKey:@"anglemodeshow_preference"];
			angleModeLabel.text = (wantsDegrees && [angleShowPref rangeOfString:@"360"].length ? @"360°" : (!wantsDegrees && [angleShowPref rangeOfString:@"2pi"].length ? @"2π" : @""));
			[self showNextBatchOfSoftKeys:0]; // re-display current menu
		}
		else if ([keyFunction isEqualToString:@"@mode_rect"] || [keyFunction isEqualToString:@"@mode_polar"] || [keyFunction isEqualToString:@"@mode_spherical"]) {
			NSString *vecMode = [keyFunction stringByReplacingOccurrencesOfString:@"@mode_" withString:@""];
			[webView stringByEvaluatingJavaScriptFromString:[NSString stringWithFormat:@"calculator.setVectorDisplayMode('%@'); calculator.show()", vecMode]];
			vectorDisplayModeLabel.text = ([vecMode rangeOfString:@"polar"].length ? @"r∠z" : ([vecMode rangeOfString:@"spherical"].length ? @"r∠∠" : @""));
			[self showNextBatchOfSoftKeys:0]; // re-display current menu
		}
		else if ([keyFunction isEqualToString:@"@undo"])
			[webView stringByEvaluatingJavaScriptFromString:@"calculator.undo()"];
		else if ([keyFunction hasPrefix:@"@menu:"])
			[self installMenu:[keyFunction substringFromIndex:6]];
		else if ([keyFunction hasPrefix:@"@show_menus"]) {
			if (![[sender titleForState:UIControlStateNormal] isEqualToString:@"◉"]) {
				NSNumber *shouldShow = [NSNumber numberWithBool:(menusView.alpha ? NO : YES)];
				[self showMenus:shouldShow];

				// also half blend in tabBar if not fully visible
				UITabBar *tabBar = ((CalculateAppDelegate *)[[UIApplication sharedApplication] delegate]).tabBarController.tabBar;
				if (tabBar.alpha < 1.0)
					[self showTabBar:[NSNumber numberWithFloat:([shouldShow boolValue] ? 0.9f : 0.0f)]];
			}
			else
				[self resizeWebUI:YES];
		}
		else if ([keyFunction hasPrefix:@"@select_category:"])
			[self selectCategory:[keyFunction substringFromIndex:17] andShow:YES];
		else if ([keyFunction hasPrefix:@"@next_softkeys"])
			[self showNextBatchOfSoftKeys:+1];
		else if ([keyFunction hasPrefix:@"@previous_softkeys"])
			[self showNextBatchOfSoftKeys:-1];
		else if ([keyFunction isEqualToString:@"@startLog"]) {
			[webView stringByEvaluatingJavaScriptFromString:@"calculator.analytics.startLogging()"];
			recordingLabel.hidden = false;
		}
		else if ([keyFunction isEqualToString:@"@stopLog"]) {
			[webView stringByEvaluatingJavaScriptFromString:@"calculator.analytics.stopLogging(); if (calculator.analytics.log.length) calculator.push(calculator.convertLogToRPLProgram())"];
			recordingLabel.hidden = true;
		}
		else
			isDone = NO;
		
		if (isDone) {
			[self updateDeleteUndoButton];
			return;
		}
		
		isInStringMode = NO; // internal commands shall never go into expressions but instead be acted upon
	}		

	const BOOL isNumberFormattingKey = (keyFunction.length == 1 && [numberFormattingCharacterSet characterIsMember:[keyFunction characterAtIndex:0]]);
	if (((isInStringMode || isInRPLProgramMode) && !isCalcKey) || isNumberFormattingKey || [keyFunction isEqualToString:@" "] || [keyFunction hasPrefix:@"'"] || [keyFunction hasPrefix:@"\""]) {
		if (!inputText.length) { // no present text in edit line
			if (isInAlgebraicMode && [keyFunction rangeOfCharacterFromSet:operatorCharacterSet].length)
				aliasedKeyFunction = [@"Ans(1)" stringByAppendingString:keyFunction];
			else if ([keyFunction isEqualToString:@"E"] && !([numberFormattingCharacterSet characterIsMember:[inputText characterAtIndex:inputText.length-1]]))
				aliasedKeyFunction = @"1E";
		}
		NSString *insertString = [NSString stringWithFormat:@"%@%@%@",
								  aliasedKeyFunction,
								  isInRPLProgramMode && !isEmptyRPLProgram && !isNumberFormattingKey ? @" " : @"",
								  isInStringMode && keyFunction.length > 1 && [[webView stringByEvaluatingJavaScriptFromString:[NSString stringWithFormat:@"calculator.isFunction('%@')", keyFunction]] isEqualToString:@"true"] ? @"(" : @""];
		
		[self addToInputUI:insertString];
	}
	else {
		if ([keyFunction isEqualToString:@" "]) // space is a no-op
			return;

		BOOL isDrawFunction = [keyFunction hasPrefix:@"@draw"];
		if (isDrawFunction && [[[NSUserDefaults standardUserDefaults] objectForKey:@"tips_preference"] boolValue]) {
			UIAlertView *alert = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"GraphingTips", nil) message:NSLocalizedString(@"GraphingTip", nil) delegate:self cancelButtonTitle:nil otherButtonTitles:NSLocalizedString(@"GotIt", nil), nil];
			[alert show];
			[alert release];
		}
		
		BOOL ignoreInputText = isDrawFunction;

		// if there's edited text, push it (unless we specifically ignore it)
		if (inputText.length && !ignoreInputText) {
/*
			NSArray *inputStrings = ([inputText hasPrefix:@"["] ? [NSArray arrayWithObject:inputText] : [inputText componentsSeparatedByString:@","]); // if this is vector or matrix, use the whole input line; otherwise, chop into comma-separated parts
			for (NSUInteger i=0; i<[inputStrings count]; i++) {
				NSString *inputString = [inputStrings objectAtIndex:i];
				if (inputString.length) {
					if ([inputString hasPrefix:@"("] && i<([inputStrings count]-1)) // this is the first part of a complex number
						inputString = [NSString stringWithFormat:@"%@,%@", inputString, [inputStrings objectAtIndex:++i]]; // glue second part back on
					NSInteger errorLoc = -1;
					inputString = [self stringByCompletingEditString:inputString hadErrorAtLocation:&errorLoc];
					if (errorLoc >= 0) {
NSLog(@"Error at location: %d", errorLoc);
						if ((id)inputTextUI == (id)inputTextView)
							inputTextView.selectedRange = NSMakeRange(errorLoc, 1);
						return;
					}
					
					inputString = [inputString stringByReplacingOccurrencesOfString:@"'" withString:@"\\'"];
//// NSLog(@"Push: %@", inputString);
					[webView stringByEvaluatingJavaScriptFromString:[NSString stringWithFormat:@"calculator.push('%@')", inputString]];
				}
			}
*/
			if (([inputText hasPrefix:@"[["] && [inputText hasSuffix:@"]]"]) || ([inputText hasPrefix:@"\""] && [inputText hasSuffix:@"\""]) || ([inputText hasPrefix:@"≪"] && [inputText hasSuffix:@"≫"]) || [inputText hasPrefix:@"/*"]  || [inputText hasPrefix:@"gs:"] /*|| [inputText hasPrefix:@"function"]*/) { // a complete matrix or firm string or RPL program, any code or function (deemed complete)
				// assume input string is complete and the only element on the edit line
				[webView stringByEvaluatingJavaScriptFromString:[NSString stringWithFormat:@"calculator.push(%@)", [inputText JSONFragment]]];
			}
			else {
				NSArray *inputStrings = [self completedComponentsIn:inputText separatedByString:@","];
				for (NSString *inputString in inputStrings) {
					// NSLog(@"inputString: %@", inputString);
					if (inputString.length > 0) {
						if ([inputString hasPrefix:@"[["]) { // a matrix
// was:						inputString = [inputString stringByReplacingOccurrencesOfString:@"\"" withString:@"\\\""];
							inputString = [webView stringByEvaluatingJavaScriptFromString:[NSString stringWithFormat:@"calculator.completeMatrixString(%@)", [inputString JSONFragment]]];
						}
						NSInteger errorLoc = -1;
						inputString = [inputString stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
						if (inputString && inputString.length) {
							inputString = [self stringByCompletingEditString:inputString hadErrorAtLocation:&errorLoc];
							if (errorLoc >= 0) {
								/// NSLog(@"Error at location: %d", errorLoc);
								if ((id)inputTextUI == (id)inputTextView)
									inputTextView.selectedRange = NSMakeRange(errorLoc, 1);
								UIAlertView *alert = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"SyntaxError", nil) message:[NSString stringWithFormat:@"%@ %d", NSLocalizedString(@"UnexpectedParenthesisAtPosition", nil), (int)errorLoc+1] delegate:nil cancelButtonTitle:nil otherButtonTitles:NSLocalizedString(@"OK", nil), nil];
								[alert show];
								[alert release];
								return;
							}
/* was:
							inputString = [inputString stringByReplacingOccurrencesOfString:@"'" withString:@"\\'"];
							if (inputTextUI != inputTextField) { // escape any NL and TAB
								inputString = [inputString stringByReplacingOccurrencesOfString:@"\n" withString:@"\\n"];
								inputString = [inputString stringByReplacingOccurrencesOfString:@"\t" withString:@"\\t"];
							}
 */
							// NSLog(@"About to push: %@", inputString);
							/// todo: if inputString is only whitespace, don't push it
							NSString *result = [webView stringByEvaluatingJavaScriptFromString:[NSString stringWithFormat:@"calculator.push(%@)", [inputString JSONFragment]]];
							if ([result isEqualToString:@"false"])
								return; // if push fails, abort (which implies that the edit line will not be cleared)
						}
					}
				}
			}
			
			// update last pushed line memory
			self.lastPushedEditLine = inputText;
		}
		else if (isCalcKey) { // if pressed without edit line, duplicate the first stack entry
			if ([[webView stringByEvaluatingJavaScriptFromString:@"calculator.stack.length > 0"] isEqualToString:@"false"])
				return; // no-op if nothing on stack
			keyFunction = @"@dup";
			aliasedKeyFunction = keyFunction;
			isCalcKey = NO; // pretend this is no longer the calc key
		}

		// if there're push args, push them
		NSString *optionalPushArgs = [self stringInParenthesesWithString:keyFunction];
		if (optionalPushArgs) {
///was:		NSArray *pushArgs = [optionalPushArgs componentsSeparatedByString:@"; "];
			NSArray *pushArgs = [self completedComponentsIn:optionalPushArgs separatedByString:@","];
			for (NSString *pushArg in pushArgs) {
				pushArg = [pushArg stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]]; // trim possible trailing space

				NSString *stringToPush = nil;
				NSObject *pushObj = [uiObjects objectForKey:pushArg];
				if (pushObj) {
					if ([pushObj class] == [UIDatePicker class]) {
						NSDateFormatter *dateFormatter = [[[NSDateFormatter alloc] init] autorelease];
						NSString *dateFormatString = [uiObjectInfo objectForKey:[NSNumber numberWithInt:(int)pushObj]];
						[dateFormatter setDateFormat:dateFormatString];
						stringToPush = [NSString stringWithFormat:@"\"%@\"", [dateFormatter stringFromDate:((UIDatePicker *)pushObj).date]];
					}
					else if ([pushObj class] == [UISegmentedControl class]) {
//						stringToPush = [NSString stringWithFormat:@"{\"%@\": %d}", pushArg, ((UISegmentedControl *)pushObj).selectedSegmentIndex];
						stringToPush = [NSString stringWithFormat:@"%ld", (long)((UISegmentedControl *)pushObj).selectedSegmentIndex];
					}
					else if ([pushObj class] == [UITextField class]) {
						stringToPush = [NSString stringWithFormat:@"\"%@\"", ((UITextField *)pushObj).text];
					}
				}
				else // push arg is not an object handle; push it instead
					stringToPush = pushArg;

//was:				stringToPush = [stringToPush stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]]; // trim possible trailing space
//// NSLog(@"Push: %@", stringToPush);
				if (stringToPush && stringToPush.length > 0) {
					[webView stringByEvaluatingJavaScriptFromString:[NSString stringWithFormat:@"calculator.push(%@)", [stringToPush JSONFragment]]];
/* was:
					BOOL isFirmString = ([stringToPush characterAtIndex:0] == [@"\"" characterAtIndex:0]);
					if (isFirmString)
						[webView stringByEvaluatingJavaScriptFromString:[NSString stringWithFormat:@"calculator.push('%@')", stringToPush]];
					else
						[webView stringByEvaluatingJavaScriptFromString:[NSString stringWithFormat:@"calculator.push(\"%@\")", stringToPush]];
 */
				}
			}
			
			// remove any pushArgs from keyFunction
			NSRange r = [keyFunction rangeOfString:@"("]; // known to exist
			if (!r.location)
				return; // if there's no function (except push args), we're done
			keyFunction = [keyFunction substringToIndex:r.location]; // all text until before "("
			keyFunction = [keyFunction stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]]; // trim possible trailing space
		}

		// special case treatment for visit key
		if (isAlternatedSoftkey || [keyFunction isEqualToString:@"@visit"]) {
			NSString *varName = (isAlternatedSoftkey ? [NSString stringWithFormat:@"'%@'", keyFunction] : [webView stringByEvaluatingJavaScriptFromString:@"calculator.pop()"]);
			[self setEditLineToText:[webView stringByEvaluatingJavaScriptFromString:[NSString stringWithFormat:@"calculator.stringValueOfItem(calculator.functions['@var_recall'](\"%@\"))", varName]]];
			return;
		}
		
/*
		if ([keyFunction isEqualToString:@"@var_store"]) {
			NSString *name = [webView stringByEvaluatingJavaScriptFromString:@"calculator.stringOfFirstStackItem()"];
			NSString *data = [webView stringByEvaluatingJavaScriptFromString:@"calculator.getSecondStackItem()"];
			if (name.length && [self isValidDatumName:name] && data.length)
				[self storeData:data forName:[name stringByTrimmingCharactersInSet:[NSCharacterSet characterSetWithCharactersInString:@"'\""]]];
			// the keyFunction will continue to be processed by JavaScript
		}
		else if ([keyFunction isEqualToString:@"@var_delete"]) {
			NSString *name = [webView stringByEvaluatingJavaScriptFromString:@"calculator.stringOfFirstStackItem()"];
			if (name.length)
				[self deleteDataForName:[name stringByTrimmingCharactersInSet:[NSCharacterSet characterSetWithCharactersInString:@"'\""]]];
			// the keyFunction will continue to be processed by JavaScript
		}
		else if ([keyFunction isEqualToString:@"@var_recall"]) {
			NSString *name = [webView stringByEvaluatingJavaScriptFromString:@"calculator.stringOfFirstStackItem()"];
			if (name.length) {
				/// todo: make sure name is viable
				[webView stringByEvaluatingJavaScriptFromString:@"calculator.pop()"];
			}
			NSString *data = [self dataForName:[name stringByTrimmingCharactersInSet:[NSCharacterSet characterSetWithCharactersInString:@"'\""]]];
			if (data && data.length)
				[webView stringByEvaluatingJavaScriptFromString:[NSString stringWithFormat:@"calculator.push(\"%@\")", data]];
			return;
		}
*/
/* http: will no longer appear as keyFunction (as only names of variables appear)
 was:
		if ([keyFunction hasPrefix:@"http:"] || (isCalcKey && [inputText hasPrefix:@"http:"])) { // special case treatment for "URL keys" and URL typed in on edit line
			if ([keyFunction hasPrefix:@"http:"])
				[webView stringByEvaluatingJavaScriptFromString:[NSString stringWithFormat:@"calculator.push('\"%@\"')", keyFunction]];
			keyFunction = (optionalPushArgs ? @"loadURLArg" : @"loadURL");
		}
*/
		
		NSString *booleanReturnString = nil;
		if (!isCalcKey) { // execute the function
			if (isRPLProgram) {
				keyFunction = [keyFunction JSONFragment];
				booleanReturnString = [webView stringByEvaluatingJavaScriptFromString:[NSString stringWithFormat:@"calculator.push(%@)", keyFunction]];
			}
			else
				booleanReturnString = [webView stringByEvaluatingJavaScriptFromString:[NSString stringWithFormat:@"calculator.push('%@')", (optionalPushArgs ? keyFunction : aliasedKeyFunction)]];
			// eval pushed key if it's a program
			if (isRPLProgram /*was: || ([softKeys containsObject:sender] && [[webView stringByEvaluatingJavaScriptFromString:[NSString stringWithFormat:@"calculator.isAnRPLProgram(calculator.vars['%@'])", keyFunction]] isEqualToString:@"true"])*/)
				[webView stringByEvaluatingJavaScriptFromString:@"calculator.operate('@eval'); calculator.show()"];
		}
		
		if ([keyFunction hasPrefix:@"@to"]) // special case treatment for toXXX mode keys
			[self showNextBatchOfSoftKeys:0]; // re-display mode menu so that changed switches can be seen

#ifdef WANTS_CHEAP_CALC_ALGEBRAIC
		// todo: see if this is really required; push of algebraic expr should result in automatic eval
		if (isInAlgebraicMode) {
			booleanReturnString = [webView stringByEvaluatingJavaScriptFromString:@"calculator.operate('@eval')"];
			lastCommandWasCalc = YES;
		}
#endif

#ifdef DONT_CLEAR_EDIT_UNLESS_SUCCESSFUL
		// clear edit text if successful
		if (isCalcKey || (booleanReturnString && [booleanReturnString isEqualToString:@"true"]))
			inputTextUI.text = @"";
		else {
			// unknown function: sound a beep or something
			// drop the arg(s) we just added
			[webView stringByEvaluatingJavaScriptFromString:@"calculator.operate('@drop')"];
		}
#else
///#ifdef WANTS_CHEAP_CALC_ALGEBRAIC
		if (isInAlgebraicMode && inputTextUI.text.length && [keyFunction isEqualToString:@"@eval"]) {
			// get first stack item and display (just like @edit)
			inputTextUI.text = [webView stringByEvaluatingJavaScriptFromString:@"calculator.stringOfFirstStackItem()"];
			if (inputTextUI.text.length)
				[webView stringByEvaluatingJavaScriptFromString:@"calculator.pop()"];
		}
		else 
///#endif
		{
			// clear input text (we just consumed it), unless we previously ignored it
			if (!ignoreInputText) {
				inputTextUI.text = @"";
				[self updateDeleteUndoButton];
			}
			// reset input UI to text field
			if ((UITextView *)inputTextUI == inputTextView)
				[self morphInputUI];
		}
		if ([booleanReturnString isEqualToString:@"false"]) {
			// unknown function: sound a beep or something
			UIAlertView *alert = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"CalcError", nil) message:aliasedKeyFunction delegate:nil cancelButtonTitle:nil otherButtonTitles:NSLocalizedString(@"OK", nil), nil];
			[alert show];
			[alert release];
		}
#endif
	}
}

- (IBAction)onDatePick:(UIDatePicker *)sender {
	NSDateFormatter *dateFormatter = [[[NSDateFormatter alloc] init] autorelease];
	NSString *dateFormatString = [uiObjectInfo objectForKey:[NSNumber numberWithInt:(int)sender]];
	[dateFormatter setDateFormat:dateFormatString];
	NSString *dateString = [NSString stringWithFormat:@"\"%@\"", [dateFormatter stringFromDate:sender.date]];
	NSString *stringToPush = [NSString stringWithFormat:@"{\"%@\": \"%@\"}", @"date", dateString];
	[webView stringByEvaluatingJavaScriptFromString:[NSString stringWithFormat:@"window.onUIChange(JSON.parse(%@))", [stringToPush JSONFragment]]];
}

- (IBAction)onSegmentChange:(UISegmentedControl *)sender {
	NSString *stringToPush = [NSString stringWithFormat:@"{\"%@\": %ld}", [uiObjectInfo objectForKey:[NSNumber numberWithInt:(int)sender]], (long)sender.selectedSegmentIndex];
	[webView stringByEvaluatingJavaScriptFromString:[NSString stringWithFormat:@"window.onUIChange(JSON.parse(%@))", [stringToPush JSONFragment]]];
}

- (IBAction)onSliderChange:(UISlider *)sender {
	NSString *stringToPush = [NSString stringWithFormat:@"{\"%@\": %f}", [uiObjectInfo objectForKey:[NSNumber numberWithInt:(int)sender]], sender.value];
	[webView stringByEvaluatingJavaScriptFromString:[NSString stringWithFormat:@"window.onSliderChange(JSON.parse(%@))", [stringToPush JSONFragment]]];
}		  

- (NSString *)pickerView:(UIPickerView *)pickerView titleForRow:(NSInteger)row forComponent:(NSInteger)component {
	NSString *dataCategory = [uiObjectInfo objectForKey:pickerView];
/*
	NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] init];
	[fetchRequest setEntity:[NSEntityDescription entityForName:@"UserDatum" inManagedObjectContext:managedObjectContext]];
	[fetchRequest setPredicate:[NSPredicate predicateWithFormat:@"(category.name == %@) AND (name contains %@)", dataCategory, @"Length"]];
	NSError *error = nil;
	NSArray *userData = [managedObjectContext executeFetchRequest:fetchRequest error:&error];
	[fetchRequest release];

	return ((UserDatum *)[userData objectAtIndex:row]).name;
 */
	return dataCategory;
}

- (void)pickerView:(UIPickerView *)pickerView didSelectRow:(NSInteger)row inComponent:(NSInteger)component {
	NSString *stringToPush = [NSString stringWithFormat:@"{%@: %ld, %ld}", [uiObjectInfo objectForKey:[NSNumber numberWithInt:(int)pickerView]], (long)row, (long)component];
	[webView stringByEvaluatingJavaScriptFromString:[NSString stringWithFormat:@"window.onUIChange(\"%@\")", stringToPush]];
}

- (NSInteger)numberOfComponentsInPickerView:(UIPickerView *)pickerView {
	return 2;
}

- (NSInteger)pickerView:(UIPickerView *)pickerView numberOfRowsInComponent:(NSInteger)component {
	return 2;
}

-(UIButton *)buttonWithTitle:(NSString *)title forSkin:(NSString *)skin buttonClass:(Class)buttonClass isSpecial:(BOOL)isSpecial {
    const BOOL wantsClassicLook = (floor(NSFoundationVersionNumber) <= NSFoundationVersionNumber_iOS_6_1); // is pre-iOS 7 ?
    
    if (!wantsClassicLook) {
        if ([skinName isEqualToString:@"Light"])
            skin = @"iOS";
        else if ([skin isEqualToString:@"Dark"])
            skin = @"iOSDark";
    }

	UIImage *backgroundImage = [UIImage imageNamed:[NSString stringWithFormat:@"%@Button%@.png", skin, isSpecial ? @"_special" : @""]];
	UIImage *backgroundPressedImage = [UIImage imageNamed:[NSString stringWithFormat:@"%@Button%@H.png", skin, isSpecial ? @"_special" : @""]];
	
	// load image from alternative location, if necessary (this is where "Custom" will always be found)
	if (!backgroundImage) {
		NSString *imagePath = [[(CalculateAppDelegate *)[[UIApplication sharedApplication] delegate] applicationDocumentsDirectory] stringByAppendingPathComponent:[NSString stringWithFormat:@"%@Button%@.png", skin, isSpecial ? @"_special" : @""]];
		backgroundImage = [UIImage imageWithContentsOfFile:imagePath];
	}
	if (!backgroundPressedImage) { // try alternative location
		NSString *imagePath = [[(CalculateAppDelegate *)[[UIApplication sharedApplication] delegate] applicationDocumentsDirectory] stringByAppendingPathComponent:[NSString stringWithFormat:@"%@Button%@H.png", skin, isSpecial ? @"_special" : @""]];
		backgroundPressedImage = [UIImage imageWithContentsOfFile:imagePath];
	}
	
	UIButton *button = [[buttonClass buttonWithType:UIButtonTypeCustom] retain];

//	button.contentVerticalAlignment = UIControlContentVerticalAlignmentCenter;
//	button.contentHorizontalAlignment = UIControlContentHorizontalAlignmentCenter;
	
	[button setTitleColor:([skin isEqualToString:@"Light"] || [skin isEqualToString:@"iOS"] ? (wantsClassicLook ? [UIColor colorWithWhite:0.15 alpha:1.0] : [UIColor blackColor])
                                                                                            : (wantsClassicLook ? [UIColor colorWithWhite:0.85 alpha:1.0] : ([skin isEqualToString:@"Dark"] ? [UIColor colorWithWhite:0.8f/*0.57 matches icons on tabbar)*/ alpha:1.0] : [UIColor colorWithWhite:0.96 alpha:1.0])) )
                                                                                            forState:UIControlStateNormal];
	
    CGSize rect = [backgroundImage size];
    UIEdgeInsets caps = { floor(rect.height / 2.0f), floor(rect.width / 2.0f), floor(rect.height / 2.0f + 1), floor(rect.width / 2.0f + 1) };

	UIImage *newImage = [backgroundImage resizableImageWithCapInsets:caps];
	[button setBackgroundImage:newImage forState:UIControlStateNormal];

	UIImage *newPressedImage = [backgroundPressedImage resizableImageWithCapInsets:caps];
	[button setBackgroundImage:newPressedImage forState:UIControlStateHighlighted];

	button.titleEdgeInsets = ([skin isEqualToString:@"Dark"] ? UIEdgeInsetsMake(2/*was: 5*/, 5, 0, 5) : UIEdgeInsetsMake(0, 3, 0, 3)); 

	button.backgroundColor = [UIColor clearColor];

	[button setTitle:title forState:UIControlStateNormal];	

	return button;
}

-(UIButton *)buttonWithTitle:(NSString *)title forSkin:(NSString *)skin {
	return [self buttonWithTitle:title forSkin:skin buttonClass:[UIButton class] isSpecial:NO];
}

- (void)feedCalcEngineWithUserData {
	{ // create objects for categories that will be added with dot notation
		NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] init];
		[fetchRequest setEntity:[NSEntityDescription entityForName:@"UserDataCategory" inManagedObjectContext:managedObjectContext]];
		NSError *error = nil;
		NSArray *userDataCategories = [managedObjectContext executeFetchRequest:fetchRequest error:&error];
		[fetchRequest release];
		
		for (UserDataCategory *category in userDataCategories) {
			[webView stringByEvaluatingJavaScriptFromString:[NSString stringWithFormat:@"calculator.vars[\"%@\"] = {}", category.name]];
			[webView stringByEvaluatingJavaScriptFromString:[NSString stringWithFormat:@"calculator.functions[\"%@\"] = {}", category.name]];
			// if a folder is translated, also make aliases with that name, so that programs can always access it
			NSString *localizedCategoryName = NSLocalizedString(category.name, nil);
			if (![localizedCategoryName isEqualToString:category.name]) {
				[webView stringByEvaluatingJavaScriptFromString:[NSString stringWithFormat:@"calculator.vars[\"%@\"] = calculator.vars[\"%@\"]", NSLocalizedString(category.name, nil), category.name]];
				[webView stringByEvaluatingJavaScriptFromString:[NSString stringWithFormat:@"calculator.functions[\"%@\"] = calculator.functions[\"%@\"]", NSLocalizedString(category.name, nil), category.name]];
			}
			// if a folder name has two words, also make abbreviated aliases to that name, so that programs can access it with "." notation
			NSRange r = [category.name rangeOfString:@" "];
			if (r.length && r.location > 0 && r.location+2 < category.name.length) {
				unichar abbreviatedChars[2];
				abbreviatedChars[0] = [category.name characterAtIndex:0];
				abbreviatedChars[1] = [category.name characterAtIndex:r.location+1];
				NSString *abbreviatedName = [NSString stringWithCharacters:abbreviatedChars length:2];
				[webView stringByEvaluatingJavaScriptFromString:[NSString stringWithFormat:@"calculator.vars[\"%@\"] = calculator.vars[\"%@\"]", abbreviatedName, category.name]];
				[webView stringByEvaluatingJavaScriptFromString:[NSString stringWithFormat:@"calculator.functions[\"%@\"] = calculator.functions[\"%@\"]", abbreviatedName, category.name]];
			}
		}

		[webView stringByEvaluatingJavaScriptFromString:[NSString stringWithFormat:@"calculator.vars.Units = {}; calculator.vars[\"%@\"] = calculator.vars.Units", NSLocalizedString(@"Units", nil)]]; // Units are used non-localized
	}

	NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] init];
	[fetchRequest setEntity:[NSEntityDescription entityForName:@"UserDatum" inManagedObjectContext:managedObjectContext]];
	NSError *error = nil;
	NSArray *userData = [managedObjectContext executeFetchRequest:fetchRequest error:&error];
	[fetchRequest release];
	
	for (UserDatum *datum in userData) {
		NSString *categoryName = NSLocalizedString(datum.category.name, nil);
		if ([datum.data hasPrefix:@"f("] || [datum.data hasPrefix:@"'f("]) {
			NSString *fDefinition = datum.data;
			[webView stringByEvaluatingJavaScriptFromString:[NSString stringWithFormat:@"calculator.currentDataCategory=\"%@\"; ME[\"%@\"][\"%@\"] = ME.expr.functionForNaturalMath(\"%@\"); calculator.vars[\"%@\"][\"%@\"] = \"%@\"", categoryName, categoryName, datum.name, fDefinition, categoryName, datum.name, fDefinition]];
		}
		else if ([datum.data hasPrefix:@"function("] || [datum.data hasPrefix:@"function ("]) {
			NSString *fDefinition = datum.data;
/* was: 
 subsumed by above
 todo: delete
			if ([fDefinition hasPrefix:@"f("]) {
				// transcribe math function definition into JavaScript
				NSRange r = [fDefinition rangeOfString:@")"];
				if (r.length) {
					r.length = r.location - 1 + 1;
					r.location = 1; // skipping "f"
					NSString *part1 = [fDefinition substringWithRange:r]; // "(x, y, ...)"
					
					r = [fDefinition rangeOfString:@"="];
					if (r.length) {
						NSString *part2 = [fDefinition substringFromIndex:r.location+1]; // body of the definition
						fDefinition = [NSString stringWithFormat:@"function%@ { return %@; }", part1, part2];
					}
				}
			}
*/
			// add to calculator.functions after ensuring there's curly braces
			NSRange range = [fDefinition rangeOfString:@"{"];
			if (range.length) {
				NSString *completedFDefinition = fDefinition;

				// conditionally, insert 'with' instructions into the function definition
				if (![fDefinition rangeOfString:@"/*as is*/"].length) {
					// first, split string into two parts
					NSString *part1 = [fDefinition substringToIndex:range.location+1]; // include "{"
					NSRange range2 = [fDefinition rangeOfString:@"}" options:NSBackwardsSearch];
					if (range2.length) {
						range.location++; // step over "{"
						range.length = range2.location - range.location + 1;
						NSString *part2 = [fDefinition substringWithRange:range];
//						NSString *part2a = [fDefinition substringWithRange:range];
//						NSString *part2 = [part2a stringByReplacingOccurrencesOfString:@"\\" withString:@"\\\\"]; // escape escapes
// if ([categoryName isEqualToString:@"Examples"] && [datum.name isEqualToString:@"fib"]) NSLog(@"\npart2a: %@\npart2:  %@", part2a, part2);
///						NSString *completedFDefinition = [NSString stringWithFormat:@"%@ %@", part1, part2]; /* debug */
						completedFDefinition = [NSString stringWithFormat:@"%@ with (calculator.vars[\"%@\"]) with (calculator.functions) with (calculator.functions[\"%@\"]) { %@ }", part1, categoryName, categoryName, part2];
					}						
				}
				[webView stringByEvaluatingJavaScriptFromString:[NSString stringWithFormat:@"calculator.functions[\"%@\"][\"%@\"] = %@", categoryName, datum.name, completedFDefinition]];
			}
		}
		else {
			NSString *data = datum.data;
			if (!data.length) // ignore empty strings
				continue;
			// a string of a string (which can contain single- or double-quotes), number, object, array
			// must be installed in calculator as its value, except an array is to remain a string (for the time being)
			
			// double-encode non-object and -number type so that a) JSON.parse can be used and b) it will parse into a string
/*			NSString *val = [data JSONFragmentValue];
			if (!(val && ([val isKindOfClass:[NSDictionary class]] || [val isKindOfClass:[NSArray class]] || [datum isKindOfClass:[NSNumber class]])))
				data = [data JSONFragment];
			data = [data stringByReplacingOccurrencesOfString:@"\\" withString:@"\\\\"]; // escape escapes
			data = [data stringByReplacingOccurrencesOfString:@"\"" withString:@"\\\""]; // escape double quotes
			NSString *str = [NSString stringWithFormat:@"calculator.vars[\"%@\"][\"%@\"] = JSON.parse(\"%@\")", categoryName, datum.name, data];
*/
			// NSLog(@"%@", data);

			const unichar stringChars[] = { [@"'" characterAtIndex:0], [@"\"" characterAtIndex:0], [@"≪" characterAtIndex:0], [@"(" characterAtIndex:0], [@"π" characterAtIndex:0] };
			unichar firstChar = [data characterAtIndex:0];
			if (firstChar == stringChars[0] || firstChar == stringChars[1] || firstChar == stringChars[2] || firstChar == stringChars[3] || firstChar == stringChars[4])
				data = [data JSONFragment];
			
			NSString *str = [NSString stringWithFormat:@"calculator.vars[\"%@\"][\"%@\"] = %@", categoryName, datum.name, data];
			[webView stringByEvaluatingJavaScriptFromString:str];
/* was:
			if ([datum.category.name isEqualToString:@"Units"])
				[webView stringByEvaluatingJavaScriptFromString:[NSString stringWithFormat:@"calculator.vars.Units[\"%@\"] = eval('(' + '%@' + ')')", datum.name, [datum.data stringByReplacingOccurrencesOfString:@"'" withString:@"\\'"]]];
			else {
				NSString *data = [datum.data stringByReplacingOccurrencesOfString:@"\\" withString:@"\\\\"]; // escape escapes
				data = [data stringByReplacingOccurrencesOfString:@"\"" withString:@"\\\""]; // escape double quotes
				[webView stringByEvaluatingJavaScriptFromString:[NSString stringWithFormat:@"var tmp = \"%@\"; calculator.vars[\"%@\"][\"%@\"] = (calculator.isAnObject(tmp) ? JSON.parse(tmp) : (calculator.isADecimalNumber(tmp) ? eval(tmp) : tmp))", data, categoryName, datum.name]];
			}
*/
/* was long ago:
// NSLog(@"%@: calculator.vars[\"%@\"] = '%@'", categoryName, datum.name, [datum.data stringByReplacingOccurrencesOfString:@"'" withString:@"\\'"]);
			if ([categoryName isEqualToString:@"Units"])
				[webView stringByEvaluatingJavaScriptFromString:[NSString stringWithFormat:@"calculator.vars.%@['%@'] = eval('(' + '%@' + ')')",  categoryName,  datum.name, [datum.data stringByReplacingOccurrencesOfString:@"'" withString:@"\\'"]]];
			else {
/// was:				NSString *data = [datum.data stringByReplacingOccurrencesOfString:@"'" withString:@"\\'"];
/// was:				[webView stringByEvaluatingJavaScriptFromString:[NSString stringWithFormat:@"var tmp = '%@'; calculator.vars['%@'] = (calculator.isANumber(tmp) ? eval(tmp) : tmp)", data, [categoryName isEqualToString:@"Units"] ? [NSString stringWithFormat:@"%@.%@", categoryName,  datum.name] : datum.name]];
				NSString *data = [datum.data stringByReplacingOccurrencesOfString:@"\\" withString:@"\\\\"]; // escape escapes
				data = [data stringByReplacingOccurrencesOfString:@"\"" withString:@"\\\""]; // escape double quotes
				[webView stringByEvaluatingJavaScriptFromString:[NSString stringWithFormat:@"var tmp = \"%@\"; calculator.vars['%@'] = (calculator.isANumber(tmp) ? eval(tmp) : tmp)", data, [categoryName isEqualToString:@"Units"] ? [NSString stringWithFormat:@"%@.%@", categoryName,  datum.name] : datum.name]];
///				[webView stringByEvaluatingJavaScriptFromString:[NSString stringWithFormat:@"calculator.vars['%@'] = JSON.parse(\"%@\")", [categoryName isEqualToString:@"Units"] ? [NSString stringWithFormat:@"%@.%@", categoryName,  datum.name] : datum.name, data]];
			}
*/
		}
	
		if ([datum.data hasPrefix:@"\u226a"]) { // an RPL Program
			// build a wrapper function that will call the program through the var we just added
			[webView stringByEvaluatingJavaScriptFromString:[NSString stringWithFormat:@"calculator.RPLProgram.buildFunctionWrapper(\"%@\", \"%@\")", datum.name, categoryName]];
///			NSString *fDefinition = [NSString stringWithFormat:@"function() { calculator.pushArraySilently(arguments); return calculator.functions['@eval'](calculator.vars[\"%@\"][\"%@\"]); }", categoryName, datum.name];
///			[webView stringByEvaluatingJavaScriptFromString:[NSString stringWithFormat:@"calculator.functions[\"%@\"][\"%@\"] = %@", categoryName, datum.name, fDefinition]];
		}
	}
}

- (void)pushEditLine {
	if (inputTextUI.text.length) {
		[webView stringByEvaluatingJavaScriptFromString:[NSString stringWithFormat:@"calculator.push(%@)", [inputTextUI.text JSONFragment]]];
		inputTextUI.text = @"";
	}
}

#pragma mark -
#pragma mark Emailing/reminders

-(void)email:(NSString *)emailBody {
    Class mailClass = (NSClassFromString(@"MFMailComposeViewController"));
    if (mailClass != nil && [mailClass canSendMail]) {		
		MFMailComposeViewController *picker = [[MFMailComposeViewController alloc] init];
		picker.mailComposeDelegate = self;
		
		NSString *subjectName = NSLocalizedString(@"MyStack", nil);
		[picker setSubject:[NSString stringWithFormat:@"[%@] %@ (%@)",
#ifdef IS_ND1
#ifdef IS_ALSO_ND0
							@"ND0",
#else
							@"ND1",
#endif
#else
							@"Calculate",
#endif
							subjectName,
							[[NSDate date] description] ]];
		NSString *emailAddress = [[NSUserDefaults standardUserDefaults] stringForKey:@"email_preference"];
		if (emailAddress && emailAddress.length)
			[picker setToRecipients:[NSArray arrayWithObject:emailAddress]];
		
		// optionally, attach any graph image
		//    NSString *path = [[NSBundle mainBundle] pathForResource:@"rainy" ofType:@"png"];
		//    NSData *myData = [NSData dataWithContentsOfFile:path];
		//    [picker addAttachmentData:myData mimeType:@"image/png" fileName:@"rainy"];
		
///		NSString *emailBody = [NSString stringWithFormat:@"%@ %@.\n", NSLocalizedString(@"StackEmailText", nil), subjectName];
		
		[picker setMessageBody:emailBody isHTML:YES];
		
		[self presentViewController:picker animated:YES completion:nil];
		[picker release];
	}
}

- (void)mailComposeController:(MFMailComposeViewController*)controller didFinishWithResult:(MFMailComposeResult)result error:(NSError*)error {
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (void)showQuickTourReminder {
	NSString *msg = NSLocalizedString(@"PleaseDoQuickTour", nil);
#ifdef IS_ALSO_ND0
	msg = [msg stringByReplacingOccurrencesOfString:@"ND1" withString:@"ND0"];
#endif
	[webView stringByEvaluatingJavaScriptFromString:[NSString stringWithFormat:@"calculator.stack.push('%@'); calculator.show()", msg]];
}

#pragma mark -
#pragma mark Load/save calculator

- (void)loadCalculatorIntoWebView {
	NSString *path = @"calc.html";
	
#ifdef IS_ND1
	if ([[[NSUserDefaults standardUserDefaults] objectForKey:@"hasRunDemo"] boolValue] == NO) {
#ifdef IS_ALSO_ND0
		path = @"Demo_ND0.html";
#else
		path = @"Demo_ND1.html";
#endif
	}
#endif

    path = [[NSBundle mainBundle] pathForResource:path ofType:nil];
	assert(path);
    [webView loadRequest:[NSURLRequest requestWithURL:[NSURL fileURLWithPath:path]]];
}

- (BOOL)isCalculatorInWebView {
///	return [[webView stringByEvaluatingJavaScriptFromString:@"document.location.href.indexOf('calc.html') != -1"] isEqualToString:@"true"];
/// NSLog(@"is calc: %d", ([[[[webView request] URL] absoluteString] rangeOfString:@"calc.html"].length > 0));
	return (![UIApplication sharedApplication].isNetworkActivityIndicatorVisible && [[[[webView request] URL] absoluteString] rangeOfString:@"calc.html"].length > 0);
}

- (void)restoreMenuState {
	// menu, data category
	self.previousMenuTitle = [[NSUserDefaults standardUserDefaults] objectForKey:@"PreviousMenu"];
	NSString *menu = [[NSUserDefaults standardUserDefaults] objectForKey:@"Menu"];
	if (!(menu && menu.length))
		menu = @"User";
	NSString *dataCategory = [[NSUserDefaults standardUserDefaults] objectForKey:@"UserDataCategory"];
	if (!(dataCategory && dataCategory.length))
		[self selectCategory:DEFAULT_VAR_STORE_NAME andShow:NO];
	else {
		if ([menu isEqualToString:@"User"]) {
			currentMenuStartIndex = [[[NSUserDefaults standardUserDefaults] objectForKey:@"MenuStartIndex"] intValue];
			[self selectCategory:dataCategory andShow:YES];
		}
		else {
			[self selectCategory:dataCategory andShow:NO];
			[self installMenu:menu withStartIndex:[[[NSUserDefaults standardUserDefaults] objectForKey:@"MenuStartIndex"] intValue]];
		}
	}
}

- (void)saveCalculatorState {
	/// todo: transfer vars from webview into db
	
	// mode
	NSString *modeSettings = [webView stringByEvaluatingJavaScriptFromString:@"JSON.stringify(calculator.mode)"];
	[[NSUserDefaults standardUserDefaults] setObject:modeSettings forKey:@"Mode"];
	// stack
	///	NSString *flattenedArray = [webView stringByEvaluatingJavaScriptFromString:@"calculator.stack.join('|').replace(/'/g, \"\\\\'\")"];
	NSString *flattenedArray = [webView stringByEvaluatingJavaScriptFromString:@"JSON.stringify(calculator.stack)"];
	[[NSUserDefaults standardUserDefaults] setObject:flattenedArray forKey:@"Stack"];
	// undo stack
	///	flattenedArray = [webView stringByEvaluatingJavaScriptFromString:@"calculator.undo_stack.join('|').replace(/'/g, \"\\\\'\")"];
	flattenedArray = [webView stringByEvaluatingJavaScriptFromString:@"JSON.stringify(calculator.undo_stack)"];
	[[NSUserDefaults standardUserDefaults] setObject:flattenedArray forKey:@"UndoStack"];
	// last args
	///	flattenedArray = [webView stringByEvaluatingJavaScriptFromString:@"calculator.lastArgs.join('|').replace(/'/g, \"\\\\'\")"];
	flattenedArray = [webView stringByEvaluatingJavaScriptFromString:@"JSON.stringify(calculator.lastArgs)"];
	[[NSUserDefaults standardUserDefaults] setObject:flattenedArray forKey:@"LastArgs"];
	// edit line
	[[NSUserDefaults standardUserDefaults] setObject:inputTextUI.text forKey:@"EditLine"];
	// last command
	[[NSUserDefaults standardUserDefaults] setObject:lastPushedEditLine forKey:@"LastCommandLine"];
	// menus
	[[NSUserDefaults standardUserDefaults] setObject:currentMenuTitle forKey:@"Menu"];
	[[NSUserDefaults standardUserDefaults] setObject:previousMenuTitle forKey:@"PreviousMenu"];
	[[NSUserDefaults standardUserDefaults] setObject:[NSNumber numberWithLong:currentMenuStartIndex] forKey:@"MenuStartIndex"];
	[[NSUserDefaults standardUserDefaults] setObject:(userDataCategory ? userDataCategory.name : @"") forKey:@"UserDataCategory"];
	
	[[NSUserDefaults standardUserDefaults] synchronize];
}

#pragma mark -
#pragma mark WebView delegation

- (void)dismissAlert:(UIAlertView *)alert {
	[alert dismissWithClickedButtonIndex:0 animated:YES];
}

// used for generic communication from the webview back into this class and saving of calc state when loading a different URL than calc.html
- (BOOL)webView:(UIWebView *)theWebView shouldStartLoadWithRequest:(NSURLRequest *)request navigationType:(UIWebViewNavigationType)navigationType {
	NSString *requestString = [[[request URL] absoluteString] stringByReplacingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
	NSArray *packed_components = [requestString componentsSeparatedByString:@"::"];
	NSUInteger n_components = [packed_components count];
	
	if (n_components >= 2 && [[packed_components objectAtIndex:0] isEqualToString:@"calc"]) {
		NSMutableArray *components = [NSMutableArray arrayWithCapacity:n_components];
		// unpack components
		for (NSUInteger i=0; i<n_components; i++) {
			NSString *data = [packed_components objectAtIndex:i];
			
			if (data) {
///was:				data = [data stringByReplacingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
/* long ago:
				data = [data stringByReplacingOccurrencesOfString:@"\u0100" withString:@"\\"]; // restate '\'
				data = [data stringByReplacingOccurrencesOfString:@"\u0101" withString:@"\n"]; // restate NLs
				data = [data stringByReplacingOccurrencesOfString:@"\u0102" withString:@"\t"]; // restate TABs
*/
				[components addObject:data];
			}
		}
		
		if (n_components == 5 && [[components objectAtIndex:1] isEqualToString:@"alert"]) {
			if (inputTextUI == (UITextField *)inputTextView && [[components objectAtIndex:3] isEqualToString:@"in line"]) {
				NSInteger line = [[components objectAtIndex:4] intValue];
				if (inputTextView.selectedRange.location > 0) {
					UIAlertView *alert = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"SyntaxError", nil) message:[NSString stringWithFormat:@"%@ %ld", NSLocalizedString(@"SyntaxErrorInLine", nil), (long)line] delegate:nil cancelButtonTitle:nil otherButtonTitles:NSLocalizedString(@"OK", nil), nil];
					[alert show];
					[alert release];
				}//// todo: discover if selected range will display and only prompt dialog if it won't
				/*else*/ { // select given error line in text view
					NSString *text = inputTextView.text;
					NSUInteger length = text.length;
					NSUInteger searchStartLocation = 0;
					NSRange r = NSMakeRange(searchStartLocation, length);
					for (int i=0; i<line; i++) {
						searchStartLocation = r.location;
						r = [text rangeOfString:@"\n" options:NSLiteralSearch range:r];
						r.location += 1;
						r.length = length-r.location;
					}
					r.length = r.location-searchStartLocation;
					r.location = searchStartLocation;
					inputTextView.selectedRange = r;
				}
			}
			else {
				NSString *varArg = [components objectAtIndex:3]; // this var is used to either contain an optional subtitle, or the delay seconds for a timed message
				BOOL isTimedAlert = [[components objectAtIndex:2] isEqualToString:@"TimedMessage"];
				BOOL hasSubTitle = (!isTimedAlert && (varArg && varArg.length > 0));
				UIAlertView *alert = [[UIAlertView alloc] initWithTitle:(isTimedAlert ? @"" : NSLocalizedString([components objectAtIndex:2], nil))
																message:[NSString stringWithFormat:@"%@%@%@",
																		 hasSubTitle ? NSLocalizedString(varArg, nil) : @"",
																		 hasSubTitle ? @": " : @"",
																		 NSLocalizedString([components objectAtIndex:4], nil)]
															   delegate:nil
													  cancelButtonTitle:nil
													  otherButtonTitles:(isTimedAlert ? nil : @"OK"), nil];
				[alert show];
				[alert release];
				if (isTimedAlert) {
					NSTimeInterval delay = [varArg doubleValue];
					if (delay < 1.0)
						delay = 3.0;
					[self performSelector:@selector(dismissAlert:) withObject:alert afterDelay:delay];
				}
			}
		}
		else if (n_components == 4 && [[components objectAtIndex:1] isEqualToString:@"@var_store"])
			[self storeData:[components objectAtIndex:2] forName:[components objectAtIndex:3]];
		else if (n_components == 3 && [[components objectAtIndex:1] isEqualToString:@"@var_delete"])
			[self deleteDataForName:[components objectAtIndex:2]];
		else if (n_components == 4 && [[components objectAtIndex:1] isEqualToString:@"inject"])
			[self injectData:[components objectAtIndex:2] forName:[components objectAtIndex:3]];
		else if (n_components == 3 && [[components objectAtIndex:1] isEqualToString:@"setEditLine"])
			[self setEditLineToText:[components objectAtIndex:2]];
		else if (n_components == 3 && [[components objectAtIndex:1] isEqualToString:@"email"])
			[self email:[[components objectAtIndex:2] stringByReplacingOccurrencesOfString:@"|" withString:@"\\"]];
		/* not used
		 else if (n_components == 2 && [[components objectAtIndex:1] isEqualToString:@"cancelPush"])
		 [NSObject cancelPreviousPerformRequestsWithTarget:self];/// selector:@selector(pushEditLine) object:self];
		 */
		else if (n_components == 2 && [[components objectAtIndex:1] isEqualToString:@"pushCurrentEditLine"])
			[self performSelector:@selector(pushEditLine) withObject:nil afterDelay:0.3];
		else if (n_components == 2 && [[components objectAtIndex:1] isEqualToString:@"resizeWebUI"])
			[self resizeWebUI:NO];
		else if (n_components == 3 && [[components objectAtIndex:1] isEqualToString:@"noteDisplayChange"]) {
			if ([[components objectAtIndex:2] isEqualToString:@"graphics"]) {
				isShowingGraphics = YES;
				UIColor *color = [UIColor darkGrayColor];
				[spaceButton setBackgroundColor:color];
				[spaceButton setTitle:@"✓" forState:UIControlStateNormal];
				[deleteButton setBackgroundColor:color];
				[deleteButton setTitle:@"✓↶" forState:UIControlStateNormal];
				[menuButton setBackgroundColor:color];
				[menuButton setTitle:@"◉" forState:UIControlStateNormal];
			}
			else if ([[components objectAtIndex:2] isEqualToString:@"stack"]) {
				isShowingGraphics = NO;
				UIColor *color = [UIColor clearColor];
				[spaceButton setBackgroundColor:color];
				[spaceButton setTitle:@"␣" forState:UIControlStateNormal];
				[deleteButton setBackgroundColor:color];
				[deleteButton setTitle:@"↶" forState:UIControlStateNormal]; // todo: make this [self updateDeleteUndoButton]; as soon as this function knows to update glyph when coming out of showingGraphics mode
				[menuButton setBackgroundColor:color];
				[menuButton setTitle:@"●" forState:UIControlStateNormal];
			}
		}
		else if (n_components == 3 && [[components objectAtIndex:1] isEqualToString:@"log"])
			NSLog(@"%@", [components objectAtIndex:2]);
		
		[webView stringByEvaluatingJavaScriptFromString:@"calculator.show()"]; // must be done, or we see blank
		
		return NO;
	}

	BOOL aboutToLoadCalculator = ([requestString rangeOfString:@"calc.html"].length > 0);
	if (!aboutToLoadCalculator) {
		if ([self isCalculatorInWebView])
			[self saveCalculatorState];
		[UIApplication sharedApplication].networkActivityIndicatorVisible = YES;
	}
	
	return YES;
}
/*
- (void)webViewDidStartLoad:(UIWebView *)theWebView {
	/// NSLog(@"Started Load of %@...", [[[theWebView request] URL] relativeString]);
	[UIApplication sharedApplication].networkActivityIndicatorVisible = [self isCalculatorInWebView];
}
*/

- (void)alertView:(UIAlertView *)alertView didDismissWithButtonIndex:(NSInteger)buttonIndex {
	// this is only ever called by the alert view launched in -webViewDidFinishLoad
	if (buttonIndex == 0)
		[[NSUserDefaults standardUserDefaults] setObject:[NSNumber numberWithBool:NO] forKey:@"DontTellAboutDoubleTapToReturn_preference"];
}

- (void)webViewDidFinishLoad:(UIWebView *)theWebView {
	// NSLog(@"Finsihed Loading %@", [[[theWebView request] URL] relativeString]);
	[UIApplication sharedApplication].networkActivityIndicatorVisible = NO;

	if (![self isCalculatorInWebView]) {
		if (!webViewIsExpanded) {
			BOOL hasRunDemo = [[[NSUserDefaults standardUserDefaults] objectForKey:@"hasRunDemo"] boolValue];

			// show info dialog
			NSNumber *warnMsg = [[NSUserDefaults standardUserDefaults] objectForKey:@"DontTellAboutDoubleTapToReturn_preference"];
			if (hasRunDemo && !(warnMsg && [warnMsg boolValue] == NO)) {
				UIAlertView *alert = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"SwitchingToFullView", nil) message:NSLocalizedString(@"DoubleTapToComeBack", nil) delegate:self cancelButtonTitle:nil otherButtonTitles:NSLocalizedString(@"DontTellMeAgain", nil), NSLocalizedString(@"OK", nil), nil];
				[alert show];
				[alert release];
			}

			// if we hadn't run the demo before, we just loaded it; so, set the flag to YES
			[[NSUserDefaults standardUserDefaults] setObject:[NSNumber numberWithBool:YES] forKey:@"hasRunDemo"];

			// expand web view
			[self resizeWebUI:YES];
		}
	}
	else { // this is a load of calc.html
		// restore calculator state
		// mode
		NSString *modeSettings = [[NSUserDefaults standardUserDefaults] objectForKey:@"Mode"];
		if (modeSettings && modeSettings.length)
			[webView stringByEvaluatingJavaScriptFromString:[NSString stringWithFormat:@"calculator.mode = JSON.parse('%@')", modeSettings]];

		// potentially overwrite some mode settings here; important when just switching modes; also necessary to prevent .wantsStackDisplay to be stuck at false after close when in graphics mode
		NSString *setModeString = [NSString stringWithFormat:@"calculator.setOperationalMode('%@')", calculator.type.name];
		[theWebView stringByEvaluatingJavaScriptFromString:setModeString];

		// stack
		NSString *flattenedArray = [[NSUserDefaults standardUserDefaults] objectForKey:@"Stack"];
		if (flattenedArray && flattenedArray.length) {
///			[webView stringByEvaluatingJavaScriptFromString:[NSString stringWithFormat:@"calculator.stack = eval('(' + '%@' + ')')", flattenedArray]];
//NSLog(@"stack before: %@", flattenedArray);
//			flattenedArray = [flattenedArray stringByReplacingOccurrencesOfString:@"\\\"" withString:@"\\\\\\\""];
			flattenedArray = [flattenedArray stringByReplacingOccurrencesOfString:@"\\" withString:@"\\\\"]; // escape escapes
			flattenedArray = [flattenedArray stringByReplacingOccurrencesOfString:@"\"" withString:@"\\\""]; // escape double quotes
//NSLog(@"stack after: %@", flattenedArray);
			[webView stringByEvaluatingJavaScriptFromString:[NSString stringWithFormat:@"calculator.stack = JSON.parse(\"%@\")", flattenedArray]];
///			[webView stringByEvaluatingJavaScriptFromString:[NSString stringWithFormat:@"calculator.stack = '%@'.replace(/\\'/g, \"'\").split('|'); calculator.makeNumbersNumberObjects(calculator.stack)", flattenedArray]];
		}
		else if ([[[NSUserDefaults standardUserDefaults] objectForKey:@"firstLaunch_preference"] boolValue]) {
			[webView stringByEvaluatingJavaScriptFromString:@"calculator.stack = [ '\"Hello.\"' ]"];
///			[webView performSelector:@selector(stringByEvaluatingJavaScriptFromString:) withObject:[NSString stringWithFormat:@"calculator.push('\"%@\"')", NSLocalizedString(@"PleaseDoQuickTour", nil)] afterDelay:3.0];
		}
		// undo stack
		flattenedArray = [[NSUserDefaults standardUserDefaults] objectForKey:@"UndoStack"];
		if (flattenedArray && flattenedArray.length) {
			flattenedArray = [flattenedArray stringByReplacingOccurrencesOfString:@"\\" withString:@"\\\\"]; // escape escapes
			flattenedArray = [flattenedArray stringByReplacingOccurrencesOfString:@"\"" withString:@"\\\""]; // escape double quotes
			[webView stringByEvaluatingJavaScriptFromString:[NSString stringWithFormat:@"calculator.undo_stack = JSON.parse(\"%@\")", flattenedArray]];
///			[webView stringByEvaluatingJavaScriptFromString:[NSString stringWithFormat:@"calculator.undo_stack = '%@'.replace(/\\'/g, \"'\").split('|'); calculator.makeNumbersNumberObjects(calculator.undo_stack)", flattenedArray]];
		}
		// last args
		flattenedArray = [[NSUserDefaults standardUserDefaults] objectForKey:@"LastArgs"];
		BOOL hasAStack = (flattenedArray && flattenedArray.length);
		if (hasAStack) {
			flattenedArray = [flattenedArray stringByReplacingOccurrencesOfString:@"\\" withString:@"\\\\"]; // escape escapes
			flattenedArray = [flattenedArray stringByReplacingOccurrencesOfString:@"\"" withString:@"\\\""]; // escape double quotes
			[webView stringByEvaluatingJavaScriptFromString:[NSString stringWithFormat:@"calculator.lastArgs = JSON.parse(\"%@\")", flattenedArray]];
///			[webView stringByEvaluatingJavaScriptFromString:[NSString stringWithFormat:@"calculator.lastArgs = '%@'.replace(/\\'/g, \"'\").split('|'); calculator.makeNumbersNumberObjects(calculator.lastArgs)", flattenedArray]];
		}
		// edit line
		NSString *textLine = [[NSUserDefaults standardUserDefaults] objectForKey:@"EditLine"];
		if (textLine && textLine.length)
			inputTextUI.text = textLine;
		// last command line
		textLine = [[NSUserDefaults standardUserDefaults] objectForKey:@"LastCommandLine"];
		if (textLine && textLine.length)
			self.lastPushedEditLine = textLine;

		// user id
		NSString *clientID = [[NSUserDefaults standardUserDefaults] stringForKey:@"uploadUUID_preference"];
		if ((clientID && ![clientID isEqualToString:@"<auto>"]))
			[webView stringByEvaluatingJavaScriptFromString:[NSString stringWithFormat:@"calculator.vars.userID = '%@'", clientID]];

		[self feedCalcEngineWithUserData];
		
		if (!hasAStack && [[[NSUserDefaults standardUserDefaults] objectForKey:@"firstLaunch_preference"] boolValue])
			[self selectCategory:NSLocalizedString(DEMO_STORE_NAME, nil) andShow:YES];
		else
			[self restoreMenuState];
		
		if (calculator.injection)
			[webView stringByEvaluatingJavaScriptFromString:calculator.injection];

#ifdef IS_ALSO_ND0
		// ND0 three-stack positions maimimg
		if (![[[NSUserDefaults standardUserDefaults] objectForKey:@"firstLaunch_preference"] boolValue]) // if not first launch
			[webView stringByEvaluatingJavaScriptFromString:@"calculator.analytics.shouldDetermineEntropy = true"];
#endif

		{ // set stack alignment
			NSString *alignPreferenceString = [[NSUserDefaults standardUserDefaults] stringForKey:@"align_preference"];
			[webView stringByEvaluatingJavaScriptFromString:[NSString stringWithFormat:@"document.styleSheets[0].cssRules[0].style.textAlign = '%@'", alignPreferenceString]];
			// position dataCategoryLabel according to stack alignment
///			CGRect rect = dataCategoryLabel.frame;
///			rect.origin.x = ([alignPreferenceString isEqualToString:@"right"] ? 30.0f : 233.0f); /// todo: val according to device and orientation
            /// rect.origin.y = 30.0f;
///			dataCategoryLabel.frame = rect;
		}

		// vector display and angle modes
		NSString *vecMode = [webView stringByEvaluatingJavaScriptFromString:@"calculator.mode.angle.vectors"];
		[webView stringByEvaluatingJavaScriptFromString:[NSString stringWithFormat:@"calculator.setVectorDisplayMode('%@')", vecMode]];
		BOOL wantsDegrees = [[webView stringByEvaluatingJavaScriptFromString:@"calculator.mode.angle.inRadians == false"] boolValue];
		[webView stringByEvaluatingJavaScriptFromString:[NSString stringWithFormat:@"calculator.setToRadians(%d)", !wantsDegrees]];

		// .onload
		[webView stringByEvaluatingJavaScriptFromString:@"calculator.onload(); calculator.show()"];

		// sync overlaid UI
		vectorDisplayModeLabel.text = ([vecMode rangeOfString:@"polar"].length ? @"r∠z" : ([vecMode rangeOfString:@"spherical"].length ? @"r∠∠" : @""));
		NSString *angleShowPref = [[NSUserDefaults standardUserDefaults] stringForKey:@"anglemodeshow_preference"];
		angleModeLabel.text = (wantsDegrees && [angleShowPref rangeOfString:@"360"].length ? @"360°" : (!wantsDegrees && [angleShowPref rangeOfString:@"2pi"].length ? @"2π" : @""));
		dataCategoryLabel.text = [webView stringByEvaluatingJavaScriptFromString:@"calculator.currentDataCategory"];
		
		inputTextField.leftView = modeSwitchButton;
		inputTextField.leftViewMode = UITextFieldViewModeAlways;
        isInputTextViewSupersized = NO;
		modeSwitchButton.hidden = false;
		//if ([calculator.type.name isEqualToString:@"Normal"]) // don't make conditional, as localization depends on this
			[self showUIForCurrentInputMode];

		[self updateDeleteUndoButton];
//		if ([calculator.type.name hasPrefix:@"RPN"])
//			[theWebView stringByEvaluatingJavaScriptFromString:@"display.scrollToBottom()"]; //// todo: not working (try delayed execution?)
	}
}

- (id)initWithNibName:(NSString *)nibName bundle:(NSBundle *)nibBundle { /// todo: remove if never called
	if ((self = [super initWithNibName:nibName bundle:nibBundle])) {
		NSString *currentCalculator = [[NSUserDefaults standardUserDefaults] objectForKey:@"CurrentCalculator"];
		if (currentCalculator)
			self.title = [[NSUserDefaults standardUserDefaults] objectForKey:@"CurrentCalculator"];
	}
	
	return self;
}

- (void)viewDidLoad {
	[super viewDidLoad];

	keyLevel = 0;
	softKeys = nil;
	uiObjects = nil;
	uiObjectInfo = nil;
	currentMenuTitle = nil;
	previousMenuTitle = nil;
	currentMenuStartIndex = 0;
	userDataCategory = nil;
	lastPushedEditLine = nil;
	alternateButton = menuButton = deleteButton = calcButton = dropButton = spaceButton = nil;
	inputTextField.hidden = false;
	inputTextView.hidden = true;
	inputTextUI = (UITextField *)inputTextField;
    inputAccessoryView = nil;
	webViewIsExpanded = NO;
	didToggleTabBarOnLastInputViewChange = NO;
	
	// obtain/create ID for keyclick sound
	if (/* DISABLES CODE */ (NO)/*&& [NSBundle instanceMethodForSelector:@selector(URLForResource: :)]*/) {
		 // from Apple SysSound example
		  NSURL *tapSound = [[NSBundle mainBundle] URLForResource:@"tap" withExtension:@"aif"];
		  AudioServicesCreateSystemSoundID((CFURLRef)tapSound, &keyClickSoundID);
	}
	else
		keyClickSoundID = 0x450; // stack overflow
		 /* Mr Marge 
		  NSString *path = [[NSBundle bundleWithIdentifier:@"com.apple.UIKit"] pathForResource:@"Tock" ofType:@"aiff"];
		  AudioServicesCreateSystemSoundID((CFURLRef)[NSURL fileURLWithPath:path], &soundID);
		  */
	// NSLog(@"ID: %d", keyClickSoundID);
	
	NSMutableCharacterSet *mutableNumberFormattingCharacterSet = [[[NSCharacterSet decimalDigitCharacterSet] mutableCopy] autorelease];
	[mutableNumberFormattingCharacterSet addCharactersInString:@".,;Ee()#[]'"];
	numberFormattingCharacterSet = [mutableNumberFormattingCharacterSet copy];

	operatorCharacterSet = [[NSCharacterSet characterSetWithCharactersInString:@"+-/^*"] retain];
	
	// if there's no calculator set, fetch from database according to title
	if (!calculator) {
		self.title = [[NSUserDefaults standardUserDefaults] objectForKey:@"CurrentCalculator"];

		NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] init];
        NSEntityDescription *entity = [NSEntityDescription entityForName:@"Calculator" inManagedObjectContext:managedObjectContext];
		[fetchRequest setEntity:entity];
		[fetchRequest setPredicate:[NSPredicate predicateWithFormat:@"name == %@", self.title]];
		NSError *error = nil;
		NSArray *calculators = [managedObjectContext executeFetchRequest:fetchRequest error:&error];
		[fetchRequest release];

		if (calculators && [calculators count])
			self.calculator = [calculators objectAtIndex:0];
		else
			; // run alert [UIAlertView a
	}
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
	[self becomeFirstResponder];
}

- (void)viewWillDisappear:(BOOL)animated {
	if (webView.isLoading)
		[webView stopLoading];

	if (webViewIsExpanded)
		[self resizeWebUI:NO];

	if ([self isCalculatorInWebView])
		[self saveCalculatorState];
    
    [super viewWillDisappear:animated];
}

// Reduces components of rect to even numbers for sharp rendering
- (CGRect)getSharpRectFromRect:(CGRect)r {
///	return CGRectIntegral(r);
	return CGRectMake(((int)r.origin.x - ((int)r.origin.x & 1)), ((int)r.origin.y - ((int)r.origin.y & 1)), ((int)r.size.width - ((int)r.size.width & 1)), ((int)r.size.height - ((int)r.size.height & 1)));
}

- (void)relayout {	
	// clear previous keys, menus, UI objects
	for (UIView *view in keysView.subviews)
		[view removeFromSuperview];
	for (UIView *view in menusView.subviews)
		[view removeFromSuperview];
	[softKeys release];
	[uiObjects release];
	[uiObjectInfo release];
/* todo: remove; invali context 0 at run-time
	CGContextRef c = UIGraphicsGetCurrentContext();
	CGContextSetShouldSmoothFonts(c, FALSE);
	CGContextSetShouldAntialias(c, FALSE);
	CGContextSetAllowsAntialiasing(c, FALSE);
*/	

/*	((CalculateAppDelegate *)[[UIApplication sharedApplication] delegate]).tabBarController.tabBar.hidden = YES;
	// extend size of keys view, now that tab bar is hidden
	CGRect frame = [keysView frame];
	frame.size.height += 30;
	[keysView setFrame:frame];
*/
	// sort calculator keys into keys instance var
	NSSortDescriptor *sortDescriptor = [[NSSortDescriptor alloc] initWithKey:@"displayOrder" ascending:YES];
	NSArray *sortDescriptors = [[NSArray alloc] initWithObjects:&sortDescriptor count:1];	
	NSMutableArray *keys = [[NSMutableArray alloc] initWithArray:[calculator.keys allObjects]];
	[keys sortUsingDescriptors:sortDescriptors];
	// also sort menus
	NSMutableArray *menus = [NSMutableArray arrayWithArray:[calculator.menus allObjects]];
	[menus sortUsingDescriptors:sortDescriptors];
	[sortDescriptor release];
	[sortDescriptors release];

	softKeys = [[NSMutableArray alloc] init];
	uiObjects = [[NSMutableDictionary alloc] init];
	uiObjectInfo = [[NSMutableDictionary alloc] init];

    // basic color theme

	UITabBar *tabBar = ((CalculateAppDelegate *)[[UIApplication sharedApplication] delegate]).tabBarController.tabBar;

    const BOOL wantsClassicLook = (floor(NSFoundationVersionNumber) <= NSFoundationVersionNumber_iOS_6_1); // is pre-iOS 7 ?
	const BOOL isDarkSkin = [skinName rangeOfString:@"Dark"].length;
    
    if (!wantsClassicLook) {
        keysView.backgroundColor = [skinName isEqualToString:@"Metal"] ? [UIColor colorWithRed:0.784f green:0.795f blue:0.804f alpha:1.0f]
                                 : isDarkSkin ? [UIColor colorWithWhite:0.12 alpha:1.0f]
                                 : [UIColor colorWithRed:0.84f green:0.85f blue:0.87f alpha:1.0f]; // roughly iOS 7 default keyboard background color

        // tab bar tinting
        if (isDarkSkin) {
            tabBar.barTintColor = [UIColor blackColor];
            tabBar.tintColor = [UIColor colorWithWhite:0.12 alpha:1.0f];
            // tabBar.translucent = NO;
            ////((CalculateAppDelegate *)[[UIApplication sharedApplication] delegate]).calculatorListController superview];
        }
        else if ([skinName isEqualToString:@"Metal"]) {
            tabBar.barTintColor = [UIColor colorWithRed:0.784f green:0.795f blue:0.804f alpha:1.0f];
            tabBar.tintColor = [UIColor colorWithWhite:0.12 alpha:1.0f];
        }
        else { // important to reset, in case "Dark" was previously selected
            tabBar.barTintColor = nil;
            tabBar.tintColor = nil;
        }
    }

	// layout and add keys to UI

	const BOOL isInteractiveTool = ([calculator.type.name hasPrefix:@"Web"] || [calculator.type.name isEqualToString:@"Interactive"]);
	inputTextField.hidden = isInteractiveTool;

	const BOOL isLandscape = (self.view.frame.size.width > self.view.frame.size.height);
	const BOOL isPad = (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad);
	const BOOL hasTabBar = (tabBar.alpha > 0.9); // was: !tabBar.hidden;
    const BOOL hasTallScreen = ([[UIScreen mainScreen] bounds].size.height > 480.0f);
    const BOOL wantsTallButtons = (!hasTabBar && hasTallScreen && [calculator.keys count] <= 34);
    

	CGRect keysViewFrame = keysView.frame;
	CGPoint insertPos = CGPointMake(0.0f, isInteractiveTool ? 0.0f : (isLandscape ? 11.0f : 8.0f));

	const CGSize gap = CGSizeMake(8.0f, isInteractiveTool ? 8.0f : (isLandscape ? 2.0f : (isPad ? 15.0f : (isDarkSkin ? 12.0f : (hasTabBar ? 12.0f : 15.0f))))); // important: must be a multiple of 3, or keyviewFrame will be non-integer-sized and font rendering be soft
	const float keyHeight = (isPad ? (isDarkSkin ? 53.0f : 53.0f) : (isLandscape ? 39.0f : (hasTabBar ? 39.0f : (isDarkSkin ? 42.0f : 41.0f)))) + (wantsTallButtons ? 11.0f : 0.0f); // 49 pixels larger, divided by 7 rows

	NSMutableCharacterSet *numbersAndBasicOpsCharacterSet = [[[NSCharacterSet decimalDigitCharacterSet] mutableCopy] autorelease];
	[numbersAndBasicOpsCharacterSet addCharactersInString:@".;,+-*/"];

	NSMutableDictionary *menusOnKeys = [NSMutableDictionary dictionaryWithCapacity:10]; // cache of menus that appear on keys for later use when building menu pop-up

	NSInteger tag = 0;
	NSInteger tagOfSlotSkipper = -1; // used to implement the vertically double-spaced enter key in landscape case
	for (Key *key in keys) {
		NSArray *keyNames = [key.name componentsSeparatedByString:@", "];
		NSString *firstKeyName = [keyNames objectAtIndex:0];

		NSArray *keyFunctions = [key.function componentsSeparatedByString:@", "];
		NSString *firstKeyFunction = [keyFunctions objectAtIndex:0];

		NSInteger buttonSize = 0;
		NSString *buttonSizeString = [self stringInBracketsWithString:firstKeyName];
		if (buttonSizeString) {
			buttonSize = [buttonSizeString integerValue];
			NSRange r = [firstKeyName rangeOfString:@"]"];
			if (r.location+1 < firstKeyName.length-1)
				firstKeyName = [[firstKeyName substringFromIndex:r.location+1] stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
			else
				firstKeyName = @"";
		}
		
		if (firstKeyName && [firstKeyName hasPrefix:@"label"]) {
			CGFloat width = (buttonSize ? keysView.frame.size.width/buttonSize : keysView.frame.size.width);
			CGFloat x = (buttonSize ? insertPos.x : keysView.frame.size.width/4.0f);
			if (buttonSize) {
				// break to next line if element won't fit
				if (insertPos.x+width > keysView.frame.size.width) {
					insertPos.y += keyHeight + gap.height;
					insertPos.x = 0.0f; // todo
				}
				else
					insertPos.x += width;
			}
			else {
				if (insertPos.x != 0.0f) // break to next line if element won't fit
					insertPos.y += keyHeight + gap.height;
				insertPos.x = 0.0f;
			}
			CGRect frame = CGRectMake( x, insertPos.y, width, 30);

			UILabel *label = [[[UILabel alloc] initWithFrame:[self getSharpRectFromRect:frame]] autorelease];
			label.font = [UIFont systemFontOfSize: 18];
			label.textAlignment = NSTextAlignmentCenter;
			label.textColor = (isDarkSkin ? [UIColor lightGrayColor] : [UIColor darkGrayColor]);
			label.backgroundColor = [UIColor clearColor];

			NSString *labelText = [self stringInParenthesesWithString:key.name];
			if (labelText)
				label.text = labelText;

			[keysView addSubview:label];
			insertPos.y += frame.size.height;
		}
		else if (firstKeyName && [firstKeyName hasPrefix:@"pickDate"]) {
			if (!key.function) /// todo: doesn't need a function if webview reacts to .onUIChanged
				continue;
			
			UIDatePicker *datePicker = [[[UIDatePicker alloc] initWithFrame:CGRectZero] autorelease];
			datePicker.autoresizingMask = UIViewAutoresizingFlexibleWidth;
			datePicker.datePickerMode = UIDatePickerModeDate;
			
			[datePicker addTarget:self action:@selector(onDatePick:) forControlEvents:UIControlEventValueChanged];
			[uiObjects setObject:datePicker forKey:firstKeyFunction];
			NSString *dateFormatString = [self stringInParenthesesWithString:key.name];
			[uiObjectInfo setObject:dateFormatString forKey:[NSNumber numberWithInt:(int)datePicker]];
			
			// break to next line if not at beginning
			if (insertPos.x != 0.0f) {
				insertPos.y += keyHeight + gap.height;
				insertPos.x = 0.0f;
			}
			CGRect frame = datePicker.frame;
			frame.origin.x = insertPos.x;
			frame.origin.y = insertPos.y;
			CGSize pickerSize = [datePicker sizeThatFits:CGSizeZero];
			datePicker.frame = CGRectMake(frame.origin.x, frame.origin.y, pickerSize.width, pickerSize.height);
			
			[keysView addSubview:datePicker];
			insertPos.y += frame.size.height + gap.height;
			insertPos.x = 0.0f;
		}
		else if (firstKeyName && [firstKeyName hasPrefix:@"pickTwo"]) {
			if (!key.function)
				continue;
			
			UIPickerView *picker = [[[UIPickerView alloc] initWithFrame:CGRectZero] autorelease];
			picker.autoresizingMask = UIViewAutoresizingFlexibleWidth;
			picker.delegate = self;
			
			[uiObjects setObject:picker forKey:firstKeyFunction];
			NSString *optionString = [self stringInParenthesesWithString:key.name];
			[uiObjectInfo setObject:optionString forKey:[NSNumber numberWithInt:(int)picker]];
			
			// break to next line if element won't fit
			if (insertPos.x != 0.0f) {
				insertPos.y += keyHeight + gap.height;
				insertPos.x = 0.0f;
			}
			CGRect frame = picker.frame;
			frame.origin.x = insertPos.x;
			frame.origin.y = insertPos.y;
			CGSize pickerSize = [picker sizeThatFits:CGSizeZero];
			picker.frame = CGRectMake(frame.origin.x, frame.origin.y, pickerSize.width, pickerSize.height);
			
			[keysView addSubview:picker];
			insertPos.y += frame.size.height + gap.height;
			insertPos.x = 0.0f;
		}
		else if (firstKeyName && [firstKeyName hasPrefix:@"input"]) {
			if (!key.function)
				continue;

			CGFloat width = (buttonSize ? keysView.frame.size.width/buttonSize : keysView.frame.size.width/2.0f);
			CGFloat x = (buttonSize ? insertPos.x : keysView.frame.size.width/4.0f);
			if (buttonSize) {
				// break to next line if element won't fit
				if (insertPos.x+width > keysView.frame.size.width) {
					insertPos.y += keyHeight + gap.height;
					insertPos.x = 0.0f; // todo
				}
				else
					insertPos.x += width;
			}
			else {
				if (insertPos.x != 0.0f) // break to next line if element won't fit
					insertPos.y += keyHeight + gap.height;
				insertPos.x = 0.0f;
			}

			CGRect frame = CGRectMake(x, insertPos.y, width, 31.0f);

			UITextField *textField = [[[UITextField alloc] initWithFrame:[self getSharpRectFromRect:frame]] autorelease];
			textField.placeholder = [self stringInParenthesesWithString:firstKeyName];
			textField.backgroundColor = [UIColor whiteColor];
			textField.borderStyle = UITextBorderStyleBezel;
			
			[uiObjects setObject:textField forKey:firstKeyFunction];
			
			[keysView addSubview:textField];
			insertPos.y += frame.size.height + gap.height;
		}
		else if (firstKeyName && [firstKeyName hasPrefix:@"slider"]) {
			if (!key.function)
				continue;

			CGFloat width = (buttonSize ? keysView.frame.size.width/buttonSize : keysView.frame.size.width/2.0f);
			CGFloat x = (buttonSize ? insertPos.x : keysView.frame.size.width/4.0f);
			if (buttonSize) {
				// break to next line if element won't fit
				if (insertPos.x+width > keysView.frame.size.width) {
					insertPos.y += keyHeight + gap.height;
					insertPos.x = 0.0f; // todo
				}
				else
					insertPos.x += width;
			}
			else {
				if (insertPos.x != 0.0f) // break to next line if element won't fit
					insertPos.y += keyHeight + gap.height;
				insertPos.x = 0.0f;
			}
			
			CGRect frame = CGRectMake(x, insertPos.y, width, 31.0f);
			UISlider *slider = [[[UISlider alloc] initWithFrame:[self getSharpRectFromRect:frame]] autorelease];
			slider.minimumValue = 0.0f;
			slider.maximumValue = 1.0f;
			slider.continuous = YES;

			[slider addTarget:self action:@selector(onSliderChange:) forControlEvents:UIControlEventValueChanged];
			[uiObjects setObject:slider forKey:firstKeyFunction];
			[uiObjectInfo setObject:firstKeyFunction forKey:[NSNumber numberWithInt:(int)slider]];

			[keysView addSubview:slider];
			insertPos.y += frame.size.height + gap.height;
		}
		else if (firstKeyName && [firstKeyName hasPrefix:@"slide"]) {
			NSString *values = [self stringInParenthesesWithString:key.name];
			if (!key.function || !values)
				continue;
			
			SlideButton *button = (SlideButton *)[self buttonWithTitle:[values stringByReplacingOccurrencesOfString:@"," withString:@" "] forSkin:skinName buttonClass:[SlideButton class] isSpecial:NO];
			[button setTitleColor:[UIColor lightGrayColor] forState:UIControlStateNormal]; // only used for initial display
			NSString *placeHolderString = [self stringInParenthesesWithString:key.function];
			if (placeHolderString)
				button.placeholder = placeHolderString;
			button.names = [values componentsSeparatedByString:@","];
			if ([firstKeyFunction hasPrefix:@"@by_name"])
				button.functions = button.names;
			else
				button.functions = [key.function componentsSeparatedByString:@","];

			[button addTarget:self action:@selector(onButtonPress:) forControlEvents:UIControlEventTouchUpInside];
			[uiObjects setObject:button forKey:[self stringInParenthesesWithString:key.name]];

			// break to next line if element won't fit
			if (insertPos.x != 0.0f) {
				insertPos.y += keyHeight + gap.height;
				insertPos.x = 0.0f;
			}
			CGRect frame = CGRectMake(insertPos.x, insertPos.y, keysView.frame.size.width, 31.0f);
			button.frame = frame;
			[keysView addSubview:button];
			insertPos.y += frame.size.height + gap.height;
			insertPos.x = 0.0f;
		}
		else if (firstKeyName && [firstKeyName hasPrefix:@"options"]) {
			if (!key.function)
				continue;
			
			NSString *itemsString = [self stringInParenthesesWithString:key.name];
			if (!itemsString)
				continue;
			
			NSArray *items = [itemsString componentsSeparatedByString:@", "];			
			UISegmentedControl *segmentedControl = [[[UISegmentedControl alloc] initWithItems:items] autorelease];
			if (isDarkSkin)
                segmentedControl.tintColor = [UIColor darkGrayColor];

			[segmentedControl addTarget:self action:@selector(onSegmentChange:) forControlEvents:UIControlEventValueChanged];
			[uiObjects setObject:segmentedControl forKey:firstKeyFunction];
			[uiObjectInfo setObject:firstKeyFunction forKey:[NSNumber numberWithInt:(int)segmentedControl]];

			// break to next line if element won't fit
			if (insertPos.x != 0.0f) {
				insertPos.y += keyHeight + gap.height;
				insertPos.x = 0.0f;
			}
			CGRect frame = segmentedControl.frame;
			frame.origin.x = (insertPos.x != 0.0f ? insertPos.x : (keysView.bounds.size.width - frame.size.width) / 2.0f); // center, if not inset
			frame.origin.y = insertPos.y;
			segmentedControl.frame = CGRectMake(frame.origin.x, frame.origin.y, frame.size.width, frame.size.height);
			[keysView addSubview:segmentedControl];

			insertPos.y += frame.size.height + gap.height;
			insertPos.x = 0.0f;
		}
		else { // a normal "button"
			// compute key name if special case "@calc" and name "@by_function"
			if ([firstKeyName isEqualToString:@"@by_function"] && [firstKeyFunction isEqualToString:@"@calc"])
				firstKeyName = ([calculator.type.name isEqualToString:@"Normal"] ? @"=" : @"enter");

			BOOL isAltKey = [firstKeyFunction isEqualToString:@"@alternate"];

			UIButton *button = [self buttonWithTitle:firstKeyName forSkin:skinName buttonClass:[UIButton class] isSpecial:isAltKey];

			// assign special buttons
			if (isAltKey)
				alternateButton = button;
			else if ([firstKeyFunction isEqualToString:@"@show_menus"])
				menuButton = button;
			else if ([firstKeyFunction isEqualToString:@"@del"])
				deleteButton = button;
			else if ([firstKeyFunction isEqualToString:@"@calc"]) {
				calcButton = button;
				calcButtonString = [button.titleLabel.text retain];
			}
			else if ([firstKeyFunction isEqualToString:@"@drop"] || [firstKeyFunction isEqualToString:@"drop"] || [firstKeyFunction isEqualToString:@"DROP"]) {
				dropButton = button;
				dropButtonString = [button.titleLabel.text retain];
			}
			else if ([firstKeyFunction isEqualToString:@"\" \""])
				spaceButton = button;

			float fontSizeIncrease = (isPad ? (isDarkSkin ? 7.0f : 7.0f) : (hasTabBar ? 0.0f : 1.0f));
            fontSizeIncrease += (wantsTallButtons ? 2.0f : 0.0f);
			if (firstKeyName.length<=2) // number and symbol (in modern mode) keys
				fontSizeIncrease += 2.0f;
			const float softKey_fontSizeIncrease = (isPad ? (isDarkSkin ? 5.0f : 5.0f) : (hasTabBar ? 0.0f : 0.0f));
			const BOOL isSoftKey = [firstKeyFunction isEqualToString:@"@soft"];
			if (isSoftKey || [firstKeyFunction isEqualToString:@"@next_softkeys"]) {
				button.backgroundColor = [[UIColor blueColor] colorWithAlphaComponent:0.2f];
				if (isSoftKey)
					[softKeys addObject:button];
				button.titleLabel.font = [UIFont systemFontOfSize:(isDarkSkin ? 12 : 13) + softKey_fontSizeIncrease];
				button.titleLabel.adjustsFontSizeToFitWidth = YES;
				button.titleLabel.minimumFontSize = ((isSoftKey || firstKeyName.length>1) ? 10 : 16/*next arrow*/) + softKey_fontSizeIncrease;
			}
			else { // styling of normal keys
				button.titleLabel.font = ((firstKeyName.length == 1 && [firstKeyName characterAtIndex:0] < 255) ? [UIFont boldSystemFontOfSize:(isDarkSkin ? 16 : 18) + fontSizeIncrease] : [UIFont systemFontOfSize:(isDarkSkin ? 14 : 16) + fontSizeIncrease]);
				button.titleLabel.adjustsFontSizeToFitWidth = YES;
				button.titleLabel.minimumFontSize = 7 + fontSizeIncrease;
			}

			// record the menus on menu function keys for later use when building menu pop-up
			if ([firstKeyFunction hasPrefix:@"@menu:"])
				[menusOnKeys setObject:[NSNumber numberWithBool:YES] forKey:[firstKeyFunction substringFromIndex:6]];
			if ([keyFunctions count] == 2 && [[keyFunctions objectAtIndex:1] hasPrefix:@"@menu:"])
				[menusOnKeys setObject:[NSNumber numberWithBool:YES] forKey:[[keyFunctions objectAtIndex:1] substringFromIndex:6]];
			
			if (isLandscape)
				button.contentVerticalAlignment = UIControlContentVerticalAlignmentTop; // we really assume a small gap here and realize packing the 2nd level function into the key

			NSRange letterRange = [firstKeyFunction rangeOfCharacterFromSet:numbersAndBasicOpsCharacterSet];
			BOOL isNumberOrBasicFunctionKey = (letterRange.length != 0);
			BOOL hasOnlyFewKeys = ([keys count] <= 10);
			BOOL isCalcKey = [firstKeyFunction isEqualToString:@"@calc"];
			
			const float nButtonsPerRow = buttonSize ? buttonSize :
										(isLandscape? (hasOnlyFewKeys ? 1 : (isNumberOrBasicFunctionKey ? 10 : (isCalcKey ? 10 : 10)))
													: (hasOnlyFewKeys ? 1 : (isNumberOrBasicFunctionKey ? 5 : (isCalcKey ? 3 : 6))));
			
			[button addTarget:self action:@selector(onButtonPress:) forControlEvents:UIControlEventTouchUpInside];
			[button addTarget:self action:@selector(onButtonTouchDown:) forControlEvents:UIControlEventTouchDown];

			CGRect frame = button.frame;
			frame.size.width = (keysView.frame.size.width - (isSoftKey ? 0.0f : gap.width*(nButtonsPerRow-1))) / nButtonsPerRow;
			if (isLandscape && isCalcKey) {
				frame.size.height = (2.0f * keyHeight - gap.height); // vertically double-spaced
				tagOfSlotSkipper = tag + nButtonsPerRow; // skip this position on the next row
				button.titleLabel.numberOfLines = [[keyNames objectAtIndex:0] length]; // use as many lines as needed to write word, one letter per line
				button.titleLabel.lineBreakMode = NSLineBreakByCharWrapping; // wrapping at character boundaries
				button.titleLabel.adjustsFontSizeToFitWidth = NO; // without dynamic size
				button.titleLabel.font = [UIFont systemFontOfSize:14]; // but rather a fixed size that will spread "ENTER" nicely over five lines and two rows
				button.titleLabel.baselineAdjustment = YES;
			}
			else
				frame.size.height = (keyHeight - gap.height);
			// advance to next row if button won't fit
			if ((insertPos.x + frame.size.width) > (keysViewFrame.size.width + 0.01f/* - frame.size.width*/)) {
				insertPos.x = 0.0f;
				insertPos.y += frame.size.height + gap.height;
			}
			frame.origin.x = insertPos.x;
			frame.origin.y = insertPos.y;
			button.frame = [self getSharpRectFromRect:frame];

			[button setTitle:key.function forState:UIControlStateApplication];
			button.tag = tag++;

			[keysView addSubview:button];
			
			if ([keyNames count] > 1) { // there's an alternate keyname
//				CGRect labelFrame = frame;
				frame.size.height -= 6.0f;
//              if (isPad)
//                  frame.origin.x = insertPos.x + 35.0f;
				if (isLandscape)
					frame.origin.y = insertPos.y + (isCalcKey ? 34.0f : 14.0f);
				else
					frame.origin.y = insertPos.y - (16.0f + (2.0f*fontSizeIncrease/3.0f)) + (isPad ? /*24.0f*/-4.0f : 0.0f) + (hasTabBar ? 2.0f : 1.0f) + (wantsTallButtons ? -3.0f : 0.0f);
				UILabel *label = [[[UILabel alloc] initWithFrame:[self getSharpRectFromRect:frame]] autorelease];
				label.text = [keyNames objectAtIndex:1];
				label.textAlignment = NSTextAlignmentCenter;
				label.textColor = isLandscape ? (isDarkSkin ? [UIColor colorWithRed:0.3f green:0.5f blue:0.7f alpha:1.0f]
                                                            : [UIColor whiteColor])
                                              : (isDarkSkin ? (wantsClassicLook ? [UIColor lightGrayColor] : [UIColor colorWithWhite:0.57f alpha:1.0f])
                                                            : (wantsClassicLook ? [UIColor lightGrayColor] : [UIColor colorWithWhite:0.39f alpha:1.0f]) );
				label.font = [UIFont systemFontOfSize:(isPad ? 17 : (isLandscape ? 10 : 12) + (2.0f*fontSizeIncrease/3.0f) + (hasTabBar ? -1.0f : -1.0f))];
				label.adjustsFontSizeToFitWidth = YES;
				label.backgroundColor = [UIColor colorWithWhite:0.0f alpha:0.0f];
				[keysView addSubview:label];
			}

			if ([keyNames count] > 2) { // there's an alternate2 key name
				if (isLandscape)
					frame.origin.y -= (isCalcKey ? 76.0f : 33.0f);
				else
					frame.origin.y += 32.0f;
				frame.size.height += 2.0f;
				UILabel *label = [[[UILabel alloc] initWithFrame:[self getSharpRectFromRect:frame]] autorelease];
				label.text = [keyNames objectAtIndex:2];
				label.textAlignment = NSTextAlignmentCenter;
				label.textColor = (isDarkSkin ? (wantsClassicLook ? [UIColor colorWithRed:0.8f green:0.6f blue:0.5f alpha:1.0f] : [UIColor colorWithWhite:1.0f alpha:1.0f])
                                              : [UIColor darkGrayColor]);
				label.font = [UIFont systemFontOfSize:(isPad ? 16 : 12)];
				label.adjustsFontSizeToFitWidth = YES;
				label.backgroundColor = [UIColor colorWithWhite:0.0f alpha:0.0f];
				[keysView addSubview:label];
			}
						
///		NSLog(@"Key: %@ (%@); basic: %d; (%f, %f) - (%f, %f)", [keyNames objectAtIndex:0], [keyNames count] > 1 ? [keyNames objectAtIndex:1] : @"n/a", isNumberOrBasicFunctionKey, frame.origin.x, frame.origin.y, frame.size.width, frame.size.height);

			// update insert position
			insertPos.x += frame.size.width + (isSoftKey ? 0.0f : gap.width);
/*
 // update insert position; go to next line when required
			if ((insertPos.x += frame.size.width + (isSoftKey ? 0.0f : gap.width)) > (keysViewFrame.size.width - frame.size.width)) {
				insertPos.x = 0.0f;
				insertPos.y += frame.size.height + gap.height;
			}
*/			
			if (tag == tagOfSlotSkipper)
				insertPos.x += frame.size.width + (isSoftKey ? 0.0f : gap.width);
		}
	}

	// resize and reposition web, key and input text (if not hidden) views to make optimal use of available height
	keysViewFrame.size.height = insertPos.y + 40.0f - gap.height/3.0f;
	if (insertPos.x == 0.0f)
		keysViewFrame.size.height -= 40.0f;
    // NSLog(@"layout: keysView y: %f h: %f; view y: %f, h: %f", keysViewFrame.origin.x, keysViewFrame.size.height, self.view.frame.origin.x, self.view.frame.size.height);
	CGRect webViewFrame = webView.frame;
	webViewFrame.size.height = self.view.frame.size.height - keysViewFrame.size.height - (inputTextField.hidden ? 0 : inputTextField.frame.size.height);
	if (inputTextField.hidden) 
		keysViewFrame.origin.y = webViewFrame.size.height;
	else {
		// adjust input text field
		CGRect frame = inputTextField.frame;
		frame.origin.y = webViewFrame.size.height;
		inputTextField.frame = frame;
		// adjust input text view
		inputTextView.frame = CGRectMake(0.0f, 0.0f, self.view.frame.size.width, webViewFrame.size.height + frame.size.height);
		// and, finally, start position of keys view
		keysViewFrame.origin.y = webViewFrame.size.height + inputTextField.frame.size.height;
	}
	webView.frame = webViewFrame;
	keysView.frame = keysViewFrame;

	if ([menus count]) {
		// the following is somehow required to make view appear; todo: find out why
		[menusView removeFromSuperview];
		[self.view addSubview:menusView];
	
		CGRect menusViewFrame = menusView.frame;

		const float indent = 10.0f;
		CGPoint insertPos = CGPointMake(indent, indent*2.0f);
		NSInteger tag = 0;
		for (Menu *menu in menus) {
			// find out if menu is already on a key; if so, don't add to pop-up
			if ([menusOnKeys objectForKey:menu.title])
				continue;

			BOOL isCASMenu = [menu.title hasPrefix:@"CAS:"];
            if (isCASMenu)
                continue;
			
			BOOL isSoftKeyNotMenu = [menu.title isEqualToString:@"@key"];
			UIButton *button = [self buttonWithTitle:(isSoftKeyNotMenu ? menu.name : menu.title) forSkin:@"Light"];
			button.titleLabel.font = [UIFont boldSystemFontOfSize:15];

			if (isSoftKeyNotMenu) {
				[button setTitle:menu.function forState:UIControlStateApplication];
				[button addTarget:self action:@selector(onButtonPress:) forControlEvents:UIControlEventTouchUpInside];
			}
			else
				[button addTarget:self action:@selector(installMenuFromButton:) forControlEvents:UIControlEventTouchUpInside];

			const float nButtonsPerRow = 3;
			CGRect frame = button.frame;
			frame.origin.x = insertPos.x;
			frame.origin.y = insertPos.y;
			frame.size.width = ((menusViewFrame.size.width - indent*2.0f) - (gap.width*(nButtonsPerRow-1))) / nButtonsPerRow;
			frame.size.height = (keyHeight - gap.height);
			button.frame = frame;
			
			button.tag = tag++;
			
			[menusView addSubview:button];

			// update insert position; go to next line when required
			if ((insertPos.x += frame.size.width + gap.width) > (menusViewFrame.size.width - frame.size.width)) {
				insertPos.x = indent;
				insertPos.y += frame.size.height + gap.height;
			}
		}

		menusViewFrame.size.height = insertPos.y + 40.0f /* std button height */;
		// decrement height by a row if we're at the beginning of a new row (which has no buttons yet)
		if (insertPos.x == indent)
			menusViewFrame.size.height -= 40.0f;
        menusViewFrame.origin.y = inputTextField.frame.origin.y - menusViewFrame.size.height + inputTextField.frame.size.height/4.0f; // anchor menu above the input text field, eating into it a bit
		menusView.frame = menusViewFrame;
	}

	[self updateDeleteUndoButton];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];

	[self loadCalculatorIntoWebView];

	// find skin in effect
	skinName = calculator.skin.name;
	if ([skinName isEqualToString:@"Default"])
		skinName = [[NSUserDefaults standardUserDefaults] stringForKey:@"skin_preference"];

	deleteButtonIsShowingUndo = NO; // todo: really?
	calcButtonIsShowingEnter = YES;
	isShowingGraphics = NO;
	[self relayout];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
	if ([calculator.orientation.name isEqualToString:@"Portrait"])
		return (interfaceOrientation == UIInterfaceOrientationPortrait);
	else if ([calculator.orientation.name isEqualToString:@"Landscape"])
		return (interfaceOrientation == UIDeviceOrientationLandscapeRight || interfaceOrientation == UIDeviceOrientationLandscapeLeft);

	return (interfaceOrientation != UIInterfaceOrientationPortraitUpsideDown);
}

- (void)didReceiveMemoryWarning {
	// Releases the view if it doesn't have a superview.
	[super didReceiveMemoryWarning];

	// Release any cached data, images, etc that aren't in use.
}

- (void)viewDidUnload {
// NSLog(@"viewDidUnload");
	webView = nil;
	keysView = nil;
	menusView = nil;
	softKeys = nil;
	uiObjects = nil;
	uiObjectInfo = nil;
	inputTextView = nil;
	inputTextField = nil;
    [super viewDidUnload];
}

- (void)toggleTextViewHeight {
	const int EXTRA_HEIGHT_ADDITION = 86;

	assert(inputTextUI == (UITextField *)inputTextView);
	
	CGRect frame = inputTextView.frame;
	frame.size.height += (isInputTextViewSupersized ? -1 : 1) * EXTRA_HEIGHT_ADDITION;
    isInputTextViewSupersized = !isInputTextViewSupersized;
		
	[UIView beginAnimations:nil context:NULL];
	[UIView setAnimationDuration:0.3];
	inputTextView.frame = frame;
	[UIView commitAnimations];
}

- (void)morphInputUI {
	UITextField *theOtherUI = (inputTextUI == inputTextField ? (UITextField *)inputTextView : inputTextField);
	CGRect saveFrame = theOtherUI.frame;
	theOtherUI.frame = inputTextUI.frame; // want to start animation with current UI's frame
	theOtherUI.text = inputTextUI.text; // copy over any text; //// todo: somehow preserve NLs and TABs
	inputTextUI.hidden = true;
	[inputTextUI resignFirstResponder];
	inputTextUI = theOtherUI;
	inputTextUI.hidden = false;
	[inputTextUI becomeFirstResponder];
	
	[UIView beginAnimations:nil context:NULL];
	[UIView setAnimationDuration:0.3];
	inputTextUI.frame = saveFrame;
	[UIView commitAnimations];

	// make sure tab bar/keys show appropriately
	if (inputTextUI == inputTextField) {
		// toggle tab bar back to large if was large before last change
		if (didToggleTabBarOnLastInputViewChange) {
			[self toggleTabBar];
			didToggleTabBarOnLastInputViewChange = YES;
		}
	}
	else { // input is text view
		// make sure to show tab bar (and thereby move Enter button into visible location
		UITabBar *tabBar = ((CalculateAppDelegate *)[[UIApplication sharedApplication] delegate]).tabBarController.tabBar;
		const BOOL hasTabBar = (tabBar.alpha > 0.9); // was: !tabBar.hidden;
		if (!hasTabBar) {
			[self toggleTabBar];
			didToggleTabBarOnLastInputViewChange = YES;
		}
		else
			didToggleTabBarOnLastInputViewChange = NO;
	}
    
    // update undo button; will show delete button while text view is active
    [self updateDeleteUndoButton];
}

- (void)resizeWebUI:(BOOL)animated {
	static BOOL isExpanded = NO;

	isExpanded = !isExpanded;
	webViewIsExpanded = isExpanded;

	if (animated) {
		[UIView beginAnimations:nil context:NULL];
		[UIView setAnimationDuration:0.3];
	}
	webView.frame = CGRectMake( webView.frame.origin.x,
                                webView.frame.origin.y,
							    webView.frame.size.width,
                  isExpanded  ? self.view.frame.size.height
                              : (self.view.frame.size.height - keysView.frame.size.height - (inputTextField.hidden ? 0 : inputTextField.frame.size.height))
    );
	if (isExpanded) {
		[self.view bringSubviewToFront:webView];
		displaySwitchButton.hidden = false;
		[self.view bringSubviewToFront:displaySwitchButton];
		webView.alpha = 1.0f;
	}
	else {
		[self.view sendSubviewToBack:webView];
		displaySwitchButton.hidden = true;
		[webView stringByEvaluatingJavaScriptFromString:@"display.isShowingGraphics ? window.onresize() : display.scrollToBottom()"];
		webView.alpha = 1.0f;

		if (![self isCalculatorInWebView])
			[self loadCalculatorIntoWebView];
	}

	if (animated)
		[UIView commitAnimations];
}

- (void)showUIForCurrentInputMode {
	BOOL isInAlgebraicMode = [calculator.type.name isEqualToString:@"Normal"];
	[inputTextField setBackgroundColor:(!isInAlgebraicMode ? [UIColor colorWithRed:163.0f/255.0f green:189.0f/255.0f blue:240.0f/255.0f alpha:1.0f]
										: [UIColor colorWithRed:171.0f/255.0f green:219.0f/255.0f blue:190.0f/255.0f alpha:1.0f])];
	[modeSwitchButton setTitle:NSLocalizedString(!isInAlgebraicMode ? NSLocalizedString(@"rpn:", nil) : NSLocalizedString(@"alg:", nil), nil) forState:UIControlStateNormal];

	if (isInAlgebraicMode) {
		deleteButtonIsShowingUndo = calcButtonIsShowingEnter = true; // set these to force updates in next call
		[self updateDeleteUndoButton];
	}
	else {
		[dropButton setTitle:dropButtonString forState:UIControlStateNormal];
		[calcButton setTitle:calcButtonString forState:UIControlStateNormal];
	}
}

- (IBAction)toggleInputMode:(id)sender {
	BOOL isInAlgebraicMode = [calculator.type.name isEqualToString:@"Normal"];
	calculator.type.name = (isInAlgebraicMode ? @"RPN" : @"Normal");

	// save the managed object context
	NSError *error = nil;
	if (![calculator.managedObjectContext save:&error]) {
		// todo: better action
		NSArray* detailedErrors = [[error userInfo] objectForKey:NSDetailedErrorsKey];
		if (detailedErrors != nil && [detailedErrors count] > 0) {
			for(NSError* detailedError in detailedErrors) {
				NSLog(@"  DetailedError: %@", [detailedError userInfo]);
			}
		}
		else
			NSLog(@"Unresolved error %@, %@", error, [error userInfo]);
	}

	[self showUIForCurrentInputMode];
}

- (BOOL)textFieldShouldReturn:(UITextField *)textField {
	[textField resignFirstResponder];
	return YES;
}

//- (BOOL)textFieldShouldBeginEditing:(UITextView *)textView {
//	return NO;
//}

- (BOOL)textViewShouldEndEditing:(UITextView *)textView {
	[textView resignFirstResponder];
	return YES;
}
/*
- (void)textViewDidEndEditing:(UITextView *)textView {
	[textView resignFirstResponder];
	[self performSelector:@selector(morphInputUI) withObject:nil afterDelay:1.0];
}
*/

- (void)textFieldDidBeginEditing:(UITextField *)textField {
	// todo: reset insert position
    
    if (false) { // todo: enable, when ready
        if (!inputAccessoryView) {
            inputAccessoryView = [[UIView alloc] initWithFrame:CGRectMake(0.0, 0.0, 50.0, 40.0)];
            [inputAccessoryView setBackgroundColor:[UIColor colorWithRed:0.56f green:0.59f blue:0.64f alpha:1.0f]];
/**/
            UIButton *enterButton = [UIButton buttonWithType:UIButtonTypeCustom];
            [enterButton setFrame:CGRectMake(5.0f, 0.0f, 40.0f, 30.0f)]; // todo: blue background (and white font)?
            [enterButton setTitle:@"⇧" forState:UIControlStateNormal];
            [enterButton setTitle:@"@calc" forState:UIControlStateApplication];
            [enterButton setTitleColor:[UIColor colorWithWhite:0.0 alpha:1.0] forState:UIControlStateNormal];
            [enterButton setBackgroundColor:[UIColor colorWithWhite:0.9f alpha:1.0f]];
            [enterButton addTarget:self action:@selector(onButtonPress:) forControlEvents:UIControlEventTouchUpInside];
/**/
///			UIButton *enterButton = [self buttonWithTitle:@"⇧" forSkin:skinName];

            [inputAccessoryView addSubview:enterButton];
        }
        
        [textField setInputAccessoryView:inputAccessoryView];
/**/            [inputAccessoryView setAlpha:0.0f];
    }
}

- (void)textFieldDidEndEditing:(UITextField *)textField {
}

- (BOOL)textFieldShouldClear:(UITextField *)textField {
	if (textField == inputTextField)
		[self performSelector:@selector(updateDeleteUndoButton) withObject:nil afterDelay:0];
	return YES;
}


- (BOOL)textField:(UITextField *)textField shouldChangeCharactersInRange:(NSRange)range replacementString:(NSString *)string {
	// todo: take note of range.location+range.length and use as insert position

	if (textField == inputTextField)
		[self performSelector:@selector(updateDeleteUndoButton) withObject:nil afterDelay:0];

	return YES;
}

- (BOOL)canBecomeFirstResponder {
	return YES;
} /**/

- (void)showTabBar:(NSNumber *)alphaVal {
	[NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(showTabBar:) object:[NSNumber numberWithBool:NO]];

	[UIView beginAnimations:nil context:NULL];
	[UIView setAnimationDuration:0.3];
	
	float alpha = [alphaVal floatValue];

	UITabBar *tabBar = ((CalculateAppDelegate *)[[UIApplication sharedApplication] delegate]).tabBarController.tabBar;
	tabBar.alpha = alpha;

    CGRect screen = [[UIScreen mainScreen] bounds];
	tabBar.frame = CGRectMake(tabBar.frame.origin.x, screen.size.height - (alpha == 0.0f ? 0.0f : 49.0f), tabBar.frame.size.width, tabBar.frame.size.height);

	// if some alpha (but not full), schedule setting to zero ("hide")
	if (alpha > 0.0f && alpha < 1.0f)
		[self performSelector:@selector(showTabBar:) withObject:[NSNumber numberWithBool:NO] afterDelay:10.0];
	
	[UIView commitAnimations];
}

- (void)toggleTabBar {
	UITabBar *tabBar = ((CalculateAppDelegate *)[[UIApplication sharedApplication] delegate]).tabBarController.tabBar;
	BOOL b = (tabBar.alpha < 0.9);
	[self showTabBar:[NSNumber numberWithBool:b]]; /// was: tabBar.hidden = !tabBar.hidden;
	
	// resize our UITransitionView (our view's superview) to reflect visibility of tab bar
	// (as per http://www.iphonedevsdk.com/forum/iphone-sdk-development/4091-uitabbarcontroller-hidden-uitabbar.html )
    // on iOS 7 we resize our own view (discovered)
	UITabBarController *tabBarController = ((CalculateAppDelegate *)[[UIApplication sharedApplication] delegate]).tabBarController;

    UIView *contentView = (floor(NSFoundationVersionNumber) <= NSFoundationVersionNumber_iOS_6_1 // is <= iOS 6?
                            ? [tabBarController.view.subviews objectAtIndex:0]
                            : self.view);
    if (!b)
        contentView.frame = tabBarController.view.bounds;
    else
        contentView.frame = CGRectMake(tabBarController.view.bounds.origin.x,
                                       tabBarController.view.bounds.origin.y,
                                       tabBarController.view.bounds.size.width,
                                       tabBarController.view.bounds.size.height - tabBarController.tabBar.frame.size.height);

	// NSLog(@"Tab bar: %d; view y: %f, h: %f; keysView y: %f, h: %f ", !tabBar.hidden, self.view.frame.origin.y, self.view.frame.size.height, keysView.frame.origin.y, keysView.frame.size.height);

	//// todo: remove; tmp measure to side-step "graphics not displaying after UI toggle" bug
	if (!b)
		[webView stringByEvaluatingJavaScriptFromString:@"display.showGraphics(false); calculator.show()"];

	[self saveCalculatorState];
	[self relayout];
	[self restoreMenuState];

///	[self updateDeleteUndoButton];

	[webView stringByEvaluatingJavaScriptFromString:@"display.isShowingGraphics ? window.onresize() : display.scrollToBottom()"];
}

/* Shake to resize support.
// Shake toggles tab bar
- (void)motionEnded:(UIEventSubtype)motion withEvent:(UIEvent *)event {
    if (motion == UIEventSubtypeMotionShake )
		[self toggleTabBar];
}
- (void)motionCancelled:(UIEventSubtype)motion withEvent:(UIEvent *)event {
}
*/

- (BOOL)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event in:(id)sender {
	if ([[touches anyObject] tapCount] == 2) {
		[NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(pushEditLine) object:nil];
		if ([sender class] == [TouchNotifyingWebView class])
			[self resizeWebUI:YES];
		else {
			if (inputTextUI == (UITextField *)inputTextView)
				[self toggleTextViewHeight];
			else
				[self morphInputUI];
		}
		return YES;
	}

	return NO;
}

///- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event {
///	[super touchesBegan:touches withEvent:event];
/*
	if ([touches count] == 3) {
		UITabBar *tabBar = ((CalculateAppDelegate *)[[UIApplication sharedApplication] delegate]).tabBarController.tabBar;
		tabBar.hidden = !tabBar.hidden;
	}
*/
/* don't want this, because of accidental invocation: two touches happen when pressing keys fast; two touches almost impossible place between keys
	else if ([touches count] == 2)
		[self showMenus:[NSNumber numberWithBool:YES]];
	else {
		if ([[touches anyObject] tapCount] == 2)
			[self showMenus:[NSNumber numberWithBool:YES]];
	}
*/
///}

- (void)dealloc {
// NSLog(@"dealloc");
	[softKeys release];
	[uiObjects release];
	[uiObjectInfo release];
	self.currentMenuTitle = nil;
	self.previousMenuTitle = nil;
	self.lastPushedEditLine = nil;
	[numberFormattingCharacterSet release];
	[webView release];
    if (inputAccessoryView)
        [inputAccessoryView release];
	if (calcButtonString)
		[calcButtonString release];
	if (dropButtonString)
		[dropButtonString release];
	
	AudioServicesDisposeSystemSoundID(keyClickSoundID);
		 
	[super dealloc];
}


@end


@implementation TouchNotifyingTextField

- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event {
	// NSLog(@"TouchNotifyingTextField; touchesBegan!");
	if ([self.delegate respondsToSelector:@selector(touchesBegan: withEvent: in:)])
		 if ([(id <TouchesNotificationReceiving>)self.delegate touchesBegan:touches withEvent:event in:self])
			 return;
	[super touchesBegan:touches withEvent:event];
}

@end

@implementation TouchNotifyingTextView

- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event {
	// NSLog(@"TouchNotifyingTextView; touchesBegan!");
	if ([self.delegate respondsToSelector:@selector(touchesBegan: withEvent: in:)])
		if ([(id <TouchesNotificationReceiving>)self.delegate touchesBegan:touches withEvent:event in:self])
			return;
	[super touchesBegan:touches withEvent:event];
}

@end

@implementation TouchNotifyingWebView

/* FUTURE: A better overall solution for double-tap detection and forwarding to delegate may be using
gestureRecognizer:shouldRecognizeSimultaneouslyWithGestureRecognizer
http://stackoverflow.com/questions/2909807/does-uigesturerecognizer-work-on-a-uiwebview
http://stackoverflow.com/questions/2627934/simultaneous-gesture-recognizers-in-iphone-sdk
https://devforums.apple.com/message/315688#315688
*/

/* no longer necessary on iOS 7, as resizeMySelf is called in hitTest
   but still required on iOS 6, where the iOS 7 code will trigger resizes on drags
   FUTURE: fix */
- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event {
	// NSLog(@"TouchNotifyingWebView; touchesBegan!");
	if ([self.delegate respondsToSelector:@selector(touchesBegan: withEvent: in:)])
		if ([(id <TouchesNotificationReceiving>)self.delegate touchesBegan:touches withEvent:event in:self])
			return;
	[super touchesBegan:touches withEvent:event];
}

- (void)resizeMySelf {
    [(JS_CalcViewController *)[self delegate] resizeWebUI:YES];
}

-(UIView *)hitTest:(CGPoint)point withEvent:(UIEvent *)event {
    BOOL isiOS6 = (floor(NSFoundationVersionNumber) <= NSFoundationVersionNumber_iOS_6_1); // is pre-iOS 7 ?
    
	BOOL wantsEvent = NO;

	if (event.type == UIEventTypeTouches) { // only intercept touch events
		// NSLog(@"hitTest on myself: %d, count: %d; point: (%f, %f)", [super hitTest:point withEvent:event] == self, [[event allTouches] count], point.x, point.y);
        static CGPoint lastEvent_point;/// = { -1, -1 };

        if (isiOS6) {
            // iOS 6 version
            static NSTimeInterval lastEvent_timestamp = -1.0;
            BOOL isSingleTouch = CGPointEqualToPoint(point, lastEvent_point);
            if ((event.timestamp - lastEvent_timestamp) < 0.25 && isSingleTouch) { // if double-tap
                // NSLog(@"hitTest; detected double-tap!");
                wantsEvent = YES;
            }
            lastEvent_timestamp = event.timestamp;
        }
        else {
            // iOS 7 version
            BOOL isSingleTouch = (sqrt((point.x-lastEvent_point.x)*(point.x-lastEvent_point.x) + (point.y-lastEvent_point.y)*(point.y-lastEvent_point.y)) < 3.0f);
            if (isSingleTouch) {
                static NSTimeInterval lastEvent_timestamp = -1.0;

                NSTimeInterval timestamp = event.timestamp;
                NSTimeInterval timeBetweenTouches = timestamp - lastEvent_timestamp;

                if (timeBetweenTouches > 0.02 && timeBetweenTouches < 0.25) { // if double-tap
                    // NSLog(@"hitTest; detected double-tap! (time between taps: %.2fs)", timestamp - lastEvent_timestamp);
                    [self performSelector:@selector(resizeMySelf) withObject:nil afterDelay:0.0];
                    wantsEvent = YES;
                }

                lastEvent_timestamp = timestamp;
            }
        }

        lastEvent_point = point;
	}

	return (wantsEvent ? (isiOS6 ? self : [self superview]) : [super hitTest:point withEvent:event]);
}

@end
