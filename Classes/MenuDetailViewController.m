
/*
     File: MenuDetailViewController.m
 Abstract: Table view controller to manage editing details of a calculator menu -- its title, name and function.
 
  Version: 1.0
 
 */

#import "MenuDetailViewController.h"
#import "Calculator.h"
#import "Menu.h"
#import "EditingTableViewCell.h"


@implementation MenuDetailViewController

@synthesize calculator, menu, editingTableViewCell;

#pragma mark -
#pragma mark View controller

- (id)initWithStyle:(UITableViewStyle)style {
    if (self = [super initWithStyle:style]) {
        UINavigationItem *navigationItem = self.navigationItem;
        navigationItem.title = NSLocalizedString(@"Menu", nil);

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
    return 3;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    static NSString *MenusCellIdentifier = @"MenusCell";
    
    EditingTableViewCell *cell = (EditingTableViewCell *)[tableView dequeueReusableCellWithIdentifier:MenusCellIdentifier];
    if (cell == nil) {
		[[NSBundle mainBundle] loadNibNamed:@"EditingTableViewCell" owner:self options:nil];
        cell = editingTableViewCell;
		self.editingTableViewCell = nil;
    }
    
	if (indexPath.row == 0) {
        cell.label.text = NSLocalizedString(@"Menu", nil);
        cell.textField.text = menu.title;
        cell.textField.placeholder = NSLocalizedString(@"Title", nil);
    }
    else if (indexPath.row == 1) {
        cell.label.text = NSLocalizedString(@"Soft Keys", nil);
        cell.textField.text = menu.name;
        cell.textField.placeholder = NSLocalizedString(@"Names", nil);
    }
	else if (indexPath.row == 2) {
        cell.label.text = NSLocalizedString(@"Functions", nil);
        cell.textField.text = menu.function;
        cell.textField.placeholder = NSLocalizedString(@"Functions", nil);
    }
	
    return cell;
}

#pragma mark -
#pragma mark Save and cancel

- (void)save:(id)sender {
	NSManagedObjectContext *context = [calculator managedObjectContext];
	
	/*
	 If there isn't an menu object, create and configure one.
	 */
    if (!menu) {
        self.menu = [NSEntityDescription insertNewObjectForEntityForName:@"Menu" inManagedObjectContext:context];
		menu.displayOrder = [NSNumber numberWithInteger:[calculator.menus count]];
        [calculator addMenusObject:menu];
    }
	
	/*
	 Update the menu from the values in the text fields.
	 */
    EditingTableViewCell *cell;
	
    cell = (EditingTableViewCell *)[self.tableView cellForRowAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:0]];
    menu.title = [cell.textField.text stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
	
    cell = (EditingTableViewCell *)[self.tableView cellForRowAtIndexPath:[NSIndexPath indexPathForRow:1 inSection:0]];
    menu.name = [cell.textField.text stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
	
    cell = (EditingTableViewCell *)[self.tableView cellForRowAtIndexPath:[NSIndexPath indexPathForRow:2 inSection:0]];
    menu.function = [cell.textField.text stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
	
	// save the managed object context
	NSError *error = nil;
	if (![context save:&error]) {
		// todo: better action
		NSLog(@"Unresolved error %@, %@", error, [error userInfo]);
		NSLog(@"Menu title: %@, name: %@, function: %@, displayOrder: %@", menu.title, menu.name, menu.function, menu.displayOrder);
		abort();
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
    [menu release];
    [super dealloc];
}

@end
