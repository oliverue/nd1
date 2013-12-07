
/*
     File: UserDataCategoryDetailViewController.h
 Abstract: Table view controller to manage an editable table view that displays information about a user data category.
 The table view uses different cell types for different row types.
 
  Version: 1.0

 */

@class UserDataCategory;

@interface UserDataCategoryDetailViewController : UITableViewController <UINavigationControllerDelegate, UITextFieldDelegate> {
    @private
        UserDataCategory *userDataCategory;
		NSMutableArray *data;
        
        UIView *tableHeaderView;    
        UITextField *nameTextField;
        UITextField *overviewTextField;
		UILabel *nEntriesTextLabel;
        UILabel *nEntriesLabel;
}

@property (nonatomic, retain) UserDataCategory *userDataCategory;
@property (nonatomic, retain) NSMutableArray *data;

@property (nonatomic, retain) IBOutlet UIView *tableHeaderView;
@property (nonatomic, retain) IBOutlet UITextField *nameTextField;
@property (nonatomic, retain) IBOutlet UITextField *overviewTextField;
@property (nonatomic, retain) IBOutlet UILabel *nEntriesTextLabel;
@property (nonatomic, retain) IBOutlet UILabel *nEntriesLabel;

@end
