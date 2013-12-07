
/*
     File: UserDataCategoryAddViewController.m
 Abstract: View controller to allow the user to add a new userDataCategory and choose its picture using the image picker.
 If the user taps Save, the userDataCategory detail view controller is pushed so that the user can edit the new item.
 
  Version: 1.0
 
 */

#import "UserDataCategoryAddViewController.h"
#import "UserDataCategory.h"

@implementation UserDataCategoryAddViewController

@synthesize userDataCategory;
@synthesize nameTextField;
@synthesize delegate;


- (void)viewDidLoad {
    [super viewDidLoad];

    self.navigationItem.title = NSLocalizedString(@"Add Category", nil);
    
    UIBarButtonItem *cancelButtonItem = [[UIBarButtonItem alloc] initWithTitle:NSLocalizedString(@"Cancel", nil) style:UIBarButtonItemStylePlain target:self action:@selector(cancel)];
    self.navigationItem.leftBarButtonItem = cancelButtonItem;
    [cancelButtonItem release];
    
    UIBarButtonItem *saveButtonItem = [[UIBarButtonItem alloc] initWithTitle:NSLocalizedString(@"Save", nil) style:UIBarButtonItemStyleDone target:self action:@selector(save)];
    self.navigationItem.rightBarButtonItem = saveButtonItem;
    [saveButtonItem release];
	
	nameTextField.placeholder = NSLocalizedString(@"AddCategoryPlaceholder", nil);
	[nameTextField becomeFirstResponder];
}


- (void)viewDidUnload {
	self.nameTextField = nil;
	[super viewDidUnload];
}
	
	
- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
    // Support all orientations except upside-down
    return (interfaceOrientation != UIInterfaceOrientationPortraitUpsideDown);
}


- (BOOL)textFieldShouldReturn:(UITextField *)textField {
	if (textField == nameTextField) {
		[nameTextField resignFirstResponder];
		[self save];
	}
	return YES;
}


- (void)save {
	// cancel if a zero-length name is provided
	if (![nameTextField.text length]) {
		[self cancel];
		return;
	}
	
    userDataCategory.name = nameTextField.text;

	NSError *error = nil;
	if (![userDataCategory.managedObjectContext save:&error]) {
		// todo: better action
		NSLog(@"Unresolved error %@, %@", error, [error userInfo]);
		abort();
	}		
    
	[self.delegate userDataCategoryAddViewController:self didAddUserDataCategory:userDataCategory];
}


- (void)cancel {
	[userDataCategory.managedObjectContext deleteObject:userDataCategory];

	NSError *error = nil;
	if (![userDataCategory.managedObjectContext save:&error]) {
		// todo: better action
		NSLog(@"Unresolved error %@, %@", error, [error userInfo]);
		abort();
	}		

    [self.delegate userDataCategoryAddViewController:self didAddUserDataCategory:nil];
}


- (void)dealloc {
    [userDataCategory release];    
    [nameTextField release];    
    [super dealloc];
}

@end
