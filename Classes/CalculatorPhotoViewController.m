
/*
     File: CalculatorPhotoViewController.m
 Abstract: View controller to manage a view to display a calculator's photo.
 The image view is created programmatically.
 
  Version: 1.0
  
 */

#import "CalculatorPhotoViewController.h"

#import "Calculator.h"

@implementation CalculatorPhotoViewController

@synthesize calculator;
@synthesize imageView;

- (void)loadView {
	self.title = NSLocalizedString(@"Photo", nil);

    imageView = [[UIImageView alloc] initWithFrame:[UIScreen mainScreen].applicationFrame];
    imageView.autoresizingMask = UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleWidth;
    imageView.contentMode = UIViewContentModeScaleAspectFit;
    imageView.backgroundColor = [UIColor blackColor];
    
    self.view = imageView;
}


- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    imageView.image = [calculator.image valueForKey:@"image"];
}


- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
    return (interfaceOrientation != UIInterfaceOrientationPortraitUpsideDown);
}


- (void)dealloc {
    [imageView release];
    [calculator release];
    [super dealloc];
}


@end
