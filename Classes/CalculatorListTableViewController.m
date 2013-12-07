
/*
     File: CalculatorListTableViewController.m
 Abstract: Table view controller to manage an editable table view that displays a list of calculators.
 Calculators are displayed in a custom table view cell.
 
  Version: 1.0
  
 */

#import "CalculatorListTableViewController.h"
#import "CalculatorDetailViewController.h"
#import "Calculator.h"
#import "CalculatorTableViewCell.h"

#import "DataDownloadsTableViewController.h"

#import "CalculateAppDelegate.h" // for its calcViewController
#import "JS_CalcViewController.h" // for its .calculator


@implementation CalculatorListTableViewController


@synthesize managedObjectContext, fetchedResultsController;


#pragma mark -
#pragma mark UIViewController overrides

- (void)viewDidLoad {
    [super viewDidLoad];

    // Configure the navigation bar
    self.title = NSLocalizedString(@"Calculators", nil);

    self.navigationItem.leftBarButtonItem = self.editButtonItem;
    
    UIBarButtonItem *addButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemAdd target:self action:@selector(add:)];
    self.navigationItem.rightBarButtonItem = addButtonItem;
    [addButtonItem release];
    
    // TODO: tint UIBar
    //// self.tabBarController.tabBar.barTintColor = [UIColor blackColor];
    
    // Set the table view's row height
    self.tableView.rowHeight = 44.0;
	
	NSError *error = nil;
	if (![[self fetchedResultsController] performFetch:&error]) {
		// todo: better action
		NSLog(@"Unresolved error %@, %@", error, [error userInfo]);
		abort();
	}
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
    // Support all orientations except upside down
    return (interfaceOrientation != UIInterfaceOrientationPortraitUpsideDown);
}


#pragma mark -
#pragma mark Calculator support

- (void)add:(id)sender {
     // add a new calculator: create a CalculatorAddViewController; present it as a modal view so that the user's focus is on the task of adding the calculator; wrap the controller in a navigation controller to provide a navigation bar for the Done and Save buttons (added by the CalculatorAddViewController in its viewDidLoad method).
    CalculatorAddViewController *addController = [[CalculatorAddViewController alloc] initWithNibName:@"CalculatorAddView" bundle:nil];
    addController.delegate = self;

	Calculator *newCalculator = [NSEntityDescription insertNewObjectForEntityForName:@"Calculator" inManagedObjectContext:self.managedObjectContext];
	addController.calculator = newCalculator;

    UINavigationController *navigationController = [[UINavigationController alloc] initWithRootViewController:addController];
    [self presentViewController:navigationController animated:YES completion:nil];

    [navigationController release];
    [addController release];
}


- (void)calculatorAddViewController:(CalculatorAddViewController *)calculatorAddViewController didAddCalculator:(Calculator *)calculator {
    if (calculator) {        
        // Show the calculator in a new view controller
        [self showCalculator:calculator animated:NO];
    }
    
    // Dismiss the modal add calculator view controller
    [self dismissViewControllerAnimated:YES completion:nil];
}


- (void)showCalculator:(Calculator *)calculator animated:(BOOL)animated {
    // Create a detail view controller, set the calculator, then push it.
    CalculatorDetailViewController *detailViewController = [[CalculatorDetailViewController alloc] initWithStyle:UITableViewStyleGrouped];
    detailViewController.calculator = calculator;

	// set entry in Calculator tab
	((CalculateAppDelegate *)[[UIApplication sharedApplication] delegate]).calcViewController.calculator = calculator;
	((CalculateAppDelegate *)[[UIApplication sharedApplication] delegate]).calcViewController.title = NSLocalizedString(calculator.name, nil);
	[[NSUserDefaults standardUserDefaults] setObject:calculator.name forKey:@"CurrentCalculator"];
	[[NSUserDefaults standardUserDefaults] synchronize];
	
    [self.navigationController pushViewController:detailViewController animated:animated];
	if (!animated) // set to edit mode if we're just coming from a fresh Calculator add (which happens to call us with animated:NO)
		; // todo: solve this somehow
		///[detailViewController setEditing:YES animated:NO];
		///[detailViewController.navigationItem.rightBarButtonItem performSelector:@selector(performClick:) withObject:nil afterDelay:0.0];
    [detailViewController release];
}


#pragma mark -
#pragma mark Table view methods

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    NSInteger count = [[fetchedResultsController sections] count];
    
	if (count == 0) {
		count = 1;
	}

	++count; // downloadables

    return count;
}


- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    NSInteger numberOfRows = 0;
	
	if (section == [self numberOfSectionsInTableView:tableView]-1) { // last row
		return 1; // "Downloadables" button
	}
    else if ([[fetchedResultsController sections] count] > 0) {
        id <NSFetchedResultsSectionInfo> sectionInfo = [[fetchedResultsController sections] objectAtIndex:section];
        numberOfRows = [sectionInfo numberOfObjects];
    }
    
    return numberOfRows;
}


- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
	if ([indexPath section] == 0) {
		// Dequeue or if necessary create a CalculatorTableViewCell, then set its calculator to the calculator for the current row.
		static NSString *CalculatorCellIdentifier = @"CalculatorCellIdentifier";
		
		CalculatorTableViewCell *calculatorCell = (CalculatorTableViewCell *)[tableView dequeueReusableCellWithIdentifier:CalculatorCellIdentifier];
		if (calculatorCell == nil) {
			calculatorCell = [[[CalculatorTableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CalculatorCellIdentifier] autorelease];
			calculatorCell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
		}
		
		[self configureCell:calculatorCell atIndexPath:indexPath];
		
		return calculatorCell;
	}
	else {
		static NSString *CalculatorDownloadCellIdentifier = @"CalculatorDownloadCellIdentifier";
		
		CalculatorTableViewCell *downloadableCategoryCell = (CalculatorTableViewCell *)[tableView dequeueReusableCellWithIdentifier:CalculatorDownloadCellIdentifier];
		if (downloadableCategoryCell == nil) {
			downloadableCategoryCell = [[[CalculatorTableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:CalculatorDownloadCellIdentifier] autorelease];
			downloadableCategoryCell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
			downloadableCategoryCell.indentationLevel = 4;
		}
		
		[self configureCell:downloadableCategoryCell atIndexPath:indexPath];
		
		return downloadableCategoryCell;
	}
}


- (void)configureCell:(CalculatorTableViewCell *)cell atIndexPath:(NSIndexPath *)indexPath {
	if ([indexPath section] == 0) {
		Calculator *calculator = (Calculator *)[fetchedResultsController objectAtIndexPath:indexPath];
		cell.calculator = calculator;
	}
	else {
		cell.textLabel.text = NSLocalizedString(@"SharedCalculators", nil);
	}
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
	if (section == 0)
		return nil;
	else
		return NSLocalizedString(@"Downloadables", nil);
}

- (UITableViewCellEditingStyle)tableView:(UITableView *)tableView editingStyleForRowAtIndexPath:(NSIndexPath *)indexPath {
	if ([indexPath section] == 0)
		return UITableViewCellEditingStyleDelete;
	else
		return UITableViewCellEditingStyleNone;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
	if ([indexPath section] == 0) {
		Calculator *calculator = (Calculator *)[fetchedResultsController objectAtIndexPath:indexPath];
		[self showCalculator:calculator animated:YES];
	}
	else {
		DataDownloadsTableViewController *downloadsViewController = [[DataDownloadsTableViewController alloc] initWithStyle:UITableViewStylePlain];
		downloadsViewController.managedObjectContext = managedObjectContext;
        downloadsViewController.doesManageUserData = NO;
		[self.navigationController pushViewController:downloadsViewController animated:YES];
		[downloadsViewController release];
	}
}


// Override to support editing the table view.
- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath {
    if (editingStyle == UITableViewCellEditingStyleDelete) {
        // Delete the managed object for the given index path
		NSManagedObjectContext *context = [fetchedResultsController managedObjectContext];
		[context deleteObject:[fetchedResultsController objectAtIndexPath:indexPath]];
		
		// Save the context.
		NSError *error;
		if (![context save:&error]) {
			// todo: better action
			NSLog(@"Unresolved error %@, %@", error, [error userInfo]);
			abort();
		}
	}
}


#pragma mark -
#pragma mark Fetched results controller

- (NSFetchedResultsController *)fetchedResultsController {
    if (fetchedResultsController == nil) {
        NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] init];

		// only show new definitions
		[fetchRequest setPredicate:[NSPredicate predicateWithFormat:@"uploadDate != NULL"]];

        NSEntityDescription *entity = [NSEntityDescription entityForName:@"Calculator" inManagedObjectContext:managedObjectContext];
        [fetchRequest setEntity:entity];
        
        // sort by name
        NSSortDescriptor *sortDescriptor = [[NSSortDescriptor alloc] initWithKey:@"name" ascending:YES];
        NSArray *sortDescriptors = [[NSArray alloc] initWithObjects:sortDescriptor, nil];
        [fetchRequest setSortDescriptors:sortDescriptors];
        
        // Edit the section name key path and cache name if appropriate.
        // nil for section name key path means "no sections".
        NSFetchedResultsController *aFetchedResultsController = [[NSFetchedResultsController alloc] initWithFetchRequest:fetchRequest managedObjectContext:managedObjectContext sectionNameKeyPath:nil cacheName:@"Root"];
        aFetchedResultsController.delegate = self;
        self.fetchedResultsController = aFetchedResultsController;
        
        [aFetchedResultsController release];
        [fetchRequest release];
        [sortDescriptor release];
        [sortDescriptors release];
    }
	
	return fetchedResultsController;
}    


/**
 Delegate methods of NSFetchedResultsController to respond to additions, removals and so on.
 */

- (void)controllerWillChangeContent:(NSFetchedResultsController *)controller {
	// The fetch controller is about to start sending change notifications, so prepare the table view for updates.
	[self.tableView beginUpdates];
}


- (void)controller:(NSFetchedResultsController *)controller didChangeObject:(id)anObject atIndexPath:(NSIndexPath *)indexPath forChangeType:(NSFetchedResultsChangeType)type newIndexPath:(NSIndexPath *)newIndexPath {
	UITableView *tableView = self.tableView;
	
	switch(type) {
		case NSFetchedResultsChangeInsert:
			[tableView insertRowsAtIndexPaths:[NSArray arrayWithObject:newIndexPath] withRowAnimation:UITableViewRowAnimationFade];
			break;
			
		case NSFetchedResultsChangeDelete:
			[tableView deleteRowsAtIndexPaths:[NSArray arrayWithObject:indexPath] withRowAnimation:UITableViewRowAnimationFade];
			break;
			
		case NSFetchedResultsChangeUpdate:
			[self configureCell:(CalculatorTableViewCell *)[tableView cellForRowAtIndexPath:indexPath] atIndexPath:indexPath];
			break;
			
		case NSFetchedResultsChangeMove:
			[tableView deleteRowsAtIndexPaths:[NSArray arrayWithObject:indexPath] withRowAnimation:UITableViewRowAnimationFade];
			[tableView insertRowsAtIndexPaths:[NSArray arrayWithObject:newIndexPath] withRowAnimation:UITableViewRowAnimationFade];
			break;
	}
}


- (void)controller:(NSFetchedResultsController *)controller didChangeSection:(id <NSFetchedResultsSectionInfo>)sectionInfo atIndex:(NSUInteger)sectionIndex forChangeType:(NSFetchedResultsChangeType)type {
	switch(type) {
		case NSFetchedResultsChangeInsert:
			[self.tableView insertSections:[NSIndexSet indexSetWithIndex:sectionIndex] withRowAnimation:UITableViewRowAnimationFade];
			break;
			
		case NSFetchedResultsChangeDelete:
			[self.tableView deleteSections:[NSIndexSet indexSetWithIndex:sectionIndex] withRowAnimation:UITableViewRowAnimationFade];
			break;
	}
}


- (void)controllerDidChangeContent:(NSFetchedResultsController *)controller {
	// The fetch controller has sent all current change notifications, so tell the table view to process all updates.
	[self.tableView endUpdates];
}



#pragma mark -
#pragma mark Memory management

- (void)dealloc {
	[fetchedResultsController release];
	[managedObjectContext release];
    [super dealloc];
}

@end
