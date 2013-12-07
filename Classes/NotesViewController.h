
/*
     File: NotesViewController.h
 Abstract: View controller to manage a text view to allow the user to edit notes for a calculator.
 
  Version: 1.0
  
 */

@class Calculator;
@class UserDataCategory;

@interface NotesViewController : UIViewController <UITextViewDelegate>
{
    @private
		Calculator *calculator;
		UserDataCategory *userDataCategory;
        UITextView *notesText;
}

@property (nonatomic, retain) Calculator *calculator;
@property (nonatomic, retain) UserDataCategory *userDataCategory;
@property (nonatomic, retain) IBOutlet UITextView *notesText;

@end
