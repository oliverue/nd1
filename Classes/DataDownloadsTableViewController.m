
/*
     File: DataDownloadsTableViewController.m
 Abstract: Table view controller to manage list of user data downloads.
 
  Version: 1.0
  
 */

#import "JSON.h"

#import "DataSharingController.h"

#import "DataDownloadsTableViewController.h"
#import "UserDataCategoryDetailViewController.h"
#import "Calculator.h"
#import "UserDataCategory.h"
#import "UserDataCategoryTableViewCell.h"

#import "CalculateAppDelegate.h" // for its calcViewController
#import "JS_CalcViewController.h" // for its .userDataCategory


@implementation DataDownloadsTableViewController


@synthesize managedObjectContext;
@synthesize doesManageUserData;


#pragma mark -
#pragma mark UIViewController overrides

- (id)initWithStyle:(UITableViewStyle)style {
    if ((self = [super initWithStyle:style])) {
        managedObjectContext = nil;
        doesManageUserData = YES;
    }

    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];

    // Set the table view's row height
    self.tableView.rowHeight = 44.0;

/* //// todo: add text
	if ([[[NSUserDefaults standardUserDefaults] objectForKey:@"tips_preference"] boolValue]) {
		UIAlertView *alert = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"MyDataTips", nil) message:NSLocalizedString(@"Downloads", nil) delegate:self cancelButtonTitle:nil otherButtonTitles:NSLocalizedString(@"GotIt", nil), nil];
		[alert show];
		[alert release];
	}
*/
	updates = nil;
	downloadables = nil;
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
	
	self.navigationItem.title = NSLocalizedString(@"Downloadables", nil);

	[self updateDownloadables];
	
    [self.tableView reloadData]; 
}


- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
    // Support all orientations except upside down
    return (interfaceOrientation != UIInterfaceOrientationPortraitUpsideDown);
}


#pragma mark -
#pragma mark Table view methods

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 2;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    NSInteger numberOfRows = 0;
	
	if (section == 0 && updates)
		numberOfRows = [updates count];
	else if (section == 1 && downloadables)
		numberOfRows = [downloadables count];
    
    return numberOfRows;
}

/*
- (NSArray *)sectionIndexTitlesForTableView:(UITableView *)tableView {
	return [NSArray arrayWithObjects:NSLocalizedString(@"Updates", nil), @"A", @"B", ..., nil];
}
*/
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
	static NSString *UserDataDownloadCellIdentifier = @"UserDataDownloadCellIdentifier";

	UITableViewCell *downloadableCategoryCell = (UITableViewCell *)[tableView dequeueReusableCellWithIdentifier:UserDataDownloadCellIdentifier];
	if (downloadableCategoryCell == nil) {
		downloadableCategoryCell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:UserDataDownloadCellIdentifier] autorelease];
	}
	
	[self configureCell:downloadableCategoryCell atIndexPath:indexPath];
	
	return downloadableCategoryCell;
}

- (void)configureCell:(UITableViewCell *)cell atIndexPath:(NSIndexPath *)indexPath {
	if ([indexPath section] < 2) {
		NSArray *array = (![indexPath section] ? updates : downloadables);
		NSDictionary *folder = [array objectAtIndex:[indexPath row]];
		NSString *title = [folder objectForKey:@"name"];
		NSString *overview = [folder objectForKey:@"overview"];
//				NSNumber *version = [folder objectForKey:@"version"];
//				NSNumber *nEntries = [folder objectForKey:@"nEntries"];
// NSLog(@"Folder %@, %@, version %@ with %@ entries", name, overview, version, nEntries);
		cell.textLabel.text = NSLocalizedString(title, nil);
		cell.detailTextLabel.text = NSLocalizedString(overview, nil);
	}
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
	if (section == 0)
		return [NSString stringWithFormat:@"%@ (%lu)", NSLocalizedString(@"Updates", nil), (unsigned long)[updates count]];
	else
		return [NSString stringWithFormat:@"%@ (%lu)", NSLocalizedString(@"Available Folders", nil), (unsigned long)[downloadables count]];
}

#ifdef IS_ALSO_ND0
#define ND0_MAX_CATEGORIES	8

- (NSUInteger)dataCategoryCount {
	NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] init];
	NSEntityDescription *entity = [NSEntityDescription entityForName:@"UserDataCategory" inManagedObjectContext:[self managedObjectContext]];
	[fetchRequest setEntity:entity];
	NSError *error = nil;
	NSArray *dataCategories = [managedObjectContext executeFetchRequest:fetchRequest error:&error];
	[fetchRequest release];
	
	return [dataCategories count];
}

- (BOOL)licensePermitsAnotherDownload {
	if ([self dataCategoryCount] >= ND0_MAX_CATEGORIES) {
		UIAlertView *alert = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"SharedFolders", nil) message:NSLocalizedString(@"ReachedFolderDownloadLimit", nil) delegate:self cancelButtonTitle:nil otherButtonTitles:NSLocalizedString(@"OK", nil), nil];
		[alert show];
		[alert release];
		return NO;
	}
	else
		return YES;
}
#endif

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
	NSMutableArray *array = (![indexPath section] ? updates : downloadables);
	NSString *folderName = [[array objectAtIndex:[indexPath row]] objectForKey:@"name"];
#ifdef IS_ALSO_ND0
	if ([self licensePermitsAnotherDownload])
#endif
	if ([self installFolder:folderName]) {
		[array removeObjectAtIndex:[indexPath row]];
		[self.tableView reloadData];
	}
}

#pragma mark -
#pragma mark Downloadables

- (BOOL)updateDownloadables {
	[UIApplication sharedApplication].networkActivityIndicatorVisible = YES;
	NSString *JSONString = [NSString stringWithContentsOfURL:[NSURL URLWithString:(doesManageUserData ? @"http://naivedesign.com/public/Folders.txt" : @"http://naivedesign.com/public/Calculators.txt")] encoding:NSUTF8StringEncoding error:NULL];
	[UIApplication sharedApplication].networkActivityIndicatorVisible = NO;
	NSDictionary *dict = [JSONString JSONValue];
	//	NSLog(@"Count: %d, Dict: %@", [array count], dictionary);
	
	if (dict) {
		// overview
		NSString *overview = [dict objectForKey:@"overview"];
		if (overview && [overview class] != [NSNull class])
			; // ok
		
		// data
		
		NSArray *array = [dict objectForKey:@"data"];

		if (updates)
			[updates release];
		updates = [[NSMutableArray alloc] initWithCapacity:[array count]];
		if (downloadables)
			[downloadables release];
		downloadables = [[NSMutableArray alloc] initWithCapacity:[array count]];
		
		// add new entries
		for (NSDictionary *d in array) {
			NSString *name = [d objectForKey:@"name"];
			//NSString *overview = [d objectForKey:@"overview"];
			NSString *version = [d objectForKey:@"version"];
			NSNumber *nEntries = [d objectForKey:@"nEntries"];
			// NSLog(@"Folder %@, %@, version %@ with %@ entries", name, overview, version, nEntries);

            // skip empty calculators
            if (!doesManageUserData && nEntries && [nEntries integerValue] == 0)
                continue;

			// see if we already have a copy of this folder
            BOOL haveAlready = NO;
            if (doesManageUserData) {
                UserDataCategory *userDataCategory = [(CalculateAppDelegate *)[[UIApplication sharedApplication] delegate] dataCategoryForFolderNamed:name];
                if (userDataCategory) { // we already have a local copy of this folder
                    // NSLog(@"Has local copy of %@", name);
                    NSString *notes = userDataCategory.notes;
                    if (notes && notes.length) {
                        NSRange r = [notes rangeOfString:@"@version"];
                        if (r.length) {
                            NSRange tillNL = [notes rangeOfString:@"\n" options:NSLiteralSearch range:NSMakeRange(r.location, notes.length-r.location)];
                            if (!tillNL.length)
                                tillNL = NSMakeRange(notes.length, 0);
                            NSUInteger versionBegin = r.location+r.length+1; // one char after version marker
                            NSString *existingVersion = [userDataCategory.notes substringWithRange:NSMakeRange(versionBegin, tillNL.location-versionBegin)];
                            if ([version isEqualToString:existingVersion])
                                continue; // local folder is up-to-date; skip
                        }
                    }
                    [updates addObject:d];
                    haveAlready = YES;
                }
            }
            else {
                Calculator *calculator = [(CalculateAppDelegate *)[[UIApplication sharedApplication] delegate] calculatorNamed:name];
                if (calculator) { // we already have a local copy of this calculator
                    // NSLog(@"Has local copy of %@", name);
                    NSString *notes = calculator.notes;
                    if (notes && notes.length) {
                        NSRange r = [notes rangeOfString:@"@version"];
                        if (r.length) {
                            NSRange tillNL = [notes rangeOfString:@"\n" options:NSLiteralSearch range:NSMakeRange(r.location, notes.length-r.location)];
                            if (!tillNL.length)
                                tillNL = NSMakeRange(notes.length, 0);
                            NSUInteger versionBegin = r.location+r.length+1; // one char after version marker
                            NSString *existingVersion = [calculator.notes substringWithRange:NSMakeRange(versionBegin, tillNL.location-versionBegin)];
                            if ([version isEqualToString:existingVersion])
                                continue; // local calculator is up-to-date; skip
                        }
                    }
                    [updates addObject:d];
                    haveAlready = YES;
                }
            }
            
            if (!haveAlready)
                [downloadables addObject:d];
		}
/* todo: find a use for these
		// notes
		NSString *notes = [dict objectForKey:@"notes"];
		NSString *dateString = [dict objectForKey:@"date"];
		NSDateFormatter *dateFormatter = [[[NSDateFormatter alloc] init] autorelease];
		[dateFormatter setDateFormat:@"yyyy-MM-dd HH:mm:ss Z"];
		NSDate *date = [dateFormatter dateFromString:dateString];
*/
		return YES;
	}
	else
		return NO;
}

- (BOOL)installFolder:(NSString *)folderName {
	BOOL ok = NO;

	// obtain folder contents
	[UIApplication sharedApplication].networkActivityIndicatorVisible = YES;
	NSString *folder_json = [NSString stringWithContentsOfURL:[NSURL URLWithString:[[NSString stringWithFormat:(doesManageUserData ? @"http://naivedesign.com/public/UserData_%@.txt" : @"http://naivedesign.com/public/Calculator_%@.txt"), folderName] stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding]] encoding:NSUTF8StringEncoding error:NULL];
	[UIApplication sharedApplication].networkActivityIndicatorVisible = NO;

	if (folder_json) {
        DataSharingController *dataService = [[DataSharingController alloc] initWithNibName:@"DataSharing" bundle:nil];
        dataService.calculator = nil;
        dataService.userDataCategory = nil;

        if (doesManageUserData) {
            UserDataCategory *userDataCategory = [(CalculateAppDelegate *)[[UIApplication sharedApplication] delegate] dataCategoryForFolderNamed:folderName];
            if (!userDataCategory) { // no pre-existing category?
                // create it
                userDataCategory = [NSEntityDescription insertNewObjectForEntityForName:@"UserDataCategory" inManagedObjectContext:self.managedObjectContext];
                userDataCategory.name = NSLocalizedString(folderName, nil);
            }
            dataService.userDataCategory = userDataCategory;

            // populate folder
            ok = [dataService recreateCategoryWithJSONString:folder_json]; // this will also save into context
		}
        else {
            Calculator *calculator = [(CalculateAppDelegate *)[[UIApplication sharedApplication] delegate] calculatorNamed:folderName];
            if (!calculator) { // no pre-existing calculator?
                // create it
                calculator = [NSEntityDescription insertNewObjectForEntityForName:@"Calculator" inManagedObjectContext:self.managedObjectContext];
                calculator.name = NSLocalizedString(folderName, nil);
            }
            dataService.calculator = calculator;

            // populate folder
            ok = [dataService recreateCalculatorWithJSONString:folder_json]; // this will also save into context
		}

		[dataService release];
	}
	
	return ok;
}

#pragma mark -
#pragma mark Memory management

- (void)dealloc {
	[managedObjectContext release];
    [super dealloc];
}

@end
