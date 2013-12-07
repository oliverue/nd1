 
 /*
     File: DataDownloadsTableViewController.h
 Abstract: Table view controller to manage list of user data downloads.
 
  Version: 1.0
  
 */

#import "UserDataCategoryAddViewController.h"

@interface DataDownloadsTableViewController : UITableViewController {
    @private
        NSManagedObjectContext *managedObjectContext;
        BOOL doesManageUserData;
		NSMutableArray *updates;
		NSMutableArray *downloadables;
}

@property (nonatomic, retain) NSManagedObjectContext *managedObjectContext;
@property (nonatomic) BOOL doesManageUserData;

- (void)configureCell:(UITableViewCell *)cell atIndexPath:(NSIndexPath *)indexPath;
- (BOOL)updateDownloadables;
- (BOOL)installFolder:(NSString *)folderName;

@end
