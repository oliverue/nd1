
/*
     File: CalculatorTableViewCell.m
 Abstract: A table view cell that displays information about a Calculator. 
 It uses individual subviews of its content view to show the name, picture, description, and type for each calculator. 
 If the table view switches to editing mode, the cell reformats itself to move the type off-screen, and resizes the name and description fields accordingly.
 
  Version: 1.0

 */

#import "Type.h"

#import "CalculatorTableViewCell.h"


#pragma mark -
#pragma mark SubviewFrames category

@interface CalculatorTableViewCell (SubviewFrames)
- (CGRect)_imageViewFrame;
- (CGRect)_nameLabelFrame;
- (CGRect)_descriptionLabelFrame;
- (CGRect)_typeLabelFrame;
@end




#pragma mark -
#pragma mark CalculatorTableViewCell implementation

@implementation CalculatorTableViewCell

@synthesize calculator, imageView, nameLabel, overviewLabel, typeLabel;


#pragma mark -
#pragma mark Initialization

- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier {
	if (self = [super initWithStyle:style reuseIdentifier:reuseIdentifier]) {
        imageView = [[UIImageView alloc] initWithFrame:CGRectZero];
		imageView.contentMode = UIViewContentModeScaleAspectFit;
        [self.contentView addSubview:imageView];

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
	
    [imageView setFrame:[self _imageViewFrame]];
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
- (CGRect)_imageViewFrame {
    if (self.editing) {
        return CGRectMake(EDITING_INSET, 0.0, IMAGE_SIZE, IMAGE_SIZE);
    }
	else {
        return CGRectMake(0.0, 0.0, IMAGE_SIZE, IMAGE_SIZE);
    }
}

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
#pragma mark Calculator set accessor

- (void)setCalculator:(Calculator *)newCalculator {
    if (newCalculator != calculator) {
        [calculator release];
        calculator = [newCalculator retain];
	}
	imageView.image = calculator.thumbnailImage;
	nameLabel.text = NSLocalizedString(calculator.name, nil);
	overviewLabel.text = NSLocalizedString(calculator.overview, nil);
	typeLabel.text = NSLocalizedString(calculator.type.name, nil);
}


#pragma mark -
#pragma mark Memory management

- (void)dealloc {
    [calculator release];
    [imageView release];
    [nameLabel release];
    [overviewLabel release];
    [typeLabel release];
    [super dealloc];
}

@end
