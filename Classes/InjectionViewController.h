//
//  InjectionViewController.h
//  Calculate
//
//  Created by Oliver Unter Ecker on 10/12/09.
//  Copyright 2009 Naive Design. All rights reserved.
//

#import <UIKit/UIKit.h>

@class Calculator;

@interface InjectionViewController : UIViewController {
@private
	Calculator *calculator;
	UITextView *notesText;
}

@property (nonatomic, retain) Calculator *calculator;
@property (nonatomic, retain) IBOutlet UITextView *notesText;
@property (nonatomic, retain) IBOutlet UILabel *nameLabel;

@end
