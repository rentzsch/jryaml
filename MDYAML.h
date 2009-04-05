//
//  YAML.h
//  Pyrot
//
//  Created by Michael Schrag on 8/9/08.
//  Copyright 2008 m Dimension Technology. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import <yaml.h>

@interface MDYAML : NSObject {
}
+ (id) objectWithContentsOfFile:(NSString *)path;
+ (id) objectWithContentsOfString:(NSString *)yaml;
+ (NSString *) stringWithObject:(id)object;
+ (void) writeObject:(id)object toFile:(NSString *)path;

@end
