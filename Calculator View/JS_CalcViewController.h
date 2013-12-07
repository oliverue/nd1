//
//  JS_CalcViewController.h
//  JS Calc
//
//  Created by Oliver Unter Ecker on 9/8/09.
//  Copyright Naive Design 2009. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <Foundation/Foundation.h>
#import <MessageUI/MessageUI.h>
#import <MessageUI/MFMailComposeViewController.h>
#import <AudioToolbox/AudioToolbox.h>

@class Calculator;
@class UserDataCategory;

@protocol TouchesNotificationReceiving
- (BOOL)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event in:(id)sender;
@end

@interface TouchNotifyingTextField: UITextField {
}
@end

@interface TouchNotifyingTextView: UITextView {
}
@end

@interface TouchNotifyingWebView: UIWebView {
}
@end


@interface JS_CalcViewController : UIViewController <UIWebViewDelegate, TouchesNotificationReceiving, UITextFieldDelegate, UITextViewDelegate, UIPickerViewDelegate, UIPickerViewDataSource, MFMailComposeViewControllerDelegate> {
    IBOutlet UITextView *inputTextView;
    IBOutlet UITextField *inputTextField;
    IBOutlet TouchNotifyingWebView *webView;
    IBOutlet UIView *keysView;
    IBOutlet UIView *menusView;
    IBOutlet UIView *menusView2;
	IBOutlet UILabel *angleModeLabel;
	IBOutlet UILabel *vectorDisplayModeLabel;
	IBOutlet UILabel *dataCategoryLabel;
	IBOutlet UILabel *recordingLabel;
	IBOutlet UIButton *displaySwitchButton;
	IBOutlet UIButton *modeSwitchButton;
  @private
	NSManagedObjectContext *managedObjectContext;
	Calculator *calculator;
	UserDataCategory *userDataCategory;

	SystemSoundID keyClickSoundID;
	UIButton *alternateButton, *menuButton, *deleteButton, *spaceButton, *calcButton, *dropButton;
	NSString *calcButtonString, *dropButtonString;
	BOOL deleteButtonIsShowingUndo, calcButtonIsShowingEnter;
	UITextField *inputTextUI;
    UIView *inputAccessoryView;
	NSMutableArray *softKeys;
	NSMutableDictionary *uiObjects;
	NSMutableDictionary *uiObjectInfo;
	NSUInteger keyLevel;
	NSString *skinName;
	NSString *currentMenuTitle;
	NSString *previousMenuTitle;
	NSInteger currentMenuStartIndex;
	BOOL hasLastShownCategories;
	NSString *lastPushedEditLine;
	NSCharacterSet *numberFormattingCharacterSet;
	NSCharacterSet *operatorCharacterSet;
	BOOL webViewIsExpanded;
	BOOL didToggleTabBarOnLastInputViewChange;
	BOOL isShowingGraphics;
	BOOL isInputTextViewSupersized;
}

@property (nonatomic, retain) NSManagedObjectContext *managedObjectContext;
@property (nonatomic, retain) Calculator *calculator;
@property (nonatomic, retain) UserDataCategory *userDataCategory;
@property (nonatomic, retain) NSString *currentMenuTitle;
@property (nonatomic, retain) NSString *previousMenuTitle;
@property (nonatomic, retain) NSString *lastPushedEditLine;

- (void)showQuickTourReminder;
- (void)morphInputUI;
- (void)showUIForCurrentInputMode;
- (void)showTabBar:(NSNumber *)shouldShow;
- (void)showMenus:(NSNumber *)shouldShow;
- (void)toggleTabBar;
- (IBAction)resizeWebUI:(BOOL)animated;
- (IBAction)toggleInputMode:(id)sender;

@end
