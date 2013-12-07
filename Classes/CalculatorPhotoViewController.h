
/*
     File: CalculatorPhotoViewController.h
 Abstract: View controller to manage a view to display a calculator's photo.
 The image view is created programmatically.
 
  Version: 1.0
 
 */

@class Calculator;

@interface CalculatorPhotoViewController : UIViewController {
    @private
        Calculator *calculator;
        UIImageView *imageView;
}

@property(nonatomic, retain) Calculator *calculator;
@property(nonatomic, retain) UIImageView *imageView;

@end
