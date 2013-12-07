//
//  SlideButton.h
//  Calculate
//
//  Created by Oliver Unter Ecker on 10/10/09.
//  Copyright 2009 Naive Design. All rights reserved.
//

#import <UIKit/UIKit.h>


@interface SlideButton : UIButton {
	NSArray *names, *functions;
	NSString *placeholder;
}

- (void)setTitleForRelativePosition:(float)pos;

@property (nonatomic, retain) NSArray *names;
@property (nonatomic, retain) NSArray *functions;
@property (nonatomic, retain) NSString *placeholder;

@end
