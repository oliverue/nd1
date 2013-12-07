
/*
     File: CalculatorAddViewController.m
 Abstract: View controller to allow the user to add a new calculator and choose its picture using the image picker.
 If the user taps Save, the calculator detail view controller is pushed so that the user can edit the new item.
 
  Version: 1.0
 
 */

#import "CalculatorAddViewController.h"
#import "Calculator.h"

@implementation CalculatorAddViewController

@synthesize calculator;
@synthesize nameTextField;
@synthesize delegate;


- (void)viewDidLoad {
    [super viewDidLoad];
    self.navigationItem.title = NSLocalizedString(@"Add Calculator", nil);
    
    UIBarButtonItem *cancelButtonItem = [[UIBarButtonItem alloc] initWithTitle:NSLocalizedString(@"Cancel", nil) style:UIBarButtonItemStylePlain target:self action:@selector(cancel)];
    self.navigationItem.leftBarButtonItem = cancelButtonItem;
    [cancelButtonItem release];
    
    UIBarButtonItem *saveButtonItem = [[UIBarButtonItem alloc] initWithTitle:NSLocalizedString(@"Save", nil) style:UIBarButtonItemStyleDone target:self action:@selector(save)];
    self.navigationItem.rightBarButtonItem = saveButtonItem;
    [saveButtonItem release];
	
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
	
    calculator.name = nameTextField.text;
	
	// populate mandatory fields with their default values

	NSError *error = nil;
	NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] init];

	[fetchRequest setEntity:[NSEntityDescription entityForName:@"Type" inManagedObjectContext:calculator.managedObjectContext]];
	calculator.type = [[calculator.managedObjectContext executeFetchRequest:fetchRequest error:&error] objectAtIndex:0];
	
	[fetchRequest setEntity:[NSEntityDescription entityForName:@"Orientation" inManagedObjectContext:calculator.managedObjectContext]];
	calculator.orientation = [[calculator.managedObjectContext executeFetchRequest:fetchRequest error:&error] objectAtIndex:0];
	
	[fetchRequest setEntity:[NSEntityDescription entityForName:@"Skin" inManagedObjectContext:calculator.managedObjectContext]];
	calculator.skin = [[calculator.managedObjectContext executeFetchRequest:fetchRequest error:&error] objectAtIndex:0];

    calculator.uploadDate = [NSDate date];

	[fetchRequest release];

	// save

	error = nil;
	if (![calculator.managedObjectContext save:&error]) {
		// todo: better action
		NSLog(@"Unresolved error %@, %@", error, [error userInfo]);
		abort();
	}		
    
	[self.delegate calculatorAddViewController:self didAddCalculator:calculator];
}


- (void)cancel {
	[calculator.managedObjectContext deleteObject:calculator];

	NSError *error = nil;
	if (![calculator.managedObjectContext save:&error]) {
		// todo: better action
		NSLog(@"Unresolved error %@, %@", error, [error userInfo]);
		abort();
	}		

    [self.delegate calculatorAddViewController:self didAddCalculator:nil];
}


- (void)dealloc {
    [calculator release];    
    [nameTextField release];    
    [super dealloc];
}

@end
