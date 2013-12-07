//
//  SlideButton.m
//  Calculate
//
//  Created by Oliver Unter Ecker on 10/10/09.
//  Copyright 2009 Naive Design. All rights reserved.
//

#import "SlideButton.h"


@implementation SlideButton

@synthesize names, functions;
@synthesize placeholder;

- (id)initWithFrame:(CGRect)frame {
    if (self = [super initWithFrame:frame]) {
        names = functions = nil;
		placeholder = nil;
    }
    return self;
}

- (void)setTitleToPlaceholder {
	[self setTitleColor:[UIColor lightGrayColor] forState:UIControlStateNormal];
	[self setTitle:placeholder forState:UIControlStateNormal];
}

- (void)setPlaceholder:(NSString *)title {
	placeholder = [title retain];
	[self setTitleToPlaceholder];
}

- (void)setTitleForRelativePosition:(float)pos {
	if (pos > 1.0f) pos = 1.0f;
	else if (pos < 0.0f) pos = 0.0f;

	[self setTitle:[names objectAtIndex:(([names count]-1)*pos+0.5f)] forState:UIControlStateNormal];
	[self setTitle:[functions objectAtIndex:(([functions count]-1)*pos+0.5f)] forState:UIControlStateApplication];
}

- (BOOL)beginTrackingWithTouch:(UITouch *)touch withEvent:(UIEvent *)event {
	[SlideButton cancelPreviousPerformRequestsWithTarget:self]; // cancel any pending placeholder sets
	[self setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];

	if (placeholder)
		[self setTitleForRelativePosition:([touch locationInView:self].x / self.frame.size.width)];

	return YES;
}

- (BOOL)continueTrackingWithTouch:(UITouch *)touch withEvent:(UIEvent *)event {
	[self setTitleForRelativePosition:([touch locationInView:self].x / self.frame.size.width)];

	return YES;
}

- (void)endTrackingWithTouch:(UITouch *)touch withEvent:(UIEvent *)event {
	if (placeholder)
		[self performSelector:@selector(setTitleToPlaceholder) withObject:nil afterDelay:3.0];
}

- (void)dealloc {
	[names release];
	[functions release];
    [super dealloc];
}


@end
