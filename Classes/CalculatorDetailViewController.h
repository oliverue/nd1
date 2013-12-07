
/*
     File: CalculatorDetailViewController.h
 Abstract: Table view controller to manage an editable table view that displays information about a calculator.
 The table view uses different cell types for different row types.
 
  Version: 1.0

 */

@class Calculator;

@interface CalculatorDetailViewController : UITableViewController <UINavigationControllerDelegate, UIImagePickerControllerDelegate, UITextFieldDelegate> {
    @private
        Calculator *calculator;
		NSMutableArray *keys;
		NSMutableArray *menus;
        
        UIView *tableHeaderView;    
        UIButton *photoButton;
        UITextField *nameTextField;
        UITextField *overviewTextField;
        UILabel *nfunctionsLabel;
		UILabel *nfunctionsTextLabel;
}

@property (nonatomic, retain) Calculator *calculator;
@property (nonatomic, retain) NSMutableArray *keys;
@property (nonatomic, retain) NSMutableArray *menus;

@property (nonatomic, retain) IBOutlet UIView *tableHeaderView;
@property (nonatomic, retain) IBOutlet UIButton *photoButton;
@property (nonatomic, retain) IBOutlet UITextField *nameTextField;
@property (nonatomic, retain) IBOutlet UITextField *overviewTextField;
@property (nonatomic, retain) IBOutlet UILabel *nfunctionsLabel;
@property (nonatomic, retain) IBOutlet UILabel *nfunctionsTextLabel;

- (IBAction)photoTapped;

@end
