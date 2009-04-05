//
//  NSBoolean.h
//  Pyrot
//
//  Created by Michael Schrag on 8/9/08.
//  Copyright 2008 m Dimension Technology. All rights reserved.
//

#import <Cocoa/Cocoa.h>


@interface NSBoolean : NSObject {
	BOOL _value;
}

-(id)initWithBool:(BOOL)value;
-(BOOL)value;
-(NSString *)stringValue;

+(NSBoolean *)booleanWithBool:(BOOL)value;

@end
