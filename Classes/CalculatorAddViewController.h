
/*
     File: CalculatorAddViewController.h
 Abstract: View controller to allow the user to add a new calculator and choose its picture using the image picker.
 If the user taps Save, the calculator detail view controller is pushed so that the user can edit the new item.
 
  Version: 1.0
 
 */

@protocol CalculatorAddDelegate;
@class Calculator;

@interface CalculatorAddViewController : UIViewController <UITextFieldDelegate> {
    @private
        Calculator *calculator;
        UITextField *nameTextField;
        id <CalculatorAddDelegate> delegate;
}

@property(nonatomic, retain) Calculator *calculator;
@property(nonatomic, retain) IBOutlet UITextField *nameTextField;
@property(nonatomic, assign) id <CalculatorAddDelegate> delegate;

- (void)save;
- (void)cancel;

@end


@protocol CalculatorAddDelegate <NSObject>
// calculator == nil on cancel
- (void)calculatorAddViewController:(CalculatorAddViewController *)calculatorAddViewController didAddCalculator:(Calculator *)calculator;

@end
