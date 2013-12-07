 
 /*
     File: UserDataCategoryListTableViewController.h
 Abstract: Table view controller to manage an editable table view that displays a list of user data categories.
 UserDataCategorys are displayed in a custom table view cell.
 
  Version: 1.0
  
 */

#import "UserDataCategoryAddViewController.h"

@class UserDataCategory;
@class UserDataCategoryTableViewCell;

@interface UserDataCategoryListTableViewController : UITableViewController <UserDataCategoryAddDelegate, NSFetchedResultsControllerDelegate> {
    @private
        NSFetchedResultsController *fetchedResultsController;
        NSManagedObjectContext *managedObjectContext;
}

@property (nonatomic, retain) NSFetchedResultsController *fetchedResultsController;
@property (nonatomic, retain) NSManagedObjectContext *managedObjectContext;

- (void)showUserDataCategory:(UserDataCategory *)userDataCategory animated:(BOOL)animated;
- (void)configureCell:(UITableViewCell *)cell atIndexPath:(NSIndexPath *)indexPath;

@end
