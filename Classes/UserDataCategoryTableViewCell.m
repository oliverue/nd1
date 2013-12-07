
/*
     File: UserDataCategoryTableViewCell.m
 Abstract: A table view cell that displays information about a UserDataCategory. 
 
  Version: 1.0

 */

#import "UserDataCategoryTableViewCell.h"


#pragma mark -
#pragma mark SubviewFrames category

@interface UserDataCategoryTableViewCell (SubviewFrames)
- (CGRect)_nameLabelFrame;
- (CGRect)_descriptionLabelFrame;
- (CGRect)_typeLabelFrame;
@end




#pragma mark -
#pragma mark UserDataCategoryTableViewCell implementation

@implementation UserDataCategoryTableViewCell

@synthesize userDataCategory, nameLabel, overviewLabel, typeLabel;


#pragma mark -
#pragma mark Initialization

- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier {
	if (self = [super initWithStyle:style reuseIdentifier:reuseIdentifier]) {
        overviewLabel = [[UILabel alloc] initWithFrame:CGRectZero];
        [overviewLabel setFont:[UIFont systemFontOfSize:14.0]];
        [overviewLabel setTextColor:[UIColor secondaryLabelColor]];
        [self.contentView addSubview:overviewLabel];

        typeLabel = [[UILabel alloc] initWithFrame:CGRectZero];
        typeLabel.textAlignment = NSTextAlignmentRight;
        [typeLabel setFont:[UIFont systemFontOfSize:12.0]];
		typeLabel.minimumScaleFactor = 0.6;
		typeLabel.lineBreakMode = NSLineBreakByTruncatingTail;
        [self.contentView addSubview:typeLabel];

        nameLabel = [[UILabel alloc] initWithFrame:CGRectZero];
        [nameLabel setFont:[UIFont boldSystemFontOfSize:18.0]];
        [self.contentView addSubview:nameLabel];
    }

    return self;
}


#pragma mark -
#pragma mark Laying out subviews

/*
 To save space, the type label disappears during editing.
 */
- (void)layoutSubviews {
    [super layoutSubviews];
	
    [nameLabel setFrame:[self _nameLabelFrame]];
    [overviewLabel setFrame:[self _descriptionLabelFrame]];
    [typeLabel setFrame:[self _typeLabelFrame]];
    if (self.editing) {
        typeLabel.alpha = 0.0;
    } else {
        typeLabel.alpha = 1.0;
    }
}


#define IMAGE_SIZE          42.0
#define EDITING_INSET       10.0
#define TEXT_LEFT_MARGIN    8.0
#define TEXT_RIGHT_MARGIN   5.0
#define TYPE_WIDTH			100.0

/*
 Return the frame of the various subviews -- these are dependent on the editing state of the cell.
 */

- (CGRect)_nameLabelFrame {
    if (self.editing) {
        return CGRectMake(IMAGE_SIZE + EDITING_INSET + TEXT_LEFT_MARGIN, 4.0, self.contentView.bounds.size.width - IMAGE_SIZE - EDITING_INSET - TEXT_LEFT_MARGIN, 20.0);
    }
	else {
        return CGRectMake(IMAGE_SIZE + TEXT_LEFT_MARGIN, 4.0, self.contentView.bounds.size.width - IMAGE_SIZE - TEXT_RIGHT_MARGIN * 2 - TYPE_WIDTH, 20.0);
    }
}

- (CGRect)_descriptionLabelFrame {
    if (self.editing) {
        return CGRectMake(IMAGE_SIZE + EDITING_INSET + TEXT_LEFT_MARGIN, 24.0, self.contentView.bounds.size.width - IMAGE_SIZE - EDITING_INSET - TEXT_LEFT_MARGIN, 16.0);
    }
	else {
        return CGRectMake(IMAGE_SIZE + TEXT_LEFT_MARGIN, 24.0, self.contentView.bounds.size.width - IMAGE_SIZE - TEXT_LEFT_MARGIN, 16.0);
    }
}

- (CGRect)_typeLabelFrame {
    CGRect contentViewBounds = self.contentView.bounds;
    return CGRectMake(contentViewBounds.size.width - TYPE_WIDTH - TEXT_RIGHT_MARGIN, 4.0, TYPE_WIDTH, 16.0);
}


#pragma mark -
#pragma mark UserDataCategory set accessor

- (void)setUserDataCategory:(UserDataCategory *)newUserDataCategory {
    if (newUserDataCategory != userDataCategory) {
        [userDataCategory release];
        userDataCategory = [newUserDataCategory retain];
	}
	nameLabel.text = NSLocalizedString(userDataCategory.name, nil);
	overviewLabel.text = NSLocalizedString(userDataCategory.overview, nil);
	typeLabel.text = [NSString stringWithFormat:@"%@: %lu", NSLocalizedString(@"entries", nil), (unsigned long)[userDataCategory.data count]];
}


#pragma mark -
#pragma mark Memory management

- (void)dealloc {
    [userDataCategory release];
    [nameLabel release];
    [overviewLabel release];
    [typeLabel release];
    [super dealloc];
}

@end
