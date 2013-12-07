
/*
     File: DataSharingController.h
 Abstract: View controller to manage a text view to allow the user to edit notes for a calculator.
 
  Version: 1.0
  
 */

#import <UIKit/UIKit.h>
#import <MessageUI/MessageUI.h>
#import <MessageUI/MFMailComposeViewController.h>

@class Calculator;
@class UserDataCategory;

@interface DataSharingController : UIViewController <MFMailComposeViewControllerDelegate>
{
	Calculator *calculator;
	UserDataCategory *userDataCategory;
    BOOL doesManageUserData;
	NSMutableData *receivedData;
	NSMutableArray *downloadQueue;
	BOOL isDownloading;
	NSString *alternativeDownloadURLString;

	IBOutlet UITextField *URLTextField;
	IBOutlet UILabel *publicLabel;
	IBOutlet UILabel *customURLLabel;
	IBOutlet UIButton *emailButton;
	IBOutlet UIButton *uploadButton;
	IBOutlet UIButton *downloadButton;
	IBOutlet UILabel *lastUploadLabel;
	IBOutlet UISwitch *visibleToPublicSwitch;
	IBOutlet UISwitch *customURLSwitch;
	IBOutlet UIButton *downloadAssetsButton;
	IBOutlet UIButton *directConnectButton;

	IBOutlet UIButton *restoreButton;
	IBOutlet UILabel *restoreLabel;
}

@property (nonatomic, retain) Calculator *calculator;
@property (nonatomic) BOOL doesManageUserData;
@property (nonatomic, retain) UserDataCategory *userDataCategory;
@property (nonatomic, retain) IBOutlet UITextField *URLTextField;
@property (nonatomic, retain) IBOutlet UILabel *lastUploadLabel;

- (IBAction)email;
- (IBAction)upload;
- (IBAction)download;
- (IBAction)downloadAssets;
- (IBAction)connect;
- (IBAction)restore;
- (IBAction)toggleVisibleToAll:(UISwitch *)sender;
- (IBAction)toggleCustomURL:(UISwitch *)sender;

- (BOOL)recreateCalculatorWithJSONString:(NSString *)JSONString;
- (BOOL)recreateCategoryWithJSONString:(NSString *)JSONString;

// download service
- (BOOL)addToDownloadQueue:(NSString *)URLString; // expected to be a properly percent-encoded URL string, or else will return false
- (BOOL)hasMoreDownloads; // can call optionally to see if there are pending downloads
- (void)serviceDownloadQueue; // call to start downloads, after adding
	
@end
