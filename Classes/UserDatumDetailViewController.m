
/*
     File: UserDatumDetailViewController.m
 Abstract: Table view controller to manage editing details of a user datum -- its name and data.
 
  Version: 1.0
 
 */

#import "UserDatumDetailViewController.h"
#import "UserDataCategory.h"
#import "UserDatum.h"
#import "EditingTableViewCell.h"


@implementation UserDatumDetailViewController

@synthesize userDataCategory, datum, editingTableViewCell;

#define MAX_DISPLAY_DATA_LENGTH 1000
#define EXCEEDED_DISPLAY_DATA_LENGTH 25

#pragma mark -
#pragma mark View controller


- (id)initWithStyle:(UITableViewStyle)style {
    if (self = [super initWithStyle:style]) {
        UINavigationItem *navigationItem = self.navigationItem;
        navigationItem.title = NSLocalizedString(@"Entry", nil);

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
    static NSString *UserDatumsCellIdentifier = @"UserDatumsCell";
    
    EditingTableViewCell *cell = (EditingTableViewCell *)[tableView dequeueReusableCellWithIdentifier:UserDatumsCellIdentifier];
    if (cell == nil) {
		[[NSBundle mainBundle] loadNibNamed:@"EditingTableViewCell" owner:self options:nil];
        cell = editingTableViewCell;
		self.editingTableViewCell = nil;
    }
    
    if (indexPath.row == 0) {
        cell.label.text = NSLocalizedString(@"Name", nil);
        cell.textField.text = NSLocalizedString(datum.name, nil);
        cell.textField.placeholder = NSLocalizedString(@"NamePlaceholder", nil);
    }
	else if (indexPath.row == 1) {
        cell.label.text = NSLocalizedString(@"Definition", nil);
		BOOL isLargeData = (datum.data.length > MAX_DISPLAY_DATA_LENGTH);
        cell.textField.text = (isLargeData ? [NSString stringWithFormat:@"%@... (%.2f KiB)", [datum.data substringToIndex:EXCEEDED_DISPLAY_DATA_LENGTH], (float)datum.data.length/1024.0f] : datum.data);
		cell.textField.enabled = !isLargeData;
		cell.textField.textColor = (!isLargeData ? [UIColor labelColor] : [UIColor secondaryLabelColor]);
        cell.textField.placeholder = NSLocalizedString(@"DefinitionPlaceholder", nil);
    }
	else if (indexPath.row == 2) {
        cell.label.text = NSLocalizedString(@"Comment", nil);
        cell.textField.text = NSLocalizedString(datum.comment, nil);
        cell.textField.placeholder = NSLocalizedString(@"CommentPlaceholder", nil);
    }
	
    return cell;
}


#pragma mark -
#pragma mark Save and cancel

- (void)save:(id)sender {
	NSManagedObjectContext *context = [userDataCategory managedObjectContext];
	
	/*
	 If there isn't an datum object, create and configure one.
	 */
    if (!datum) {
        self.datum = [NSEntityDescription insertNewObjectForEntityForName:@"UserDatum" inManagedObjectContext:context];
		datum.displayOrder = [NSNumber numberWithInteger:[userDataCategory.data count]];
        [userDataCategory addDataObject:datum];
    }
	
	/*
	 Update the datum from the values in the text fields.
	 */
    EditingTableViewCell *cell;
	
    cell = (EditingTableViewCell *)[self.tableView cellForRowAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:0]];
    datum.name = cell.textField.text;
	
    cell = (EditingTableViewCell *)[self.tableView cellForRowAtIndexPath:[NSIndexPath indexPathForRow:1 inSection:0]];
    datum.data = cell.textField.text;
	
    cell = (EditingTableViewCell *)[self.tableView cellForRowAtIndexPath:[NSIndexPath indexPathForRow:2 inSection:0]];
    datum.comment = cell.textField.text;
	
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
    [userDataCategory release];
    [datum release];
    [super dealloc];
}

@end
