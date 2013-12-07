
/*
     File: EditingTableViewCell.m
 Abstract: A table view cell that displays a label and a text field so that a value can be edited. The user interface is loaded from a nib file.
 
  Version: 1.0
  
 */

#import "EditingTableViewCell.h"

@implementation EditingTableViewCell

@synthesize label, textField;

- (void)dealloc {
	[label release];
	[textField release];
	[super dealloc];
}

@end
