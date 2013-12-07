
/*
     File: KeyDetailViewController.h
 Abstract: Table view controller to manage editing details of a calculator key -- its name and function.
 
  Version: 1.0

 */

@class Calculator, Key, EditingTableViewCell;

@interface KeyDetailViewController : UITableViewController {
    @private
        Calculator *calculator;
        Key *key;
        
        EditingTableViewCell *editingTableViewCell;
}

@property (nonatomic, retain) Calculator *calculator;
@property (nonatomic, retain) Key *key;

@property (nonatomic, assign) IBOutlet EditingTableViewCell *editingTableViewCell;

@end
