
/*
     File: NotesViewController.m
 Abstract: View controller to manage a text view to allow the user to edit notes for a calculator.
 
  Version: 1.0
  
 */

#import "NotesViewController.h"
#import "Calculator.h"
#import "UserDataCategory.h"

@implementation NotesViewController

@synthesize calculator;
@synthesize userDataCategory;
@synthesize notesText;


- (void)viewDidLoad {
    [super viewDidLoad];
    UINavigationItem *navigationItem = self.navigationItem;
    navigationItem.title = NSLocalizedString(@"CreditsNotes", nil);
    self.navigationItem.rightBarButtonItem = self.editButtonItem;
}

- (void)viewDidUnload {
	self.notesText = nil;
	[super viewDidUnload];
}

- (void)viewWillAppear:(BOOL)animated {    
    // Update the views appropriately
/// was:    nameLabel.text = NSLocalizedString(calculator ? calculator.name : userDataCategory.name, nil);
    notesText.text = calculator ? calculator.notes : userDataCategory.notes;    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardWillShow:) name:UIKeyboardWillShowNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardWillHide:) name:UIKeyboardWillHideNotification object:nil];
}

- (void)viewWillDisappear:(BOOL)animated {    
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)keyboardWillShow:(NSNotification *)aNotification {
	// the keyboard is showing so resize the table's height
	CGRect keyboardRect = [[[aNotification userInfo] objectForKey:UIKeyboardFrameBeginUserInfoKey] CGRectValue];
    NSTimeInterval animationDuration = [[[aNotification userInfo] objectForKey:UIKeyboardAnimationDurationUserInfoKey] doubleValue];
    CGRect frame = self.view.frame;
    frame.size.height -= keyboardRect.size.height-50;
    [UIView beginAnimations:@"ResizeForKeyboard" context:nil];
    [UIView setAnimationDuration:animationDuration];
    self.view.frame = frame;
    [UIView commitAnimations];
}

- (void)keyboardWillHide:(NSNotification *)aNotification {
    // the keyboard is hiding reset the table's height
	CGRect keyboardRect = [[[aNotification userInfo] objectForKey:UIKeyboardFrameBeginUserInfoKey] CGRectValue];
    NSTimeInterval animationDuration = [[[aNotification userInfo] objectForKey:UIKeyboardAnimationDurationUserInfoKey] doubleValue];
    CGRect frame = self.view.frame;
    frame.size.height += keyboardRect.size.height-50;
    [UIView beginAnimations:@"ResizeForKeyboard" context:nil];
    [UIView setAnimationDuration:animationDuration];
    self.view.frame = frame;
    [UIView commitAnimations];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
    return (interfaceOrientation != UIInterfaceOrientationPortraitUpsideDown);
}

- (void)setEditing:(BOOL)editing animated:(BOOL)animated {
    [super setEditing:editing animated:animated];

    notesText.editable = editing;
	[self.navigationItem setHidesBackButton:editing animated:YES];

	// when editing is finished, update the notes and save the managed object context
	if (!editing) {
		if (calculator)
			calculator.notes = notesText.text;
		else
			userDataCategory.notes = notesText.text;
		
		NSManagedObjectContext *context = calculator ? calculator.managedObjectContext : userDataCategory.managedObjectContext;
		NSError *error = nil;
		if (![context save:&error]) {
			// todo: better action
			NSLog(@"Unresolved error %@, %@", error, [error userInfo]);
			abort();
		}
	}		
}

- (void)dealloc {
    [calculator release];
	[userDataCategory release];
    [notesText release];
    [super dealloc];
}

@end
