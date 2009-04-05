//
//  MDYAML.m
//  Pyrot
//
//  Created by Michael Schrag on 8/9/08.
//  Copyright 2008 m Dimension Technology. All rights reserved.
//

#import "MDYAML.h"
#import "NSBoolean.h"

@interface NSString (regex)
- (BOOL) yamlMatchesPattern:(NSString *)regex;
@end

@implementation NSString (regex)
- (BOOL) yamlMatchesPattern:(NSString *)regex {
	NSString *testRegex = [[NSString alloc] initWithFormat:@"SELF MATCHES '%@'", regex];
	NSPredicate *regexPredicate = [NSPredicate predicateWithFormat:testRegex];
	[testRegex release];// the predicate has retained testRegex
	return [regexPredicate evaluateWithObject:self];
}
@end

@interface MDYAML (hidden)
+ (id) objectWithYamlDocument:(yaml_document_t *)document node:(yaml_node_t *)node;
+ (int) addObject:(id)object toDocument:(yaml_document_t *)document;
@end

@implementation MDYAML
- (id) init {
	if (self = [super init]) {
	}
	return self;
}

+ (NSMutableDictionary *)dictionaryWithYamlDocument:(yaml_document_t *)document node:(yaml_node_t *)node {
	NSMutableDictionary *dictionary = [NSMutableDictionary dictionary];
	yaml_node_pair_t *pair;
	for (pair = node->data.mapping.pairs.start; pair < node->data.mapping.pairs.top; pair ++) {
		yaml_node_t *keyNode = yaml_document_get_node(document, pair->key);
		yaml_node_t *valueNode = yaml_document_get_node(document, pair->value);
		
		id key = [MDYAML objectWithYamlDocument:document node:keyNode];
		id value = [MDYAML objectWithYamlDocument:document node:valueNode];
		[dictionary setObject:value forKey:key];
	}
	return dictionary;
}

+ (NSMutableArray *)arrayWithYamlDocument:(yaml_document_t *)document node:(yaml_node_t *)node {
	NSMutableArray *array = [NSMutableArray array];
	yaml_node_item_t *item;
	for (item = node->data.sequence.items.start; item < node->data.sequence.items.top; item ++) {
		yaml_node_t *node = yaml_document_get_node(document, *item);
		id value = [MDYAML objectWithYamlDocument:document node:node];
		[array addObject:value];
	}
	return array;
}	

+ (id) scalarWithYamlDocument:(yaml_document_t *)document node:(yaml_node_t *)node {
	//yaml_scalar_style_t style = node->data.scalar.style;
	yaml_char_t *value = node->data.scalar.value;
	
	id result;
	NSString *str = [NSString stringWithCString:(char *)value encoding:[NSString defaultCStringEncoding]];
	if ([str yamlMatchesPattern:@"^-?\\d+$"]) {
		result = [NSNumber numberWithInt:[str intValue]];
	}
	else if ([str yamlMatchesPattern:@"^-?\\d+\\.\\d+$"]) {
		result = [NSNumber numberWithFloat:[str floatValue]];
	}
	else if ([str caseInsensitiveCompare:@"true"] == NSOrderedSame) {
		result = [NSBoolean booleanWithBool:YES];
	}
	else if ([str caseInsensitiveCompare:@"false"] == NSOrderedSame) {
		result = [NSBoolean booleanWithBool:NO];
	}
	else {
		result = str;
	}
	return result;
}

+ (id) objectWithYamlDocument:(yaml_document_t *)document node:(yaml_node_t *)node {
	id result = nil;
	switch (node->type) {
		case YAML_SCALAR_NODE:
			result = [MDYAML scalarWithYamlDocument:document node:node];
			break;
			
		case YAML_SEQUENCE_NODE:
			result = [MDYAML arrayWithYamlDocument:document node:node];
			break;
			
		case YAML_MAPPING_NODE:
			result = [MDYAML dictionaryWithYamlDocument:document node:node];
			break;
			
		default:
			assert(0);
			break;
	}
	
	return result;
}

+ (id) objectWithParser:(yaml_parser_t *)parser {
	id result = nil;
	yaml_document_t document;
	if (yaml_parser_load(parser, &document)) {
		yaml_node_t *rootNode = yaml_document_get_root_node(&document);
		result = [MDYAML objectWithYamlDocument:&document node:rootNode];
		yaml_document_delete(&document);
	}
	return result;
}

+ (id) objectWithContentsOfString:(NSString *)yaml {
	id result = nil;
	yaml_parser_t parser;
	if (yaml != nil && yaml_parser_initialize(&parser)) {
		const char *input = [yaml cStringUsingEncoding:[NSString defaultCStringEncoding]];
		size_t length = [yaml length];
		yaml_parser_set_input_string(&parser, (unsigned char *)input, length);
		result = [MDYAML objectWithParser:&parser];
		yaml_parser_delete(&parser);
	}
	return result;
}

+ (id) objectWithContentsOfFile:(NSString *)path {
	NSString *yaml = [NSString stringWithContentsOfFile:path];
	return [MDYAML objectWithContentsOfString:yaml];
}

+ (int) addDictionary:(NSDictionary *)dictionary toDocument:(yaml_document_t *)document {
	int mappingID = yaml_document_add_mapping(document, NULL, YAML_ANY_MAPPING_STYLE);
	for (id key in [dictionary allKeys]) {
		id value = [dictionary objectForKey:key];
		int keyID = [MDYAML addObject:key toDocument:document];
		int valueID = [MDYAML addObject:value toDocument:document];
		yaml_document_append_mapping_pair(document, mappingID, keyID, valueID);
	}
	return mappingID;
}

+ (int) addArray:(NSArray *)array toDocument:(yaml_document_t *)document {
	int sequenceID = yaml_document_add_sequence(document, NULL, YAML_ANY_SEQUENCE_STYLE);
	for (id value in array) {
		int valueID = [MDYAML addObject:value toDocument:document];
		yaml_document_append_sequence_item(document, sequenceID, valueID);
	}
	return sequenceID;
}

+ (int) addScalar:(id)scalar toDocument:(yaml_document_t *)document {
	NSString *str;
	if ([scalar isKindOfClass:[NSNumber class]]) {
		str = [(NSNumber *)scalar stringValue];
	} 
	else if ([scalar isKindOfClass:[NSBoolean class]]) {
		str = [(NSBoolean *)scalar stringValue];
	}
	else {
		str = (NSString *)scalar;
	}
	int scalarID = yaml_document_add_scalar(document, NULL, (yaml_char_t *)[str cStringUsingEncoding:[NSString defaultCStringEncoding]], [str length], YAML_ANY_SCALAR_STYLE);
	return scalarID;
}

+ (int) addObject:(id)object toDocument:(yaml_document_t *)document {
	int nodeID;
	if ([object isKindOfClass:[NSDictionary class]]) {
		nodeID = [MDYAML addDictionary:(NSDictionary *)object toDocument:document];
	}
	else if ([object isKindOfClass:[NSArray class]]) {
		nodeID = [MDYAML addArray:(NSArray *)object toDocument:document];
	}
	else {
		nodeID = [MDYAML addScalar:(NSDictionary *)object toDocument:document];
	}
	return nodeID;
}

int NSMutableString_write_handler(void *data, unsigned char *buffer, size_t size) {
	NSMutableString *str = (NSMutableString *)data;
	[str appendString:[NSString stringWithCString:(const char *)buffer length:size]];
	return 1;
}

+ (NSString *) stringWithObject:(id)object {
	NSMutableString *str = nil;
	yaml_document_t document;
	yaml_emitter_t emitter;
	if (yaml_emitter_initialize(&emitter)) {
		str = [NSMutableString string];
		yaml_emitter_set_output(&emitter, (yaml_write_handler_t *)&NSMutableString_write_handler, str);
		if (yaml_emitter_open(&emitter)) {
			if (yaml_document_initialize(&document, NULL, NULL, NULL, 0, 0)) {
				[MDYAML addObject:object toDocument:&document];
				yaml_emitter_dump(&emitter, &document);
			}
			yaml_emitter_close(&emitter);
		}
		yaml_emitter_delete(&emitter);
	}
	return str;
}

+ (void) writeObject:(id)object toFile:(NSString *)path {
	NSString *str = [self stringWithObject:object];
	[str writeToFile:path atomically:FALSE encoding:[NSString defaultCStringEncoding] error:nil];
}

- (void) dealloc {
	[super dealloc];
}
@end
