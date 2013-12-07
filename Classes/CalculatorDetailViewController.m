
/*
     File: CalculatorDetailViewController.m
 Abstract: Table view controller to manage an editable table view that displays information about a calculator.
 The table view uses different cell types for different row types.
 
  Version: 1.0
  
 */

#import "CalculatorDetailViewController.h"

#import "Calculator.h"
#import "Key.h"
#import "Menu.h"
#import "Type.h"

#import "NotesViewController.h"
#import "InjectionViewController.h"
#import "TypeSelectionViewController.h"
#import "CalculatorPhotoViewController.h"
#import "KeyDetailViewController.h"
#import "MenuDetailViewController.h"
#import "DataSharingController.h"


@interface CalculatorDetailViewController (PrivateMethods)
- (void)updatePhotoButton;
@end

@implementation CalculatorDetailViewController

@synthesize calculator;
@synthesize keys;
@synthesize menus;

@synthesize tableHeaderView;
@synthesize photoButton;
@synthesize nameTextField, overviewTextField, nfunctionsLabel, nfunctionsTextLabel;

/**/#undef IS_ND1

#define TYPE_SECTION 0
#define KEYS_SECTION 1
#define MENUS_SECTION 2
#ifdef IS_ND1
#define RESTORE_SECTION 3
#define INJECTION_SECTION 4
#define N_SECTIONS 5
#else
#define NOTES_SECTION 3
#define SHARING_SECTION 4
#define RESTORE_SECTION 5
#define INJECTION_SECTION 6
#define N_SECTIONS 7
#endif

#pragma mark -
#pragma mark View controller

- (void)viewDidLoad {
    [super viewDidLoad];
#ifdef IS_ND1
	self.navigationItem.hidesBackButton = YES;
#endif

    self.navigationItem.rightBarButtonItem = self.editButtonItem;
    
    // Create and set the table header view.
    if (tableHeaderView == nil) {
        [[NSBundle mainBundle] loadNibNamed:@"DetailHeaderView" owner:self options:nil];
        self.tableView.tableHeaderView = tableHeaderView;
        self.tableView.allowsSelectionDuringEditing = YES;
    }

	if ([[[NSUserDefaults standardUserDefaults] objectForKey:@"tips_preference"] boolValue]) {
		UIAlertView *alert = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"DefinitionTips", nil) message:NSLocalizedString(@"DefinitionTip", nil) delegate:self cancelButtonTitle:nil otherButtonTitles:NSLocalizedString(@"GotIt", nil), nil];
		[alert show];
		[alert release];
	}	
}


- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
	
    [photoButton setImage:calculator.thumbnailImage forState:UIControlStateNormal];

	NSString *name = NSLocalizedString(calculator.name, nil);
#ifdef IS_ALSO_ND0
	name = [name stringByReplacingOccurrencesOfString:@"ND1" withString:@"ND0"];
#endif
	self.navigationItem.title = name;
    nameTextField.text = name;

#ifdef IS_ALSO_ND0
    overviewTextField.text = NSLocalizedString(@"ND0_Overview", nil);
#else
    overviewTextField.text = NSLocalizedString(calculator.overview, nil);
#endif
	nfunctionsTextLabel.text = NSLocalizedString(@"# functions:", nil);
	[self updatePhotoButton];

	/*
	 Create mutable arrays that contain the calculator's keys and menus ordered by displayOrder.
	 The table view uses this array to display these.
	 */
	NSSortDescriptor *sortDescriptor = [[NSSortDescriptor alloc] initWithKey:@"displayOrder" ascending:YES];
	NSArray *sortDescriptors = [[NSArray alloc] initWithObjects:&sortDescriptor count:1];

	if ([calculator.keys count]) {
		NSMutableArray *sortedKeys = [[NSMutableArray alloc] initWithArray:[calculator.keys allObjects]];
		[sortedKeys sortUsingDescriptors:sortDescriptors];
		self.keys = sortedKeys;
		[sortedKeys release];
	}
	else {
		keys = nil;
	}


	if ([calculator.menus count]) {
		NSMutableArray *sortedMenus = [[NSMutableArray alloc] initWithArray:[calculator.menus allObjects]];
		[sortedMenus sortUsingDescriptors:sortDescriptors];
		self.menus = sortedMenus;
		[sortedMenus release];
	}
	else {
		menus = nil;
	}

	
	[sortDescriptor release];
	[sortDescriptors release];

	// figure # of functions in keys and menus
	NSUInteger nfunctions = 0;
	for (Key *key in calculator.keys)
		nfunctions += [[key.function componentsSeparatedByString:@", "] count];
	for (Menu *menu in calculator.menus)
		if (![menu.title isEqualToString:@"Const"])
			nfunctions += [[menu.function componentsSeparatedByString:@", "] count];	
	self.nfunctionsLabel.text = [NSString stringWithFormat:@"%lu", (unsigned long)nfunctions];

    [self.tableView reloadData];
}


- (void)viewDidUnload {
    self.tableHeaderView = nil;
	self.photoButton = nil;
	self.nameTextField = nil;
	self.overviewTextField = nil;
	self.nfunctionsLabel = nil;
	self.nfunctionsTextLabel = nil;
	[super viewDidUnload];
}


- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
    return (interfaceOrientation != UIInterfaceOrientationPortraitUpsideDown);
}


#pragma mark -
#pragma mark Editing

- (void)setEditing:(BOOL)editing animated:(BOOL)animated {
    [super setEditing:editing animated:animated];
    
	[self updatePhotoButton];
	overviewTextField.enabled = editing;
#ifndef IS_ND1
	nameTextField.enabled = editing;
	[self.navigationItem setHidesBackButton:editing animated:YES];
#endif

	[self.tableView beginUpdates];
	
    NSUInteger keysCount = [calculator.keys count];
    NSArray *keysInsertIndexPath = [NSArray arrayWithObject:[NSIndexPath indexPathForRow:keysCount inSection:KEYS_SECTION]];
    NSUInteger menusCount = [calculator.menus count];
    NSArray *menusInsertIndexPath = [NSArray arrayWithObject:[NSIndexPath indexPathForRow:menusCount inSection:MENUS_SECTION]];
    if (editing) {
        [self.tableView insertRowsAtIndexPaths:keysInsertIndexPath withRowAnimation:UITableViewRowAnimationTop];
        [self.tableView insertRowsAtIndexPaths:menusInsertIndexPath withRowAnimation:UITableViewRowAnimationTop];
		overviewTextField.placeholder = NSLocalizedString(@"Overview", nil);
	} else {
        [self.tableView deleteRowsAtIndexPaths:keysInsertIndexPath withRowAnimation:UITableViewRowAnimationTop];
        [self.tableView deleteRowsAtIndexPaths:menusInsertIndexPath withRowAnimation:UITableViewRowAnimationTop];
		overviewTextField.placeholder = @"";
    }
    
    [self.tableView endUpdates];
	
	// when editing is finished, save the managed object context
	if (!editing) {
		NSManagedObjectContext *context = calculator.managedObjectContext;
		NSError *error = nil;
		if (![context save:&error]) {
			// todo: better action
			NSLog(@"Unresolved error %@, %@", error, [error userInfo]);
/////			abort();
		}
	}
}


- (BOOL)textFieldShouldEndEditing:(UITextField *)textField {
	if (textField == nameTextField) {
		calculator.name = nameTextField.text;
		self.navigationItem.title = calculator.name;
	}
	else if (textField == overviewTextField) {
		calculator.overview = overviewTextField.text;
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
	return ([[NSUserDefaults standardUserDefaults] boolForKey:@"injection_preference"] ? N_SECTIONS : (N_SECTIONS-1));
}


- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
    NSString *title = nil;
    switch (section) {
        case TYPE_SECTION:
            title = NSLocalizedString(@"Type", nil);
            break;
        case KEYS_SECTION:
            title = ([calculator.type.name isEqualToString:@"Normal"] || [calculator.type.name isEqualToString:@"RPN"] ? NSLocalizedString(@"Keys", nil) : NSLocalizedString(@"Interface Elements", nil));
            break;
        case MENUS_SECTION:
            title = NSLocalizedString(@"Menus", nil);
            break;
        default:
            break;
    }
    return title;
}


- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    NSInteger rows = 0;
    
    // the number of rows depends on the section.
	// in the case of keys and menus, if editing, add a row in editing mode to present the "Add ..." cell.
    switch (section) {
        case TYPE_SECTION:
			rows = 3;
			break;
        case KEYS_SECTION:
            rows = [calculator.keys count];
            if (self.editing)
                rows++;
            break;
        case MENUS_SECTION:
            rows = [calculator.menus count];
            if (self.editing)
                rows++;
            break;
#ifndef IS_ND1
        case NOTES_SECTION:
		case SHARING_SECTION:
            rows = 1;
            break;
#endif
		case RESTORE_SECTION:
        case INJECTION_SECTION:
            rows = 1;
            break;
		default:
            break;
    }
    return rows;
}


- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = nil;
    
    if (indexPath.section == KEYS_SECTION) {
		NSUInteger keyCount = [calculator.keys count];
        NSInteger row = indexPath.row;
		
        if (indexPath.row < keyCount) {
            // If the row is within the range of the number of keys for the current calculator, then configure the cell to show the key name and amount.
			static NSString *KeysCellIdentifier = @"KeysCell";
			
			cell = [tableView dequeueReusableCellWithIdentifier:KeysCellIdentifier];
			
			if (cell == nil) {
				 // Create a cell to display an key.
				cell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:KeysCellIdentifier] autorelease];
				cell.accessoryType = UITableViewCellAccessoryNone;
			}
			
            Key *key = [keys objectAtIndex:row];
            cell.textLabel.text = key.name;
			cell.detailTextLabel.text = key.function;
        } else {
            // If the row is outside the range, it's the row that was added to allow insertion (see tableView:numberOfRowsInSection:) so give it an appropriate label.
			static NSString *AddKeyCellIdentifier = @"AddKeyCell";
			
			cell = [tableView dequeueReusableCellWithIdentifier:AddKeyCellIdentifier];
			if (cell == nil) {
				 // Create a cell to display "Add Key".
				cell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:AddKeyCellIdentifier] autorelease];
				cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
			}
            cell.textLabel.text = ([calculator.type.name isEqualToString:@"Normal"] || [calculator.type.name isEqualToString:@"RPN"] ? NSLocalizedString(@"Add Key", nil) : NSLocalizedString(@"Add Interface Element", nil));
        }
    }
	else if (indexPath.section == MENUS_SECTION) {
		NSUInteger menuCount = [calculator.menus count];
        NSInteger row = indexPath.row;
		
        if (indexPath.row < menuCount) {
            // If the row is within the range of the number of menus for the current calculator, then configure the cell to show the menu name and amount.
			static NSString *MenusCellIdentifier = @"MenusCell";
			
			cell = [tableView dequeueReusableCellWithIdentifier:MenusCellIdentifier];
			
			if (cell == nil) {
				// Create a cell to display an menu.
				cell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:MenusCellIdentifier] autorelease];
				cell.accessoryType = UITableViewCellAccessoryNone;
			}
			
            Menu *menu = [menus objectAtIndex:row];
            cell.textLabel.text = menu.title;
			cell.detailTextLabel.text = menu.name;
        } else {
            // If the row is outside the range, it's the row that was added to allow insertion (see tableView:numberOfRowsInSection:) so give it an appropriate label.
			static NSString *AddMenuCellIdentifier = @"AddMenuCell";
			
			cell = [tableView dequeueReusableCellWithIdentifier:AddMenuCellIdentifier];
			if (cell == nil) {
				// Create a cell to display "Add Menu".
				cell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:AddMenuCellIdentifier] autorelease];
				cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
			}
            cell.textLabel.text = NSLocalizedString(@"Add Menu", nil);
        }
    }
	else if (indexPath.section == TYPE_SECTION) {
        static NSString *MyIdentifier = @"TypeCell";
        
        cell = [tableView dequeueReusableCellWithIdentifier:MyIdentifier];
        if (cell == nil) {
            cell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleValue1 reuseIdentifier:MyIdentifier] autorelease];
            cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
        }
        
        NSString *text = nil, *detailText;
		if (indexPath.row == 0) {
			text = NSLocalizedString(@"Mode", nil);
			detailText = NSLocalizedString([calculator.type valueForKey:@"name"], nil);
		}
		else if (indexPath.row == 1) {
			text = NSLocalizedString(@"Skin", nil);
			detailText = NSLocalizedString([calculator.skin valueForKey:@"name"], nil);
		}
		else {
			text = NSLocalizedString(@"Orientation", nil);
			detailText = NSLocalizedString([calculator.orientation valueForKey:@"name"], nil);
		}
		cell.accessoryType = UITableViewCellAccessoryNone;
#ifdef IS_ND1
		if (indexPath.row == 1) // "Skin"
#endif		
		cell.editingAccessoryType = UITableViewCellAccessoryDisclosureIndicator;
		
		cell.textLabel.text = text;
		cell.detailTextLabel.text = detailText;
	}
	else {
         // If necessary create a new cell and configure it appropriately for the section.  Give the cell a different identifier from that used for cells in the Keys and Menus sections so that it can be dequeued separately.
        static NSString *MyIdentifier = @"GenericCell";
        
        cell = [tableView dequeueReusableCellWithIdentifier:MyIdentifier];
        if (cell == nil) {
            cell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:MyIdentifier] autorelease];
            cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
        }
        
        NSString *text = nil;
        
        switch (indexPath.section) {
            case TYPE_SECTION: // type -- should be selectable -> checkbox
				if (indexPath.row == 0)
					text = [calculator.type valueForKey:@"name"];
				else if (indexPath.row == 1)
					text = [calculator.skin valueForKey:@"name"];
				else
					text = [calculator.orientation valueForKey:@"name"];
                cell.accessoryType = UITableViewCellAccessoryNone;
                cell.editingAccessoryType = UITableViewCellAccessoryDisclosureIndicator;
                break;
            case INJECTION_SECTION: // injection string
                text = NSLocalizedString(@"Injection", nil);
                cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
                cell.editingAccessoryType = UITableViewCellAccessoryNone;
                break;
			case RESTORE_SECTION:
#ifndef IS_ND1
			case SHARING_SECTION:
				if (indexPath.section == SHARING_SECTION)
					text = NSLocalizedString(@"Sharing", nil);
				else
#endif
					text = NSLocalizedString(@"Restore", nil);
                cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
                cell.editingAccessoryType = UITableViewCellAccessoryNone;
				break;
#ifndef IS_ND1
            case NOTES_SECTION: // notes
                text = NSLocalizedString(@"CreditsNotes", nil);
                cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
                cell.editingAccessoryType = UITableViewCellAccessoryNone;
                break;
#endif
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

#ifdef IS_ND1
	// disallow editing of type attributes other than "Skin"
	if (isEditing && (section == TYPE_SECTION && indexPath.row != 1))
		rowToSelect = nil;
#endif

    // If editing, don't allow notes/injection to be selected
    // Not editing: Only allow notes/injection to be selected
#ifdef IS_ND1
    if ((isEditing && (section == INJECTION_SECTION || section == RESTORE_SECTION)) || (!isEditing && (section != INJECTION_SECTION && section != RESTORE_SECTION))) {
#else
	if ((isEditing && (section == NOTES_SECTION || section == INJECTION_SECTION || section == SHARING_SECTION || section == RESTORE_SECTION)) || (!isEditing && (section != NOTES_SECTION && section != INJECTION_SECTION && section != SHARING_SECTION && section != RESTORE_SECTION))) {
#endif
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
     For Type, Notes, and Keys, create and push a new view controller of the type appropriate for the next screen.
     */
    switch (section) {
        case TYPE_SECTION:
            nextViewController = [[TypeSelectionViewController alloc] initWithStyle:UITableViewStyleGrouped];
            ((TypeSelectionViewController *)nextViewController).calculator = calculator;
			((TypeSelectionViewController *)nextViewController).typeString = (indexPath.row == 0 ? @"Type" : (indexPath.row == 1 ? @"Skin" : @"Orientation"));
            break;
			
        case INJECTION_SECTION:
            nextViewController = [[InjectionViewController alloc] initWithNibName:@"InjectionView" bundle:nil];
            ((InjectionViewController *)nextViewController).calculator = calculator;
            break;
			
        case RESTORE_SECTION:
#ifndef IS_ND1
        case SHARING_SECTION:
			if (section == SHARING_SECTION)
				nextViewController = [[DataSharingController alloc] initWithNibName:@"DataSharing" bundle:nil];
			else
#endif
				nextViewController = [[DataSharingController alloc] initWithNibName:@"DataSharing_Restore" bundle:nil];
            ((DataSharingController *)nextViewController).calculator = calculator;
            ((DataSharingController *)nextViewController).userDataCategory = nil;
            break;

#ifndef IS_ND1
        case NOTES_SECTION:
            nextViewController = [[NotesViewController alloc] initWithNibName:@"NotesView" bundle:nil];
            ((NotesViewController *)nextViewController).calculator = calculator;
            break;
#endif
			
        case KEYS_SECTION:
            nextViewController = [[KeyDetailViewController alloc] initWithStyle:UITableViewStyleGrouped];
            ((KeyDetailViewController *)nextViewController).calculator = calculator;
            
            if (indexPath.row < [calculator.keys count]) {
                Key *key = [keys objectAtIndex:indexPath.row];
                ((KeyDetailViewController *)nextViewController).key = key;
            }
            break;
			
        case MENUS_SECTION:
            nextViewController = [[MenuDetailViewController alloc] initWithStyle:UITableViewStyleGrouped];
            ((MenuDetailViewController *)nextViewController).calculator = calculator;
            
            if (indexPath.row < [calculator.menus count]) {
                Menu *menu = [menus objectAtIndex:indexPath.row];
                ((MenuDetailViewController *)nextViewController).menu = menu;
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
    if (indexPath.section == KEYS_SECTION) {
        // If this is the last item, it's the insertion row.
        if (indexPath.row == [calculator.keys count]) {
            style = UITableViewCellEditingStyleInsert;
        }
        else {
            style = UITableViewCellEditingStyleDelete;
        }
    }
    else if (indexPath.section == MENUS_SECTION) {
        // If this is the last item, it's the insertion row.
        if (indexPath.row == [calculator.menus count]) {
            style = UITableViewCellEditingStyleInsert;
        }
        else {
            style = UITableViewCellEditingStyleDelete;
        }
    }
    
    return style;
}


- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath {
    // Only allow deletion, and only in the keys and menus sections
    if ((editingStyle == UITableViewCellEditingStyleDelete) && (indexPath.section == KEYS_SECTION)) {
        // Remove the corresponding key object from the calculator's key list and delete the appropriate table view cell.
        Key *key = [keys objectAtIndex:indexPath.row];
        [calculator removeKeysObject:key];
        [keys removeObject:key];
        
        NSManagedObjectContext *context = key.managedObjectContext;
        [context deleteObject:key];
        
        [self.tableView deleteRowsAtIndexPaths:[NSArray arrayWithObject:indexPath] withRowAnimation:UITableViewRowAnimationTop];

		// re-enumerate display order fields
		for (NSInteger i = indexPath.row; i < [keys count]; i++) {
			key = [keys objectAtIndex:i];
			key.displayOrder = [NSNumber numberWithInteger:i];
		}
    }
    else if ((editingStyle == UITableViewCellEditingStyleDelete) && (indexPath.section == MENUS_SECTION)) {
		Menu *menu = [menus objectAtIndex:indexPath.row];
        [calculator removeMenusObject:menu];
        [menus removeObject:menu];
        
        NSManagedObjectContext *context = menu.managedObjectContext;
        [context deleteObject:menu];
        
        [self.tableView deleteRowsAtIndexPaths:[NSArray arrayWithObject:indexPath] withRowAnimation:UITableViewRowAnimationTop];

		// re-enumerate display order fields
		for (NSInteger i = indexPath.row; i < [menus count]; i++) {
			menu = [menus objectAtIndex:i];
			menu.displayOrder = [NSNumber numberWithInteger:i];
		}
    }
}


#pragma mark -
#pragma mark Moving rows

- (BOOL)tableView:(UITableView *)tableView canMoveRowAtIndexPath:(NSIndexPath *)indexPath {
    BOOL canMove = NO;

    // Moves are only allowed within the keys and menus sections.  Within these, the last row (Add Key/Menu) cannot be moved.
    if (indexPath.section == KEYS_SECTION)
        canMove = indexPath.row != [calculator.keys count];
    else if (indexPath.section == MENUS_SECTION)
        canMove = indexPath.row != [calculator.menus count];

    return canMove;
}


- (NSIndexPath *)tableView:(UITableView *)tableView targetIndexPathForMoveFromRowAtIndexPath:(NSIndexPath *)sourceIndexPath toProposedIndexPath:(NSIndexPath *)proposedDestinationIndexPath {
    NSIndexPath *target = proposedDestinationIndexPath;
    
    /*
     Moves are only allowed within the keys and menus sections, so make sure the destination is in either.
     If the destination is in either section, make sure that it's not the Add row -- if it is, retarget for the penultimate row.
     */
	NSUInteger sourceSection = sourceIndexPath.section;
	NSUInteger proposedSection = proposedDestinationIndexPath.section;

	if (sourceSection == KEYS_SECTION) {
		if (proposedSection < KEYS_SECTION)
			target = [NSIndexPath indexPathForRow:0 inSection:KEYS_SECTION];
		else if (proposedSection > KEYS_SECTION)
			target = [NSIndexPath indexPathForRow:([calculator.keys count] - 1) inSection:KEYS_SECTION];
		else {
			NSUInteger keysCount_1 = [calculator.keys count] - 1;			
			if (proposedDestinationIndexPath.row > keysCount_1)
				target = [NSIndexPath indexPathForRow:keysCount_1 inSection:KEYS_SECTION];
		}
	}
	else if (sourceSection == MENUS_SECTION) {
		if (proposedSection < MENUS_SECTION)
			target = [NSIndexPath indexPathForRow:0 inSection:MENUS_SECTION];
		else if (proposedSection > MENUS_SECTION)
			target = [NSIndexPath indexPathForRow:([calculator.menus count] - 1) inSection:MENUS_SECTION];
		else {
			NSUInteger menusCount_1 = [calculator.menus count] - 1;
			if (proposedDestinationIndexPath.row > menusCount_1)
				target = [NSIndexPath indexPathForRow:menusCount_1 inSection:MENUS_SECTION];
		}
	}
	
    return target;
}


- (void)tableView:(UITableView *)tableView moveRowAtIndexPath:(NSIndexPath *)fromIndexPath toIndexPath:(NSIndexPath *)toIndexPath {
	NSUInteger sourceSection = fromIndexPath.section;
	
	if (sourceSection == KEYS_SECTION) {		
		/*
		 Update the keys array in response to the move.
		 Update the display order indexes within the range of the move.
		 */
		Key *key = [keys objectAtIndex:fromIndexPath.row];
		[keys removeObjectAtIndex:fromIndexPath.row];
		[keys insertObject:key atIndex:toIndexPath.row];

		NSInteger start = fromIndexPath.row;
		if (toIndexPath.row < start) {
			start = toIndexPath.row;
		}
		NSInteger end = toIndexPath.row;
		if (fromIndexPath.row > end) {
			end = fromIndexPath.row;
		}
		for (NSInteger i = start; i <= end; i++) {
			key = [keys objectAtIndex:i];
			key.displayOrder = [NSNumber numberWithInteger:i];
		}
	}
	else if (sourceSection == MENUS_SECTION) {		
		Menu *menu = [menus objectAtIndex:fromIndexPath.row];
		[menus removeObjectAtIndex:fromIndexPath.row];
		[menus insertObject:menu atIndex:toIndexPath.row];
		
		NSInteger start = fromIndexPath.row;
		if (toIndexPath.row < start) {
			start = toIndexPath.row;
		}
		NSInteger end = toIndexPath.row;
		if (fromIndexPath.row > end) {
			end = fromIndexPath.row;
		}
		for (NSInteger i = start; i <= end; i++) {
			menu = [menus objectAtIndex:i];
			menu.displayOrder = [NSNumber numberWithInteger:i];
		}
	}	
}


#pragma mark -
#pragma mark Photo

- (IBAction)photoTapped {
#ifndef IS_ND1
    // If in editing state, then display an image picker; if not, create and push a photo view controller.
	if (self.editing) {
		UIImagePickerController *imagePicker = [[UIImagePickerController alloc] init];
		imagePicker.delegate = self;
		[self presentViewController:imagePicker animated:YES completion:nil];
		[imagePicker release];
	} else {	
		CalculatorPhotoViewController *calculatorPhotoViewController = [[CalculatorPhotoViewController alloc] init];
        calculatorPhotoViewController.hidesBottomBarWhenPushed = YES;
		calculatorPhotoViewController.calculator = calculator;
		[self.navigationController pushViewController:calculatorPhotoViewController animated:YES];
		[calculatorPhotoViewController release];
	}
#endif
}


- (void)imagePickerController:(UIImagePickerController *)picker didFinishPickingImage:(UIImage *)selectedImage editingInfo:(NSDictionary *)editingInfo {
	// Delete any existing image.
	NSManagedObject *oldImage = calculator.image;
	if (oldImage != nil) {
		[calculator.managedObjectContext deleteObject:oldImage];
	}
	
    // Create an image object for the new image.
	NSManagedObject *image = [NSEntityDescription insertNewObjectForEntityForName:@"CalculatorImage" inManagedObjectContext:calculator.managedObjectContext];
	calculator.image = image;

	// Set the image for the image managed object.
	[image setValue:selectedImage forKey:@"image"];
	
	// Create a thumbnail version of the image for the calculator object.

	CGSize size = selectedImage.size;
	CGFloat ratio = 0;
	if (size.width > size.height) {
		ratio = 44.0 / size.width;
	} else {
		ratio = 44.0 / size.height;
	}
	CGRect rect = CGRectMake(0.0, 0.0, ratio * size.width, ratio * size.height);
	
	UIGraphicsBeginImageContext(rect.size);
	[selectedImage drawInRect:rect];
	calculator.thumbnailImage = UIGraphicsGetImageFromCurrentImageContext();
	UIGraphicsEndImageContext();
	
    [self dismissViewControllerAnimated:YES completion:nil];
}


- (void)imagePickerControllerDidCancel:(UIImagePickerController *)picker {
    [self dismissViewControllerAnimated:YES completion:nil];
}


- (void)updatePhotoButton {
	/*
	 How to present the photo button depends on the editing state and whether the calculator has a thumbnail image.
	 * If the calculator has a thumbnail, set the button's highlighted state to the same as the editing state (it's highlighted if editing).
	 * If the calculator doesn't have a thumbnail, then: if editing, enable the button and show an image that says "Choose Photo" or similar; if not editing then disable the button and show nothing.  
	 */
	BOOL editing = self.editing;
	
	if (calculator.thumbnailImage != nil) {
		photoButton.highlighted = editing;
	} else {
		photoButton.enabled = editing;
		
		if (editing) {
			[photoButton setImage:[UIImage imageNamed:@"choosePhoto.png"] forState:UIControlStateNormal];
		} else {
			[photoButton setImage:nil forState:UIControlStateNormal];
		}
	}
}


#pragma mark -
#pragma mark dealloc

- (void)dealloc {
    [tableHeaderView release];
    [photoButton release];
    [nameTextField release];
    [overviewTextField release];
    [nfunctionsLabel release];
    [nfunctionsTextLabel release];
    [calculator release];
    [keys release];
    [menus release];
    [super dealloc];
}


@end
