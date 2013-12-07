
/*
     File: UserDataCategoryTableViewCell.h
 Abstract: A table view cell that displays information about a UserDataCategory.
 
  Version: 1.0
  
 */

#import "UserDataCategory.h"

@interface UserDataCategoryTableViewCell : UITableViewCell {
    UserDataCategory *userDataCategory;
    
    UILabel *nameLabel;
    UILabel *overviewLabel;
    UILabel *typeLabel;
}

@property (nonatomic, retain) UserDataCategory *userDataCategory;

@property (nonatomic, retain) UILabel *nameLabel;
@property (nonatomic, retain) UILabel *overviewLabel;
@property (nonatomic, retain) UILabel *typeLabel;

@end
