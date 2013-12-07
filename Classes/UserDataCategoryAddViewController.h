
/*
     File: UserDataCategoryAddViewController.h
 Abstract: View controller to allow the user to add a new userDataCategory and choose its picture using the image picker.
 If the user taps Save, the userDataCategory detail view controller is pushed so that the user can edit the new item.
 
  Version: 1.0
 
 */

@protocol UserDataCategoryAddDelegate;
@class UserDataCategory;

@interface UserDataCategoryAddViewController : UIViewController <UITextFieldDelegate> {
    @private
        UserDataCategory *userDataCategory;
        UITextField *nameTextField;
        id <UserDataCategoryAddDelegate> delegate;
}

@property(nonatomic, retain) UserDataCategory *userDataCategory;
@property(nonatomic, retain) IBOutlet UITextField *nameTextField;
@property(nonatomic, assign) id <UserDataCategoryAddDelegate> delegate;

- (void)save;
- (void)cancel;

@end


@protocol UserDataCategoryAddDelegate <NSObject>
// userDataCategory == nil on cancel
- (void)userDataCategoryAddViewController:(UserDataCategoryAddViewController *)userDataCategoryAddViewController didAddUserDataCategory:(UserDataCategory *)userDataCategory;

@end
