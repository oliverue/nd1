
/*
     File: MenuDetailViewController.h
 Abstract: Table view controller to manage editing details of a calculator menu -- its title, names and functions.
 
  Version: 1.0

 */

@class Calculator, Menu, EditingTableViewCell;

@interface MenuDetailViewController : UITableViewController {
    @private
        Calculator *calculator;
        Menu *menu;
        
        EditingTableViewCell *editingTableViewCell;
}

@property (nonatomic, retain) Calculator *calculator;
@property (nonatomic, retain) Menu *menu;

@property (nonatomic, assign) IBOutlet EditingTableViewCell *editingTableViewCell;

@end
