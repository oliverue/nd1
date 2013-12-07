//
//  InjectionViewController.m
//  Calculate
//
//  Created by Oliver Unter Ecker on 10/12/09.
//  Copyright 2009 Naive Design. All rights reserved.
//

#import "Calculator.h"
#import "InjectionViewController.h"


@implementation InjectionViewController

@synthesize calculator;
@synthesize notesText;
@synthesize nameLabel;


- (void)viewDidLoad {
    [super viewDidLoad];
    UINavigationItem *navigationItem = self.navigationItem;
    navigationItem.title = NSLocalizedString(@"Injection", nil);
    self.navigationItem.rightBarButtonItem = self.editButtonItem;
}

- (void)viewDidUnload {
	self.notesText = nil;
	[super viewDidUnload];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];

    // Update the views appropriately
    notesText.text = calculator.injection;
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardWillShow:) name:UIKeyboardWillShowNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardWillHide:) name:UIKeyboardWillHideNotification object:nil];
}

- (void)viewWillDisappear:(BOOL)animated {    
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    [super viewWillDisappear:animated];
}

- (void)keyboardWillShow:(NSNotification *)aNotification  {
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
		calculator.injection = notesText.text;
		
		NSManagedObjectContext *context = calculator.managedObjectContext;
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
    [notesText release];
    [super dealloc];
}

@end
