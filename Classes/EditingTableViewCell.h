
/*
     File: EditingTableViewCell.h
 Abstract: A table view cell that displays a label and a text field so that a value can be edited. The user interface is loaded from a nib file.
 
  Version: 1.0

 */

@interface EditingTableViewCell : UITableViewCell {
	UILabel *label;
	UITextField *textField;
}

@property (nonatomic, retain) IBOutlet UILabel *label;
@property (nonatomic, retain) IBOutlet UITextField *textField;

@end
