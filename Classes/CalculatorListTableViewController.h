 
 /*
     File: CalculatorListTableViewController.h
 Abstract: Table view controller to manage an editable table view that displays a list of calculators.
 Calculators are displayed in a custom table view cell.
 
  Version: 1.0
  
 */

#import "CalculatorAddViewController.h"

@class Calculator;
@class CalculatorTableViewCell;

@interface CalculatorListTableViewController : UITableViewController <CalculatorAddDelegate, NSFetchedResultsControllerDelegate> {
    @private
        NSFetchedResultsController *fetchedResultsController;
        NSManagedObjectContext *managedObjectContext;
}

@property (nonatomic, retain) NSFetchedResultsController *fetchedResultsController;
@property (nonatomic, retain) NSManagedObjectContext *managedObjectContext;

- (void)showCalculator:(Calculator *)calculator animated:(BOOL)animated;
- (void)configureCell:(CalculatorTableViewCell *)cell atIndexPath:(NSIndexPath *)indexPath;

@end
