//
//  ImageToDataTransformer.m
//  Calculate
//
//  Created by Oliver Unter Ecker on 9/12/09.
//  Copyright 2009 Naive Design. All rights reserved.
//

#import "ImageToDataTransformer.h"


@implementation ImageToDataTransformer

+ (BOOL)allowsReverseTransformation {
	return YES;
}

+ (Class)transformedValueClass {
	return [NSData class];
}

- (id)transformedValue:(id)value {
	NSData *data = UIImagePNGRepresentation(value);
	return data;
}

- (id)reverseTransformedValue:(id)value {
	UIImage *uiImage = [[UIImage alloc] initWithData:value];
	return [uiImage autorelease];
}

@end
