
/*
     File: KeyDetailViewController.m
 Abstract: Table view controller to manage editing details of a calculator key -- its name and function.
 
  Version: 1.0
 
 */

#import "KeyDetailViewController.h"
#import "Calculator.h"
#import "Key.h"
#import "EditingTableViewCell.h"


@implementation KeyDetailViewController

@synthesize calculator, key, editingTableViewCell;


#pragma mark -
#pragma mark View controller

- (id)initWithStyle:(UITableViewStyle)style {
    if (self = [super initWithStyle:style]) {
        UINavigationItem *navigationItem = self.navigationItem;
        navigationItem.title = NSLocalizedString(@"Key", nil);

        UIBarButtonItem *cancelButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemCancel target:self action:@selector(cancel:)];
        self.navigationItem.leftBarButtonItem = cancelButton;
        [cancelButton release];

        UIBarButtonItem *saveButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemSave target:self action:@selector(save:)];
        self.navigationItem.rightBarButtonItem = saveButton;
        [saveButton release];
    }
    return self;
}

- (void)viewDidLoad {
	[super viewDidLoad];	
	self.tableView.allowsSelection = NO;
	self.tableView.allowsSelectionDuringEditing = NO;
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
    return (interfaceOrientation != UIInterfaceOrientationPortraitUpsideDown);
}

#pragma mark -
#pragma mark Table view

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return 2;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    static NSString *KeysCellIdentifier = @"KeysCell";
    
    EditingTableViewCell *cell = (EditingTableViewCell *)[tableView dequeueReusableCellWithIdentifier:KeysCellIdentifier];
    if (cell == nil) {
		[[NSBundle mainBundle] loadNibNamed:@"EditingTableViewCell" owner:self options:nil];
        cell = editingTableViewCell;
		self.editingTableViewCell = nil;
    }
    
    if (indexPath.row == 0) {
        cell.label.text = NSLocalizedString(@"Key", nil);
        cell.textField.text = key.name;
        cell.textField.placeholder = NSLocalizedString(@"Name", nil);
    }
	else if (indexPath.row == 1) {
        cell.label.text = NSLocalizedString(@"Function", nil);
        cell.textField.text = key.function;
        cell.textField.placeholder = NSLocalizedString(@"Function", nil);
    }

    return cell;
}

#pragma mark -
#pragma mark Save and cancel

- (void)save:(id)sender {
	NSManagedObjectContext *context = [calculator managedObjectContext];
	
	/*
	 If there isn't a key object, create and configure one.
	 */
    if (!key) {
        self.key = [NSEntityDescription insertNewObjectForEntityForName:@"Key" inManagedObjectContext:context];
        [calculator addKeysObject:key];
		key.displayOrder = [NSNumber numberWithInteger:[calculator.keys count]];
    }

	/*
	 Update the key from the values in the text fields.
	 */
    EditingTableViewCell *cell;

    cell = (EditingTableViewCell *)[self.tableView cellForRowAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:0]];
    key.name = [cell.textField.text stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];

    cell = (EditingTableViewCell *)[self.tableView cellForRowAtIndexPath:[NSIndexPath indexPathForRow:1 inSection:0]];
    key.function = [cell.textField.text stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];

	// save the managed object context
	NSError *error = nil;
	if (![context save:&error]) {
		// todo: better action
		NSArray* detailedErrors = [[error userInfo] objectForKey:NSDetailedErrorsKey];
		if(detailedErrors != nil && [detailedErrors count] > 0) {
			for(NSError* detailedError in detailedErrors) {
				NSLog(@"  DetailedError: %@", [detailedError userInfo]);
			}
		}
		else
			NSLog(@"Unresolved error %@, %@", error, [error userInfo]);
		
///		abort();
	}

    [self.navigationController popViewControllerAnimated:YES];
}


- (void)cancel:(id)sender {
    [self.navigationController popViewControllerAnimated:YES];
}

#pragma mark -
#pragma mark Memory management

- (void)dealloc {
    [calculator release];
    [key release];
    [super dealloc];
}

@end
