
/*
     File: DataSharingController.m
 Abstract: View controller to manage a text view to allow the user to edit notes for a calculator.
 
  Version: 1.0
  
 */

#import "JSON.h"

#import "Calculator.h"
#import "Key.h"
#import "Menu.h"
#import "Type.h"
#import "Orientation.h"
#import "Skin.h"

#import "UserDataCategory.h"
#import "UserDatum.h"

#import "CalculateAppDelegate.h"

#import "DataSharingController.h"

#define DEFAULT_UPLOAD_PATH @"http://naivedesign.com/upload.php"

@implementation DataSharingController

@synthesize calculator;
@synthesize userDataCategory;
@synthesize doesManageUserData;
@synthesize URLTextField;
@synthesize lastUploadLabel;


- (id)init {
    if ((self = [super init])) {
        userDataCategory = nil;
        doesManageUserData = YES;
    }

    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    UINavigationItem *navigationItem = self.navigationItem;
    navigationItem.title = NSLocalizedString(@"Sharing", nil);
	receivedData = nil;
	downloadQueue = [[NSMutableArray alloc] initWithCapacity:10];
	isDownloading = NO;
	alternativeDownloadURLString = nil;
	publicLabel.text = NSLocalizedString(@"VisibleToThePublic", nil);
	customURLLabel.text = NSLocalizedString(@"CustomURL", nil);
	[emailButton setTitle:NSLocalizedString(@"Email", nil) forState:UIControlStateNormal];
	[uploadButton setTitle:NSLocalizedString(@"Upload", nil) forState:UIControlStateNormal];
	[downloadButton setTitle:NSLocalizedString(@"Download", nil) forState:UIControlStateNormal];
	[downloadAssetsButton setTitle:NSLocalizedString(@"DownloadAssets", nil) forState:UIControlStateNormal];
	[directConnectButton setTitle:NSLocalizedString(@"DirectConnect", nil) forState:UIControlStateNormal];
	[restoreButton setTitle:NSLocalizedString(@"RestoreCalculator", nil) forState:UIControlStateNormal];
	restoreLabel.text = NSLocalizedString(@"RestoreWarning", nil);
	
	NSDate *dateToShow = (userDataCategory ? userDataCategory.uploadDate : calculator.uploadDate);
	if (dateToShow) {
		NSDateFormatter *dateFormatter = [[[NSDateFormatter alloc] init] autorelease];
		[dateFormatter setDateFormat:@"EEE MMMM d, yyyy, HH:mm"];
		lastUploadLabel.text = [NSString stringWithFormat:@"%@ %@", NSLocalizedString(@"LastUploadedOn", nil), [dateFormatter stringFromDate:dateToShow]];
	}
	
	if (userDataCategory)
		visibleToPublicSwitch.on = [userDataCategory.visibleToPublic boolValue];
}

- (void)viewDidUnload {
	if (downloadQueue)
		[downloadQueue release];
	downloadQueue = nil;
	if (alternativeDownloadURLString)
		[alternativeDownloadURLString release];
	self.URLTextField = nil;
	self.lastUploadLabel = nil;
	[super viewDidUnload];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];

    // Update the views appropriately
////    nameLabel.text = [NSString stringWithFormat:@"%@ \"%@\" %@", NSLocalizedString(@"Share", nil), NSLocalizedString(calculator ? calculator.name : userDataCategory.name, nil), NSLocalizedString(@"via", nil)];
    URLTextField.text = [[NSUserDefaults standardUserDefaults] stringForKey:@"uploadURL_preference"];
	if (userDataCategory && [userDataCategory.useCustomURL boolValue] && URLTextField.text && URLTextField.text.length) {
		customURLSwitch.on = true;
		[self toggleCustomURL:customURLSwitch];
	}

	if (userDataCategory) {
		BOOL gotAssets = NO;
		for (UserDatum *datum in [userDataCategory.data allObjects]) {
			if ([datum.data hasPrefix:@"http:"]) {
				gotAssets = YES;
				break;
			}
		}
		if (gotAssets) {
			downloadAssetsButton.enabled = true;
			downloadAssetsButton.hidden = false;
		}
	}
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
    return (interfaceOrientation != UIInterfaceOrientationPortraitUpsideDown);
}

#pragma mark -
#pragma mark JSON factories

- (NSString *)JSONStringForCalculator {
	NSMutableString *JSONstring = [NSMutableString stringWithString:@"{ \n"];
	if (calculator) {
		// overview
		[JSONstring appendString:[NSString stringWithFormat:@"\"overview\": %@,\n", (calculator.overview ? [calculator.overview JSONFragment] : @"null")]];
		// type
		[JSONstring appendString:[NSString stringWithFormat:@"\"type\": \"%@\",\n", calculator.type.name]];
		// orientation
		[JSONstring appendString:[NSString stringWithFormat:@"\"orientation\": \"%@\",\n", calculator.orientation.name]];
		// skin
		[JSONstring appendString:[NSString stringWithFormat:@"\"skin\": \"%@\",\n", calculator.skin.name]];

		// set up sorting
		NSSortDescriptor *sortDescriptor = [[NSSortDescriptor alloc] initWithKey:@"displayOrder" ascending:YES];
		NSArray *sortDescriptors = [[NSArray alloc] initWithObjects:&sortDescriptor count:1];

		{ // keys array
		[JSONstring appendString:@"\"keys\": [ \n"];
		NSMutableArray *arr = [[calculator.keys allObjects] mutableCopy];
		[arr sortUsingDescriptors:sortDescriptors]; // sort array by displayOrder
		// transcribe to JSON
		for (NSUInteger i=0; i<[arr count]; i++) {
			Key *key = [arr objectAtIndex:i];
			
			NSDictionary *dict = [NSDictionary dictionaryWithObjectsAndKeys:
								  key.name ? key.name : @"", @"name",
								  key.function ? key.function : @"", @"function",
								  nil];
			[JSONstring appendString:[dict JSONRepresentation]];
			if (i < [arr count]-1)
				[JSONstring appendString:@",\n"];
		}		
		[arr release];
		[JSONstring appendString:@" ],\n"];
		}
		
		{ // menus array
		[JSONstring appendString:@"\"menus\": [ \n"];
		NSMutableArray *arr = [[calculator.menus allObjects] mutableCopy];
		[arr sortUsingDescriptors:sortDescriptors]; // sort array by displayOrder
		// transcribe to JSON
		for (NSUInteger i=0; i<[arr count]; i++) {
			Menu *menu = [arr objectAtIndex:i];
			
			NSDictionary *dict = [NSDictionary dictionaryWithObjectsAndKeys:
								  menu.title ? menu.title : @"", @"title",
								  menu.name ? menu.name : @"", @"names",
								  menu.function ? menu.function : @"", @"functions",
								  nil];
			[JSONstring appendString:[dict JSONRepresentation]];
			if (i < [arr count]-1)
				[JSONstring appendString:@",\n"];
		}		
		[arr release];
		[JSONstring appendString:@" ],\n"];
		}
		
		// clean up sorting
		[sortDescriptor release];
		[sortDescriptors release];

		// notes
		[JSONstring appendString:[NSString stringWithFormat:@"\"notes\": %@,\n", (calculator.notes ? [calculator.notes JSONFragment] : @"null")]];
		
		// injection
		if (calculator.injection && calculator.injection.length)
			[JSONstring appendString:[NSString stringWithFormat:@"\"injection\": %@,\n", [calculator.injection JSONFragment]]];
		
		// dates
		calculator.uploadDate = [NSDate date];
		[JSONstring appendString:[NSString stringWithFormat:@"\"uploadDate\": \"%@\"%@\n", [calculator.uploadDate description], (calculator.downloadDate ? @"," : @"")]];
		if (calculator.downloadDate)
			[JSONstring appendString:[NSString stringWithFormat:@"\"downloadDate\": \"%@\"\n", [calculator.downloadDate description]]];
	}
	[JSONstring appendString:@" }\n"];
	//	NSLog(@"JSON: %@", JSONstring);
	
	return JSONstring;
}

- (NSString *)JSONStringForUserData {
	NSMutableString *JSONstring = [NSMutableString stringWithString:@"{ \n"];
	if (userDataCategory) {
		// overview
		[JSONstring appendString:[NSString stringWithFormat:@"\"overview\": %@,\n", userDataCategory.overview ? [userDataCategory.overview JSONFragment] : @"null"]];
		
		// data array

		[JSONstring appendString:@"\"data\": [ \n"];
		NSMutableArray *arr = [[userDataCategory.data allObjects] mutableCopy];
		
		// sort array by displayOrder
		NSSortDescriptor *sortDescriptor = [[NSSortDescriptor alloc] initWithKey:@"displayOrder" ascending:YES];
		NSArray *sortDescriptors = [[NSArray alloc] initWithObjects:&sortDescriptor count:1];
		[arr sortUsingDescriptors:sortDescriptors];
		[sortDescriptor release];
		[sortDescriptors release];

		// transcribe to JSON
		for (NSUInteger i=0; i<[arr count]; i++) {
			UserDatum *datum = [arr objectAtIndex:i];

			// determine data: empty string if null, object value in case of objects, original data otherwise
			id data = @"";
			if (datum.data) {
				data = datum.data; // sure to be a string (of a string, array, object, number)
				if ([data hasPrefix:@"{"]) { // an object/dictionary
					id val = [data JSONValue];
					if (val)
						data = val;
				}
			}
			
			NSDictionary *dict = [NSDictionary dictionaryWithObjectsAndKeys:
								  datum.name ? datum.name : @"", @"name",
								  data, @"data",
								  datum.comment ? datum.comment : @"", @"comment",
								  nil];
			[JSONstring appendString:[dict JSONRepresentation]];
			if (i < [arr count]-1)
				[JSONstring appendString:@",\n"];
/*				
			NSString *data = datum.data;///[datum.data stringByReplacingOccurrencesOfString:@"\\" withString:@"\\\\"]; // escape escapes
///			data = [data stringByReplacingOccurrencesOfString:@"\"" withString:@"\\\""]; // escape double quotes
			data = [data JSONFragment];
			[JSONstring appendFormat:@"{ \"name\": \"%@\", \"data\": %@, \"comment\": \"%@\" }%@\n", [datum.name stringByReplacingOccurrencesOfString:@"\"" withString:@"\\\""], data, [datum.comment stringByReplacingOccurrencesOfString:@"\"" withString:@"\\\""], (i == [arr count]-1) ? @"" : @","];
///			BOOL dataIsString = YES; //([datum.data characterAtIndex:0] != bracket && [datum.data characterAtIndex:0] != curlyBrace);
///			[JSON appendFormat:@"{ \"name\": \"%@\", \"data\": %@%@%@, \"comment\": \"%@\" }%@\n", [datum.name stringByReplacingOccurrencesOfString:@"\"" withString:@"\\\""], dataIsString ? @"\"" : @"", dataIsString ? [datum.data stringByReplacingOccurrencesOfString:@"\"" withString:@"\\\""] : datum.data, dataIsString ? @"\"" : @"", [datum.comment stringByReplacingOccurrencesOfString:@"\"" withString:@"\\\""], (i == [arr count]-1) ? @"" : @","];
 */
		}
		
		[arr release];
		[JSONstring appendString:@" ],\n"];

		// notes
		[JSONstring appendString:[NSString stringWithFormat:@"\"notes\": %@,\n", userDataCategory.notes ? [userDataCategory.notes JSONFragment] : @"null"]];

		// dates
		userDataCategory.uploadDate = [NSDate date];
		[JSONstring appendString:[NSString stringWithFormat:@"\"uploadDate\": \"%@\"%@\n", [userDataCategory.uploadDate description], (userDataCategory.downloadDate ? @"," : @"")]];
		if (userDataCategory.downloadDate)
			[JSONstring appendString:[NSString stringWithFormat:@"\"downloadDate\": \"%@\"\n", [userDataCategory.downloadDate description]]];
	}
	[JSONstring appendString:@" }\n"];
//	NSLog(@"JSON: %@", JSONstring);
	
	return JSONstring;
}

#pragma mark -
#pragma mark Compose Mail

-(void)displayComposerSheet {
	NSString *objectName = NSLocalizedString(calculator ? calculator.name : userDataCategory.name, nil);

    MFMailComposeViewController *picker = [[MFMailComposeViewController alloc] init];
    picker.mailComposeDelegate = self;

    [picker setSubject:[NSString stringWithFormat:@"[%@] %@",
#ifdef IS_ND1
#ifdef IS_ALSO_ND0
						@"ND0",
#else
						@"ND1",
#endif
#else
						@"Calculate",
#endif
						objectName]];
	NSString *emailAddress = [[NSUserDefaults standardUserDefaults] stringForKey:@"email_preference"]; /// todo: provide a default email address
	if (emailAddress && emailAddress.length)
		[picker setToRecipients:[NSArray arrayWithObject:emailAddress]];
    
    // optionally, attach any graph image
//    NSString *path = [[NSBundle mainBundle] pathForResource:@"rainy" ofType:@"png"];
//    NSData *myData = [NSData dataWithContentsOfFile:path];
//    [picker addAttachmentData:myData mimeType:@"image/png" fileName:@"rainy"];
    
    NSString *emailBody = [NSString stringWithFormat:@"%@ %@.\n", NSLocalizedString(@"EmailText", nil), objectName];

	// produce and add attachment containing data
	NSString *JSONstring = [self JSONStringForUserData];
	[picker addAttachmentData:[JSONstring dataUsingEncoding:NSUTF8StringEncoding] mimeType:@"application/json" fileName:objectName];

    [picker setMessageBody:emailBody isHTML:NO];
    
    [self presentViewController:picker animated:YES completion:nil];
    [picker release];
}

- (void)mailComposeController:(MFMailComposeViewController*)controller didFinishWithResult:(MFMailComposeResult)result error:(NSError*)error {    
/*
    message.hidden = NO;
    switch (result) {
        case MFMailComposeResultCancelled:
            message.text = @"Result: canceled";
            break;
        case MFMailComposeResultSaved:
            message.text = @"Result: saved";
            break;
        case MFMailComposeResultSent:
            message.text = @"Result: sent";
            break;
        case MFMailComposeResultFailed:
            message.text = @"Result: failed";
            break;
        default:
            message.text = @"Result: not sent";
            break;
    } */
    [self dismissViewControllerAnimated:YES completion:nil];
}

/* can use this if support of <OS 3.0 is required
-(void)launchMailAppOnDevice {
    NSString *recipients = @"mailto:first@example.com?cc=second@example.com,third@example.com&subject=Hello from California!";
    NSString *body = @"&body=It is raining in sunny California!";
    
    NSString *email = [NSString stringWithFormat:@"%@%@", recipients, body];
    email = [email stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
    
    [[UIApplication sharedApplication] openURL:[NSURL URLWithString:email]];
}
*/
-(IBAction)email {
    Class mailClass = (NSClassFromString(@"MFMailComposeViewController"));
    if (mailClass != nil && [mailClass canSendMail])
		[self displayComposerSheet];
///	else
///		[self launchMailAppOnDevice];
}

#pragma mark -
#pragma mark User prompts

- (void)reportError:(NSString *)description for:(NSString *)failingURLString {
	NSString *message = ((failingURLString && failingURLString.length && [failingURLString rangeOfString:@"naivedesign.com"].length == 0)
						 ? [NSString stringWithFormat:@"%@ (%@)", description, failingURLString]
						 : [NSString stringWithFormat:@"%@", description] );
	UIAlertView *alert = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"ErrorOccurred", nil) message:message delegate:nil cancelButtonTitle:nil otherButtonTitles:@"OK", nil];
	[alert show];
	[alert release];
}

- (void)alertView:(UIAlertView *)alertView didDismissWithButtonIndex:(NSInteger)buttonIndex {
	// this is only ever called by the alert view launched in -connectionDidFinishLoading
	if (buttonIndex == 1 && alternativeDownloadURLString) {
		// NSLog(@"Trying to download URL: %@", alternativeDownloadURLString);
		[self addToDownloadQueue:alternativeDownloadURLString];
		[self serviceDownloadQueue];
	}
}

#pragma mark -
#pragma mark URL loading delegate

- (void)connection:(NSURLConnection *)connection didReceiveResponse:(NSURLResponse *)response {
	[receivedData setLength:0];
	
	NSInteger statusCode = [(NSHTTPURLResponse *)response statusCode];
	if (statusCode != 200)
		[self reportError:(statusCode == 404 ? NSLocalizedString(@"ResourceNotFound", nil) : [NSString stringWithFormat:@"HTTP status code: %ld", (long)statusCode]) for:[[response URL] absoluteString]];
}

- (void)connection:(NSURLConnection *)connection didReceiveData:(NSData *)data {
	[receivedData appendData:data];
}

- (void)connectionDidFinishLoading:(NSURLConnection *)connection {
	[UIApplication sharedApplication].networkActivityIndicatorVisible = NO;

	NSString *responseString = nil;

	if (isDownloading) {
		NSString *downloadAssetsButtonTitle = NSLocalizedString(@"DownloadAssets", nil);
		BOOL isAnAsset = (downloadAssetsButton && ![[downloadAssetsButton currentTitle] isEqualToString:downloadAssetsButtonTitle]); // button is saying "Cancel..." if this is an asset download
		if (isAnAsset) {
			BOOL pageNotFound = NO;
			if (receivedData && [receivedData length] < 600) {
				NSString *testString = [[NSString alloc] initWithData:receivedData encoding:NSUTF8StringEncoding];
				pageNotFound = ([testString rangeOfString:@"Page Not Found"].length > 0);
				[testString release];
			}
			if (!pageNotFound && receivedData && [receivedData length]) {
				NSString *URLString = [downloadQueue objectAtIndex:0];
				NSString *localPath = [[(CalculateAppDelegate *)[[UIApplication sharedApplication] delegate] applicationDocumentsDirectory] stringByAppendingPathComponent:[URLString lastPathComponent]];
				[receivedData writeToFile:localPath atomically:NO];
			}
		}
		else { // JSON data for calculator or user category
			NSString *JSONString = [[NSString alloc] initWithData:receivedData encoding:NSUTF8StringEncoding];
			if ([JSONString rangeOfString:@"Page Not Found"].length > 0) {
				// was: [self reportError:NSLocalizedString(@"PageNotFound", nil) for:@""]; // no need to report again, because 404 was already reported above
				NSString *failingURLString = [downloadQueue objectAtIndex:0];
				// if failure is on naivedesign.com offer user to try for public version of file
				if ([failingURLString rangeOfString:@"naivedesign.com/uploads"].length > 0) {
					NSRange r = [failingURLString rangeOfString:@"UserData"];
					if (r.length) {
						UIAlertView *alert = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"AlternativeDownload", nil) message:NSLocalizedString(@"TryPublic", nil) delegate:self cancelButtonTitle:NSLocalizedString(@"No", nil) otherButtonTitles:NSLocalizedString(@"Yes", nil), nil];
						[alert show];
						[alert release];
						alternativeDownloadURLString = [[NSString alloc] initWithFormat:@"http://naivedesign.com/public/%@", [failingURLString substringFromIndex:r.location]];
						// NSLog(@"Alternative URL: %@", alternativeDownloadURLString);
					}
				}
			}
			else {
				if (userDataCategory) {
					if (![self recreateCategoryWithJSONString:JSONString])
						[self reportError:NSLocalizedString(@"BadJSON", nil) for:@""];
				}
				else {
					if (![self recreateCalculatorWithJSONString:JSONString])
						[self reportError:NSLocalizedString(@"BadJSON", nil) for:@""];
				}
			}
			[JSONString release];
		}

		// cleanup and/or move to next download
		[receivedData release]; receivedData = nil;
		[downloadQueue removeObjectAtIndex:0];
		if ([self hasMoreDownloads])
			[self serviceDownloadQueue];
		else { // completely done downloading
			isDownloading = NO;
			if (isAnAsset)
				[downloadAssetsButton setTitle:downloadAssetsButtonTitle forState:UIControlStateNormal]; // reset button title
		}
		
	}
	else { // is uploading
		responseString = [[NSString alloc] initWithData:receivedData encoding:NSASCIIStringEncoding];
		[receivedData release]; receivedData = nil;
		
		if ([responseString isEqualToString:@"ok"]) {
			NSDateFormatter *dateFormatter = [[[NSDateFormatter alloc] init] autorelease];
			[dateFormatter setDateFormat:@"EEE MMMM d, yyyy, HH:mm"];
			lastUploadLabel.text = [NSString stringWithFormat:@"%@ %@", NSLocalizedString(@"LastUploadedOn", nil), [dateFormatter stringFromDate:(userDataCategory ? userDataCategory.uploadDate : calculator.uploadDate)]];
		}
		else if ([responseString length])
			[self reportError:[@"server error response: " stringByAppendingString:responseString] for:@""]; // todo: serverURL
	}
	
	[responseString release];
	[connection release];
}

- (void)connection:(NSURLConnection *)connection didFailWithError:(NSError *)error {
	[UIApplication sharedApplication].networkActivityIndicatorVisible = NO;

	[connection release];
	[receivedData release]; receivedData = nil;
	
	[self reportError:[error localizedDescription] for:[[error userInfo] objectForKey:NSURLErrorFailingURLStringErrorKey]];
}

#pragma mark -
#pragma mark Connect

-(IBAction)connect {
}

#pragma mark -
#pragma mark Restore

- (IBAction)restore {
	NSString *baseURL = [DEFAULT_UPLOAD_PATH stringByDeletingLastPathComponent];
	NSString *URLString = [NSString stringWithFormat:@"%@/public/Calculator_%@.txt", baseURL, calculator.name];
	
	[self addToDownloadQueue:[URLString stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding]];
	[self serviceDownloadQueue];
}

#pragma mark -
#pragma mark TextField delegation

- (BOOL)textFieldShouldEndEditing:(UITextField *)textField {
	if (textField == URLTextField && URLTextField.text && URLTextField.text.length)
		[[NSUserDefaults standardUserDefaults] setObject:URLTextField.text forKey:@"uploadURL_preference"];
	return YES;
}

- (BOOL)textFieldShouldReturn:(UITextField *)textField {
	[textField resignFirstResponder];
	return YES;
}

#pragma mark -
#pragma mark Upload

- (IBAction)toggleVisibleToAll:(UISwitch *)sender {
	if (sender.on && customURLSwitch.on) {
		customURLSwitch.on = false;
		[self toggleCustomURL:customURLSwitch];
	}
	if (userDataCategory)
		userDataCategory.visibleToPublic = [NSNumber numberWithBool:sender.on];
}

- (IBAction)toggleCustomURL:(UISwitch *)sender {
	URLTextField.enabled = sender.on;
	if (userDataCategory)
		userDataCategory.useCustomURL = [NSNumber numberWithBool:sender.on];
}

-(IBAction)upload {
	// obtain, or compute and store for re-use, our client ID
	NSString *clientID = [[NSUserDefaults standardUserDefaults] stringForKey:@"uploadUUID_preference"];
	if (!(clientID && [clientID length] == 36 && ![clientID isEqualToString:@"<auto>"])) {
		CFUUIDRef uuid = CFUUIDCreate(NULL);
		CFStringRef uuidStr = CFUUIDCreateString(NULL, uuid);
		clientID = [NSString stringWithString:(NSString *)uuidStr];
		CFRelease(uuidStr);
		CFRelease(uuid);
		// store as user default
		[[NSUserDefaults standardUserDefaults] setObject:clientID forKey:@"uploadUUID_preference"];
		[[NSUserDefaults standardUserDefaults] synchronize];
	}

	BOOL useCustomURL = (URLTextField.enabled && URLTextField.text && URLTextField.text.length);
	NSString *baseURL = (useCustomURL ? URLTextField.text : DEFAULT_UPLOAD_PATH);
	NSString *URLString = [NSString stringWithFormat:@"%@?clientID=%@%@&type=%@&category=%@", baseURL, clientID, (visibleToPublicSwitch.on ? @"_PUBLIC" : @""), (userDataCategory ? @"UserData" : @"Calculator"), (userDataCategory ? userDataCategory.name : (calculator ? calculator.name : @""))];
	NSURL *URL = [NSURL URLWithString:[URLString stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding]];

	NSString *JSONstring = (userDataCategory ? [self JSONStringForUserData] : [self JSONStringForCalculator]);
	
	NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:URL];
	[request setHTTPMethod:@"POST"];
	NSData *data = [JSONstring dataUsingEncoding:NSUTF8StringEncoding];
	[request setValue:@"application/json" forHTTPHeaderField:@"Content-Type"];
	[request setValue:[NSString stringWithFormat:@"%lu", (unsigned long)[data length]] forHTTPHeaderField:@"Content-Length"];
	[request setHTTPBody:data];

	NSURLConnection *connectionResponse = [[NSURLConnection alloc] initWithRequest:request delegate:self];
	if (connectionResponse) {
		receivedData = [[NSMutableData data] retain];
		[UIApplication sharedApplication].networkActivityIndicatorVisible = YES;
	}
}

#pragma mark -
#pragma mark Download

- (BOOL)addToDownloadQueue:(NSString *)URLString {
	if (![URLString hasPrefix:@"http:"])
		return NO;
	[downloadQueue addObject:URLString]; // expected to be a properly percent-encoded URL string // todo: check for compliance
	return YES;
}

- (BOOL)hasMoreDownloads {
	return ([downloadQueue count] > 0);
}
	
- (void)serviceDownloadQueue {
	if ([self hasMoreDownloads]) {
		NSURL *URL = [NSURL URLWithString:[downloadQueue objectAtIndex:0]];
		receivedData = [[NSMutableData data] retain];
		NSURLRequest *request = [NSURLRequest requestWithURL:URL];
		[[NSURLConnection alloc] initWithRequest:request delegate:self];
		[UIApplication sharedApplication].networkActivityIndicatorVisible = YES;
		isDownloading = YES;
	}
}

- (IBAction)downloadAssets {
	if (isDownloading) {
		[downloadQueue removeAllObjects];
		[downloadAssetsButton setTitle:NSLocalizedString(@"DownloadAssets", nil) forState:UIControlStateNormal]; // reset button title
	}
	else {
		// schedule downloads for all "http:" items
		for (UserDatum *datum in [userDataCategory.data allObjects])
			if ([datum.data hasPrefix:@"http:"])
				[self addToDownloadQueue:datum.data];

		[self serviceDownloadQueue];

		if (isDownloading)
			[downloadAssetsButton setTitle:NSLocalizedString(@"CancelDownloadAssets", nil) forState:UIControlStateNormal]; // "busy" text
	}
}

-(IBAction)download {
	// obtain our client ID, or inform user of error condition if not available
	NSString *clientID = [[NSUserDefaults standardUserDefaults] stringForKey:@"uploadUUID_preference"];
	if (!(clientID && ![clientID isEqualToString:@"<auto>"])) {
		[self reportError:NSLocalizedString(@"NoClientID", nil) for:NSLocalizedString(@"PleaseUpload", nil)];
		return;
	}

	NSString *baseURL = [(URLTextField.enabled && URLTextField.text && URLTextField.text.length ? URLTextField.text : DEFAULT_UPLOAD_PATH) stringByDeletingLastPathComponent];
	NSString *URLString = [NSString stringWithFormat:@"%@/uploads/%@%@_%@_%@.txt", baseURL, clientID, (visibleToPublicSwitch.on ? @"_PUBLIC" : @""), (userDataCategory ? @"UserData" : @"Calculator"), (userDataCategory ? userDataCategory.name : (calculator ? calculator.name : @""))];

	[self addToDownloadQueue:[URLString stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding]];
	[self serviceDownloadQueue];
/* was:
	NSURL *URL = [NSURL URLWithString:[URLString stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding]];
	receivedData = [[NSMutableData data] retain];
	NSURLRequest *request = [NSURLRequest requestWithURL:URL];
	[[NSURLConnection alloc] initWithRequest:request delegate:self];
	[UIApplication sharedApplication].networkActivityIndicatorVisible = YES;
	isDownloading = YES;
*/
}

- (BOOL)recreateCalculatorWithJSONString:(NSString *)JSONString {
	NSDictionary *dict = [JSONString JSONValue];
	//	NSLog(@"Count: %d, Dict: %@", [array count], dictionary);
	
	if (dict) {
		NSManagedObjectContext *context = [calculator managedObjectContext];
		
		{ // overview
		NSString *overview = [dict objectForKey:@"overview"];
		if (overview && [overview class] != [NSNull class])
			calculator.overview = overview;
		}
		{ // type
		NSString *type = [dict objectForKey:@"type"];
		if (type) {
            Type *typeObj = [NSEntityDescription insertNewObjectForEntityForName:@"Type" inManagedObjectContext:context];
			calculator.type = typeObj;
			calculator.type.name = type;
        }
		}
		{ // orientation
		NSString *orientation = [dict objectForKey:@"orientation"];
		if (orientation) {
            Orientation *or = [NSEntityDescription insertNewObjectForEntityForName:@"Orientation" inManagedObjectContext:context];
			calculator.orientation = or;
			calculator.orientation.name = orientation;
        }
		}
		{ // skin
		NSString *skin = [dict objectForKey:@"skin"];
		if (skin) {
            Skin *skinObj = [NSEntityDescription insertNewObjectForEntityForName:@"Skin" inManagedObjectContext:context];
			calculator.skin = skinObj;
			calculator.skin.name = skin;
        }
		}
		//NSLog(@"Calc: skin: %@, orientation: %@", calculator.skin.name, calculator.orientation.name);

		// keys & menus

		// delete all pre-existing keys
		for (Key *key in [calculator.keys allObjects])
			[context deleteObject:key];		
		// add new keys
		{ NSArray *array = [dict objectForKey:@"keys"];
		int index = 0;
		for (NSDictionary *d in array) {
			///			NSLog(@"Dict: %@", d);
			Key *key = [NSEntityDescription insertNewObjectForEntityForName:@"Key" inManagedObjectContext:context];
			key.name = [d objectForKey:@"name"];
			key.function = [d objectForKey:@"function"];			
			key.displayOrder = [NSNumber numberWithInteger:index++];
			key.calculator = calculator;
		}
		}

		// delete all pre-existing menus
		for (Menu *menu in [calculator.menus allObjects])
			[context deleteObject:menu];
		{ // add new menus
		NSArray *array = [dict objectForKey:@"menus"];
		int index = 0;
		for (NSDictionary *d in array) {
			///			NSLog(@"Dict: %@", d);
			Menu *menu = [NSEntityDescription insertNewObjectForEntityForName:@"Menu" inManagedObjectContext:context];
			menu.title = [d objectForKey:@"title"];
			menu.name = [d objectForKey:@"names"];
			menu.function = [d objectForKey:@"functions"];			
			menu.displayOrder = [NSNumber numberWithInteger:index++];
			menu.calculator = calculator;
		}
		}

		// notes
		{ NSString *notes = [dict objectForKey:@"notes"];
		if (notes && [notes class] != [NSNull class])
			calculator.notes = notes;
		}
		// injection
		{ NSString *injection = [dict objectForKey:@"injection"];
			if (injection && [injection class] != [NSNull class])
				calculator.injection = injection;
		}

		// dates;
		// uploadDate
		{ NSString *uploadDate = [dict objectForKey:@"uploadDate"];
			if (uploadDate) {
				NSDateFormatter *dateFormatter = [[[NSDateFormatter alloc] init] autorelease];
				[dateFormatter setDateFormat:@"yyyy-MM-dd HH:mm:ss Z"];
				calculator.uploadDate = [dateFormatter dateFromString:uploadDate];
			}
		}
		// lastUsedDate, downloadDate
		calculator.lastUsedDate = calculator.downloadDate = [NSDate date];

		// save
		NSError *error = nil;
		if (![context save:&error]) {
			// todo: better action
			NSArray* detailedErrors = [[error userInfo] objectForKey:NSDetailedErrorsKey];
			if (detailedErrors != nil && [detailedErrors count] > 0) {
				for(NSError* detailedError in detailedErrors) {
					NSLog(@"  DetailedError: %@", [detailedError userInfo]);
				}
			}
			else
				NSLog(@"Unresolved error %@, %@", error, [error userInfo]);			
		}
		
		return YES;
	}
	else
		return NO;
}

- (NSString *)mapStrings:(NSDictionary *)d inString:(NSString *)inString {
	NSArray *keys = [d allKeys];
	NSArray *vals = [d allValues];
	NSMutableString *string = [NSMutableString stringWithString:inString];
	for (NSUInteger i=0; i<[keys count]; i++)
		[string replaceOccurrencesOfString:[keys objectAtIndex:i] withString:[vals objectAtIndex:i] options:NSLiteralSearch range:NSMakeRange(0, [string length])];
	
	return string;
}

- (BOOL)recreateCategoryWithJSONString:(NSString *)JSONString {
	NSDictionary *dict = [JSONString JSONValue];
//	NSLog(@"Count: %d, Dict: %@", [array count], dictionary);

	if (dict) {
		NSManagedObjectContext *context = [userDataCategory managedObjectContext];

		// overview
		NSString *overview = [dict objectForKey:@"overview"];
		if (overview && [overview class] != [NSNull class])
			userDataCategory.overview = overview;

		// data

		NSArray *array = [dict objectForKey:@"data"];
		
		// delete all pre-existing objects in category
		for (UserDatum *datum in [userDataCategory.data allObjects])
			[context deleteObject:datum];

		// add new entries
		int index = 0;
		for (NSDictionary *d in array) {
//		for (NSUInteger i=0; i<[array count]; i++) {
///			NSDictionary *d = [array objectAtIndex:i];
///			NSLog(@"Dict: %@", d);
			UserDatum *userDatum = [NSEntityDescription insertNewObjectForEntityForName:@"UserDatum" inManagedObjectContext:context];
			userDatum.name = [d objectForKey:@"name"];
			id datum = [d objectForKey:@"data"];

			// transform objects into JSON strings
			if ([datum isKindOfClass:[NSDictionary class]]) {
				datum = [datum JSONRepresentation];
/* was:
				NSDictionary *dict = datum;
				NSMutableString *dictString = [NSMutableString stringWithString:@"{ "];
				for (id key in datum) {
					[dictString appendFormat:@"\"%@\": \"%@\"%@", key, [dict objectForKey:key], @","];
				}
				[dictString appendString:@" }"];
				datum = dictString;
*/
			}

			if (datum && [datum class] != [NSNull class]) {
				if ([datum class] == [NSNumber class])
					datum = [datum stringValue];
				else { // string
					if ([datum hasPrefix:@"\\<<"]) // RPL program
						datum = [self mapStrings:[NSDictionary dictionaryWithObjectsAndKeys:
										  @"\u2220", @"\\<>", // angle
										  @"\u221a", @"\\v/", // sqrt
										  @"\u03c0", @"\\pi",
										  @"<=", @"\\<=",
										  @">=", @"\\>=",
										  @"\u2260", @"\\=/",
										  @"\u2192", @"\\->",
										  @"\u03c0", @"\\PI",
										  @"\u226a", @"\\<<",
										  @"\u226b", @"\\>>",
										  @"/", @"\\:-",
										  @"\u2191", @"\\^|", // up-arrow
										  @"\u2193", @"\\v|", // down-arrow
										  nil]
									inString:datum];
				}
				userDatum.data = datum;
			}
			
			NSString *comment = [d objectForKey:@"comment"];
			if (comment && [comment class] != [NSNull class])
				userDatum.comment = comment;

			userDatum.displayOrder = [NSNumber numberWithInteger:index++];
			userDatum.category = userDataCategory;
		}
		
		// notes
		NSString *notes = [dict objectForKey:@"notes"];
		if (notes && [notes class] != [NSNull class])
			userDataCategory.notes = notes;

		// dates;
		// uploadDate
		{ NSString *uploadDate = [dict objectForKey:@"uploadDate"];
			if (uploadDate) {
				NSDateFormatter *dateFormatter = [[[NSDateFormatter alloc] init] autorelease];
				[dateFormatter setDateFormat:@"yyyy-MM-dd HH:mm:ss Z"];
				userDataCategory.uploadDate = [dateFormatter dateFromString:uploadDate];
			}
		}
		// lastUsedDate, downloadDate
		userDataCategory.lastUsedDate = userDataCategory.downloadDate = [NSDate date];
		
		// save
		NSError *error = nil;
		if (![context save:&error]) {
			// todo: better action
			NSArray* detailedErrors = [[error userInfo] objectForKey:NSDetailedErrorsKey];
			if (detailedErrors != nil && [detailedErrors count] > 0) {
				for(NSError* detailedError in detailedErrors) {
					NSLog(@"  DetailedError: %@", [detailedError userInfo]);
				}
			}
			else
				NSLog(@"Unresolved error %@, %@", error, [error userInfo]);			
		}
		
		return YES;
	}
	else
		return NO;
}

#pragma mark -
#pragma mark Cleanup

- (void)dealloc {
    [calculator release];
	[userDataCategory release];
    [URLTextField release];
    [lastUploadLabel release];
    [super dealloc];
}

@end
