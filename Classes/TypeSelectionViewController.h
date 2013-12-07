
/*
     File: TypeSelectionViewController.h
 Abstract: Table view controller to allow the user to select the calculator type.
 The options are presented as items in the table view; the selected item has a check mark in the accessory view. The controller caches the index path of the selected item to avoid the need to perform repeated string comparisons after an update.
 
  Version: 1.0
  
 */

@class Calculator;

@interface TypeSelectionViewController : UITableViewController {
@private
	Calculator *calculator;
	NSString *typeString;
	NSArray *calculatorTypes;
}

@property (nonatomic, retain) Calculator *calculator;
@property (nonatomic, retain) NSString *typeString;
@property (nonatomic, retain, readonly) NSArray *calculatorTypes;

@end
