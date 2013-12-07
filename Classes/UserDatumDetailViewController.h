
/*
     File: UserDatumDetailViewController.h
 Abstract: Table view controller to manage editing details of a user datum -- its name and data.
 
  Version: 1.0

 */

@class UserDataCategory, UserDatum, EditingTableViewCell;

@interface UserDatumDetailViewController : UITableViewController {
    @private
        UserDataCategory *userDataCategory;
        UserDatum *datum;
        
        EditingTableViewCell *editingTableViewCell;
}

@property (nonatomic, retain) UserDataCategory *userDataCategory;
@property (nonatomic, retain) UserDatum *datum;

@property (nonatomic, assign) IBOutlet EditingTableViewCell *editingTableViewCell;

@end
