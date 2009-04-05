//
//  NSBoolean.m
//  Pyrot
//
//  Created by Michael Schrag on 8/9/08.
//  Copyright 2008 m Dimension Technology. All rights reserved.
//

#import "NSBoolean.h"


@implementation NSBoolean
- (BOOL)value {
	return _value;
}

- (id)initWithBool:(BOOL)value {
	if (self = [super init]) {
		_value = value;
	}
	return self;
}

- (NSUInteger)hash {
	return _value;
}

- (BOOL)isEqual:(id)anObject {
	return [anObject isKindOfClass:[NSBoolean class]] && [((NSBoolean *)anObject) value] == _value;
}

-(NSString *)stringValue {
	return _value ? @"true" : @"false";
}

+ (NSBoolean *)booleanWithBool:(BOOL)value {
	NSBoolean *boolean = [[NSBoolean alloc] initWithBool:value];
	return [boolean autorelease];
}

@end
