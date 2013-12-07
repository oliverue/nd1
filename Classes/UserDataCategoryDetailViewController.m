
/*
     File: UserDataCategoryDetailViewController.m
 Abstract: Table view controller to manage an editable table view that displays information about a user data category.
 The table view uses different cell types for different row types.
 
  Version: 1.0
  
 */

#import "UserDataCategoryDetailViewController.h"

#import "UserDataCategory.h"
#import "UserDatum.h"

#import "NotesViewController.h"
#import "UserDatumDetailViewController.h"
#import "DataSharingController.h"


@implementation UserDataCategoryDetailViewController

@synthesize userDataCategory;
@synthesize data;

@synthesize tableHeaderView;
@synthesize nameTextField, overviewTextField, nEntriesLabel, nEntriesTextLabel;

#define MAX_DISPLAY_DATA_LENGTH 1000
#define EXCEEDED_DISPLAY_DATA_LENGTH 25

#define DATA_SECTION 0
#define NOTES_SECTION 1
#define SHARING_SECTION 2


#pragma mark -
#pragma mark View controller

- (void)viewDidLoad {
    [super viewDidLoad];

    self.navigationItem.rightBarButtonItem = self.editButtonItem;
    
    // Create and set the table header view.
    if (tableHeaderView == nil) {
        [[NSBundle mainBundle] loadNibNamed:@"UserDataCategoryDetailHeaderView" owner:self options:nil];
        self.tableView.tableHeaderView = tableHeaderView;
        self.tableView.allowsSelectionDuringEditing = YES;
		nEntriesTextLabel.text = NSLocalizedString(@"nEntriesText", nil);
    }
}


- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
	
	self.navigationItem.title = NSLocalizedString(userDataCategory.name, nil);
    nameTextField.text = NSLocalizedString(userDataCategory.name, nil);
    overviewTextField.text = NSLocalizedString(userDataCategory.overview, nil);
	overviewTextField.placeholder = NSLocalizedString(@"OverviewPlaceholder", nil);

	/*
	 Create mutable arrays that contain the userDataCategory's data ordered by displayOrder.
	 The table view uses this array to display these.
	 */
	NSSortDescriptor *sortDescriptor = [[NSSortDescriptor alloc] initWithKey:@"displayOrder" ascending:YES];
	NSArray *sortDescriptors = [[NSArray alloc] initWithObjects:&sortDescriptor count:1];
	
	NSMutableArray *sortedUserData = [[NSMutableArray alloc] initWithArray:[userDataCategory.data allObjects]];
	[sortedUserData sortUsingDescriptors:sortDescriptors];
	self.data = sortedUserData;

	[sortDescriptor release];
	[sortDescriptors release];
	[sortedUserData release];

	// figure # of entries
	self.nEntriesLabel.text = [NSString stringWithFormat:@"%lu", (unsigned long)[self.data count]];

    [self.tableView reloadData]; 
}


- (void)viewDidUnload {
    self.tableHeaderView = nil;
	self.nameTextField = nil;
	self.overviewTextField = nil;
	self.nEntriesLabel = nil;
	[super viewDidUnload];
}


- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
    return (interfaceOrientation != UIInterfaceOrientationPortraitUpsideDown);
}


#pragma mark -
#pragma mark Editing

- (void)setEditing:(BOOL)editing animated:(BOOL)animated {
    [super setEditing:editing animated:animated];
    
	nameTextField.enabled = editing;
	overviewTextField.enabled = editing;
	[self.navigationItem setHidesBackButton:editing animated:YES];

	[self.tableView beginUpdates];
	
    NSUInteger dataCount = [userDataCategory.data count];
    NSArray *dataInsertIndexPath = [NSArray arrayWithObject:[NSIndexPath indexPathForRow:dataCount inSection:DATA_SECTION]];
    if (editing) {
        [self.tableView insertRowsAtIndexPaths:dataInsertIndexPath withRowAnimation:UITableViewRowAnimationTop];
		overviewTextField.placeholder = NSLocalizedString(@"OverviewPlaceholder", nil);
	} else {
        [self.tableView deleteRowsAtIndexPaths:dataInsertIndexPath withRowAnimation:UITableViewRowAnimationTop];
		overviewTextField.placeholder = @"";
    }
    
    [self.tableView endUpdates];
	
	// when editing is finished, save the managed object context
	if (!editing) {
		NSManagedObjectContext *context = userDataCategory.managedObjectContext;
		NSError *error = nil;
		if (![context save:&error]) {
			// todo: better action
			NSLog(@"Unresolved error %@, %@", error, [error userInfo]);
			abort();
		}
	}
}


- (BOOL)textFieldShouldEndEditing:(UITextField *)textField {
	if (textField == nameTextField) {
		userDataCategory.name = nameTextField.text;
		self.navigationItem.title = userDataCategory.name;
	}
	else if (textField == overviewTextField) {
		userDataCategory.overview = overviewTextField.text;
	}
	return YES;
}


- (BOOL)textFieldShouldReturn:(UITextField *)textField {
	[textField resignFirstResponder];
	return YES;
}


#pragma mark -
#pragma mark UITableView Delegate/Datasource

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 3;
}


- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
    NSString *title = nil;
    switch (section) {
        case DATA_SECTION:
            title = NSLocalizedString(@"Entries", nil);
            break;
        default:
            break;
    }
    return title;
}


- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    NSInteger rows = 0;
    
    // the number of rows depends on the section.
	// in the case of data, if editing, add a row in editing mode to present the "Add ..." cell.
    switch (section) {
		case SHARING_SECTION:
        case NOTES_SECTION:
            rows = 1;
            break;
        case DATA_SECTION:
            rows = [userDataCategory.data count];
            if (self.editing)
                rows++;
            break;
		default:
            break;
    }
    return rows;
}


- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = nil;
    
    if (indexPath.section == DATA_SECTION) {
		NSUInteger datumCount = [userDataCategory.data count];
        NSInteger row = indexPath.row;
		
        if (indexPath.row < datumCount) {
            // If the row is within the range of the number of data for the current userDataCategory, then configure the cell to show the datum name and amount.
			static NSString *UserDataCellIdentifier = @"UserDataCell";
			
			cell = [tableView dequeueReusableCellWithIdentifier:UserDataCellIdentifier];
			
			if (cell == nil) {
				 // Create a cell to display an datum.
				cell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:UserDataCellIdentifier] autorelease];
				cell.accessoryType = UITableViewCellAccessoryNone;
			}
			
            UserDatum *datum = [data objectAtIndex:row];
			if (datum.comment && [datum.comment length] > 0 && [datum.comment length] < 17)
				cell.textLabel.text = [NSString stringWithFormat:@"%@ (%@)", NSLocalizedString(datum.name, nil), NSLocalizedString(datum.comment, nil)];
			else
				cell.textLabel.text = NSLocalizedString(datum.name, nil);
			BOOL isLargeData = (datum.data.length > MAX_DISPLAY_DATA_LENGTH);
			cell.detailTextLabel.text = (isLargeData ? [NSString stringWithFormat:@"%@... (%.2f KiB)", [datum.data substringToIndex:EXCEEDED_DISPLAY_DATA_LENGTH], (float)datum.data.length/1024.0f] : datum.data);
        } else {
            // If the row is outside the range, it's the row that was added to allow insertion (see tableView:numberOfRowsInSection:) so give it an appropriate label.
			static NSString *AddUserDatumCellIdentifier = @"AddUserDatumCell";
			
			cell = [tableView dequeueReusableCellWithIdentifier:AddUserDatumCellIdentifier];
			if (cell == nil) {
				 // Create a cell to display "Add UserDatum".
				cell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:AddUserDatumCellIdentifier] autorelease];
				cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
			}
            cell.textLabel.text = NSLocalizedString(@"Add Entry", nil);
        }
    }
	else {
         // If necessary create a new cell and configure it appropriately for the section.  Give the cell a different identifier from that used for cells in the Data section so that it can be dequeued separately.
        static NSString *MyIdentifier = @"GenericCell";
        
        cell = [tableView dequeueReusableCellWithIdentifier:MyIdentifier];
        if (cell == nil) {
            cell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:MyIdentifier] autorelease];
            cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
        }
        
        NSString *text = nil;
        
        switch (indexPath.section) {
			case SHARING_SECTION:
				text = NSLocalizedString(@"Sharing", nil);
                cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
                cell.editingAccessoryType = UITableViewCellAccessoryNone;
				break;
            case NOTES_SECTION: // notes
                text = NSLocalizedString(@"CreditsNotes", nil);
                cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
                cell.editingAccessoryType = UITableViewCellAccessoryNone;
                break;
            default:
                break;
        }
        
        cell.textLabel.text = text;
    }
    return cell;
}


#pragma mark -
#pragma mark Editing rows

- (NSIndexPath *)tableView:(UITableView *)tableView willSelectRowAtIndexPath:(NSIndexPath *)indexPath {
	NSIndexPath *rowToSelect = indexPath;
    NSInteger section = indexPath.section;
    BOOL isEditing = self.editing;
    
    // If editing, don't allow notes to be selected
    // Not editing: Only allow notes to be selected
    if ((isEditing && (section == NOTES_SECTION || section == SHARING_SECTION)) || (!isEditing && (section != NOTES_SECTION && section != SHARING_SECTION))) {
        [tableView deselectRowAtIndexPath:indexPath animated:YES];
        rowToSelect = nil;
    }

	return rowToSelect;
}


- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    NSInteger section = indexPath.section;
    UIViewController *nextViewController = nil;
    
    /*
     What to do on selection depends on what section the row is in.
     For Notes and Data, create and push a new view controller of the type appropriate for the next screen.
     */
    switch (section) {
        case SHARING_SECTION:
            nextViewController = [[DataSharingController alloc] initWithNibName:@"DataSharing" bundle:nil];
            ((DataSharingController *)nextViewController).calculator = nil;
            ((DataSharingController *)nextViewController).userDataCategory = userDataCategory;
            break;
			
        case NOTES_SECTION:
            nextViewController = [[NotesViewController alloc] initWithNibName:@"NotesView" bundle:nil];
            ((NotesViewController *)nextViewController).calculator = nil;
            ((NotesViewController *)nextViewController).userDataCategory = userDataCategory;
            break;
			
        case DATA_SECTION:
            nextViewController = [[UserDatumDetailViewController alloc] initWithStyle:UITableViewStyleGrouped];
            ((UserDatumDetailViewController *)nextViewController).userDataCategory = userDataCategory;
            
            if (indexPath.row < [userDataCategory.data count]) {
                UserDatum *datum = [data objectAtIndex:indexPath.row];
                ((UserDatumDetailViewController *)nextViewController).datum = datum;
            }
            break;

        default:
            break;
    }
    
    // If we got a new view controller, push it .
    if (nextViewController) {
        [self.navigationController pushViewController:nextViewController animated:YES];
        [nextViewController release];
    }
}


- (UITableViewCellEditingStyle)tableView:(UITableView *)tableView editingStyleForRowAtIndexPath:(NSIndexPath *)indexPath {
	UITableViewCellEditingStyle style = UITableViewCellEditingStyleNone;
    if (indexPath.section == DATA_SECTION) {
        // If this is the last item, it's the insertion row.
        if (indexPath.row == [userDataCategory.data count]) {
            style = UITableViewCellEditingStyleInsert;
        }
        else {
            style = UITableViewCellEditingStyleDelete;
        }
    }
    
    return style;
}


- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath {
    // Only allow deletion, and only in the data sections
    if ((editingStyle == UITableViewCellEditingStyleDelete) && (indexPath.section == DATA_SECTION)) {
        // Remove the corresponding datum object from the userDataCategory's datum list and delete the appropriate table view cell.
        UserDatum *datum = [data objectAtIndex:indexPath.row];
        [userDataCategory removeDataObject:datum];
        [data removeObject:datum];
        
        NSManagedObjectContext *context = datum.managedObjectContext;
        [context deleteObject:datum];
        
        [self.tableView deleteRowsAtIndexPaths:[NSArray arrayWithObject:indexPath] withRowAnimation:UITableViewRowAnimationTop];

		// re-enumerate display order fields
		for (NSInteger i = indexPath.row; i < [data count]; i++) {
			datum = [data objectAtIndex:i];
			datum.displayOrder = [NSNumber numberWithInteger:i];
		}
		
		// update fields that show data count
		self.nEntriesLabel.text = [NSString stringWithFormat:@"%lu", (unsigned long)[data count]];
    }
}


#pragma mark -
#pragma mark Moving rows

- (BOOL)tableView:(UITableView *)tableView canMoveRowAtIndexPath:(NSIndexPath *)indexPath {
    BOOL canMove = NO;

    // Moves are only allowed within the data section.  Within this one, the last row (Add Entry) cannot be moved.
    if (indexPath.section == DATA_SECTION)
        canMove = indexPath.row != [userDataCategory.data count];

    return canMove;
}


- (NSIndexPath *)tableView:(UITableView *)tableView targetIndexPathForMoveFromRowAtIndexPath:(NSIndexPath *)sourceIndexPath toProposedIndexPath:(NSIndexPath *)proposedDestinationIndexPath {
    NSIndexPath *target = proposedDestinationIndexPath;
    
    /*
     Moves are only allowed within the data section, so make sure the destination is in there.
     If the destination is in either section, make sure that it's not the Add row -- if it is, retarget for the penultimate row.
     */
	NSUInteger sourceSection = sourceIndexPath.section;
	NSUInteger proposedSection = proposedDestinationIndexPath.section;

	if (sourceSection == DATA_SECTION) {
		if (proposedSection < DATA_SECTION)
			target = [NSIndexPath indexPathForRow:0 inSection:DATA_SECTION];
		else if (proposedSection > DATA_SECTION)
			target = [NSIndexPath indexPathForRow:([userDataCategory.data count] - 1) inSection:DATA_SECTION];
		else {
			NSUInteger dataCount_1 = [userDataCategory.data count] - 1;			
			if (proposedDestinationIndexPath.row > dataCount_1)
				target = [NSIndexPath indexPathForRow:dataCount_1 inSection:DATA_SECTION];
		}
	}
	
    return target;
}


- (void)tableView:(UITableView *)tableView moveRowAtIndexPath:(NSIndexPath *)fromIndexPath toIndexPath:(NSIndexPath *)toIndexPath {

	NSUInteger sourceSection = fromIndexPath.section;
	
	if (sourceSection == DATA_SECTION) {		
		/*
		 Update the data array in response to the move.
		 Update the display order indexes within the range of the move.
		 */
		UserDatum *datum = [data objectAtIndex:fromIndexPath.row];
		[data removeObjectAtIndex:fromIndexPath.row];
		[data insertObject:datum atIndex:toIndexPath.row];

		NSInteger start = fromIndexPath.row;
		if (toIndexPath.row < start) {
			start = toIndexPath.row;
		}
		NSInteger end = toIndexPath.row;
		if (fromIndexPath.row > end) {
			end = fromIndexPath.row;
		}
		for (NSInteger i = start; i <= end; i++) {
			datum = [data objectAtIndex:i];
			// NSLog(@"%d: pre-existing: %d", i, [datum.displayOrder intValue]); // use to inspect displayOrder to verify correctness
			datum.displayOrder = [NSNumber numberWithInteger:i];
		}
	}
}


#pragma mark -
#pragma mark dealloc

- (void)dealloc {
    [tableHeaderView release];
    [nameTextField release];
    [overviewTextField release];
    [nEntriesLabel release];
    [userDataCategory release];
    [data release];
    [super dealloc];
}


@end
