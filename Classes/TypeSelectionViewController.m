
/*
     File: TypeSelectionViewController.m
 Abstract: Table view controller to allow the user to select the calculator type.
 The options are presented as items in the table view; the selected item has a check mark in the accessory view. The controller caches the index path of the selected item to avoid the need to perform repeated string comparisons after an update.
 
  Version: 1.0

 */

#import "TypeSelectionViewController.h"
#import "Calculator.h"


@interface TypeSelectionViewController()
@property (nonatomic, retain) NSArray *calculatorTypes;
@end


@implementation TypeSelectionViewController

@synthesize calculator;
@synthesize typeString;
@synthesize calculatorTypes;

#pragma mark -
#pragma mark UIViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
	// Fetch the calculator types in alphabetical order by name from the calculator's context.
	NSManagedObjectContext *context = [calculator managedObjectContext];
	
	NSError *error = nil;
	NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] init];

	[fetchRequest setEntity:[NSEntityDescription entityForName:typeString inManagedObjectContext:context]];
	self.calculatorTypes = [context executeFetchRequest:fetchRequest error:&error];

	[fetchRequest release];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
    return (interfaceOrientation != UIInterfaceOrientationPortraitUpsideDown);
}

#pragma mark -
#pragma mark UITableView Delegate/Datasource

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return [calculatorTypes count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    static NSString *MyIdentifier = @"MyIdentifier";
    
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:MyIdentifier];
    if (cell == nil)
        cell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:MyIdentifier] autorelease];
    
    // Configure the cell
	NSManagedObject *calculatorType = [calculatorTypes objectAtIndex:indexPath.row];
    cell.textLabel.text = NSLocalizedString([calculatorType valueForKey:@"name"], nil);
    
	if ([cell.textLabel.text isEqualToString:NSLocalizedString([[calculator valueForKey:typeString] valueForKey:@"name"], nil)])
        cell.accessoryType = UITableViewCellAccessoryCheckmark;
    
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    // If there was a previous selection, unset the accessory view for its cell.
	NSManagedObject *currentType = [calculator valueForKey:typeString];
    if (currentType != nil) {
		NSInteger index = [calculatorTypes indexOfObject:currentType];
		NSIndexPath *selectionIndexPath = [NSIndexPath indexPathForRow:index inSection:0];
        UITableViewCell *checkedCell = [tableView cellForRowAtIndexPath:selectionIndexPath];
        checkedCell.accessoryType = UITableViewCellAccessoryNone;
    }

    // Set the checkmark accessory for the selected row.
    [[tableView cellForRowAtIndexPath:indexPath] setAccessoryType:UITableViewCellAccessoryCheckmark];    
     // Update the type of the calculator instance
    [calculator setValue:[calculatorTypes objectAtIndex:indexPath.row] forKey:typeString];

    // if applicable, show tip for custom skin
	if ([[[calculatorTypes objectAtIndex:indexPath.row] name] isEqualToString:@"Custom"] && [[[NSUserDefaults standardUserDefaults] objectForKey:@"tips_preference"] boolValue]) {
		UIAlertView *alert = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"CustomSkinTips", nil) message:NSLocalizedString(@"CustomSkinTip", nil) delegate:self cancelButtonTitle:nil otherButtonTitles:NSLocalizedString(@"GotIt", nil), nil];
		[alert show];
		[alert release];
	}

    // Deselect the row.
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
}

- (void)dealloc {
    [calculator release];
    [calculatorTypes release];
    [super dealloc];
}

@end
