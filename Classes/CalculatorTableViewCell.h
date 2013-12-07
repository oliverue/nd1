
/*
     File: CalculatorTableViewCell.h
 Abstract: A table view cell that displays information about a Calculator.  It uses individual subviews of its content view to show the name, picture, description, and preparation time for each calculator.  If the table view switches to editing mode, the cell reformats itself to move the preparation time off-screen, and resizes the name and description fields accordingly.
 
  Version: 1.0
  
 */

#import "Calculator.h"

@interface CalculatorTableViewCell : UITableViewCell {
    Calculator *calculator;
    
    UIImageView *imageView;
    UILabel *nameLabel;
    UILabel *overviewLabel;
    UILabel *typeLabel;
}

@property (nonatomic, retain) Calculator *calculator;

@property (nonatomic, retain) UIImageView *imageView;
@property (nonatomic, retain) UILabel *nameLabel;
@property (nonatomic, retain) UILabel *overviewLabel;
@property (nonatomic, retain) UILabel *typeLabel;

@end
