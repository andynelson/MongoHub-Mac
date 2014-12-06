//
//  MODHelper.m
//  MongoHub
//
//  Created by Jérôme Lebel on 20/09/2011.
//

#import "MODHelper.h"
#import <MongoObjCDriver/MongoObjCDriver.h>
#import <MongoObjCDriver/MODDBPointer.h>

@interface MODHelper()
+ (NSMutableDictionary *)convertForOutlineWithValue:(id)dataValue dataKey:(NSString *)dataKey jsonKeySortOrder:(MODJsonKeySortOrder)jsonKeySortOrder;
@end

@implementation MODHelper

+ (NSArray *)convertForOutlineWithObjects:(NSArray *)mongoObjects bsonData:(NSArray *)allData jsonKeySortOrder:(MODJsonKeySortOrder)jsonKeySortOrder
{
    NSMutableArray *result;
    NSUInteger index = 0;
    
    result = [NSMutableArray arrayWithCapacity:[mongoObjects count]];
    for (MODSortedDictionary *object in mongoObjects) {
        id idValue = nil;
        NSString *idValueName = nil;
        NSMutableDictionary *dict = nil;
        
        idValue = [object objectForKey:@"_id"];
        idValueName = @"_id";
        if (!idValue) {
            idValue = [object objectForKey:@"name"];
            idValueName = @"name";
        }
        if (!idValue && [object count] > 0) {
            idValueName = [[object sortedKeys] objectAtIndex:0];
            idValue = [object objectForKey:idValueName];
        }
        if (idValue) {
            dict = [self convertForOutlineWithValue:idValue dataKey:idValueName jsonKeySortOrder:jsonKeySortOrder];
        }
        if (dict == nil) {
            dict = [NSMutableDictionary dictionary];
        }
        [dict setObject:[self convertForOutlineWithObject:object jsonKeySortOrder:jsonKeySortOrder] forKey:@"child" ];
        [dict setObject:[MODClient convertObjectToJson:object pretty:YES strictJson:NO jsonKeySortOrder:MODJsonKeySortOrderDocument] forKey:@"beautified"];
        [dict setObject:object forKey:@"objectvalue"];
        if (allData) {
            [dict setObject:[allData objectAtIndex:index] forKey:@"bsondata"];
        }
        [result addObject:dict];
        index++;
    }
    return result;
}

+ (NSArray *)convertForOutlineWithObject:(MODSortedDictionary *)mongoObject jsonKeySortOrder:(MODJsonKeySortOrder)jsonKeySortOrder
{
    NSMutableArray *result;
    NSArray *keys;
    
    keys = [MODClient sortKeys:mongoObject.sortedKeys withJsonKeySortOrder:jsonKeySortOrder];
    result = [NSMutableArray array];
    for (NSString *dataKey in keys) {
        NSMutableDictionary *value;
        
        value = [self convertForOutlineWithValue:[mongoObject objectForKey:dataKey] dataKey:dataKey jsonKeySortOrder:jsonKeySortOrder];
        if (value) {
            [result addObject:value];
        }
    }
    return result;
}

+ (NSMutableDictionary *)convertForOutlineWithValue:(id)dataValue dataKey:(NSString *)dataKey jsonKeySortOrder:(MODJsonKeySortOrder)jsonKeySortOrder
{
    NSArray *child = nil;
    NSString *value = @"";
    NSString *type = @"";
    NSMutableDictionary *result = nil;
    
    if ([dataValue isKindOfClass:[NSNumber class]]) {
        if (strcmp([dataValue objCType], @encode(double)) == 0 || strcmp([dataValue objCType], @encode(float)) == 0) {
            type = @"Double";
            value = [dataValue description];
        } else if (strcmp([dataValue objCType], @encode(int)) == 0) {
            type = @"Integer";
            value = [dataValue description];
        } else if (strcmp([dataValue objCType], @encode(long long)) == 0) {
            type = @"Long Integer";
            value = [dataValue description];
        } else if (strcmp([dataValue objCType], @encode(BOOL)) == 0) {
            type = @"Boolean";
            if ([dataValue boolValue]) {
                value = @"true";
            } else {
                value = @"false";
            }
        } else {
            NSLog(@"%s %@ %@", [dataValue objCType], dataValue, dataKey);
        }
    } else if ([dataValue isKindOfClass:[NSDate class]]) {
        type = @"Date";
        value = [dataValue description];
    } else if ([dataValue isKindOfClass:[MODObjectId class]]) {
        type = @"Object id";
        value = [dataValue jsonValueWithPretty:YES strictJSON:NO];
    } else if ([dataValue isKindOfClass:[MODRegex class]]) {
        type = @"Regex";
        value = [dataValue jsonValueWithPretty:YES strictJSON:NO];
    } else if ([dataValue isKindOfClass:[MODTimestamp class]]) {
        type = @"Timestamp";
        value = [dataValue jsonValueWithPretty:YES strictJSON:NO];
    } else if ([dataValue isKindOfClass:[MODBinary class]]) {
        type = @"Binary";
        value = [dataValue jsonValueWithPretty:YES strictJSON:NO];
    } else if ([dataValue isKindOfClass:[MODDBPointer class]]) {
        type = @"DBPointer deprecated";
        value = [dataValue jsonValueWithPretty:YES strictJSON:NO];
    } else if ([dataValue isKindOfClass:[NSString class]]) {
        type = @"String";
        value = dataValue;
    } else if ([dataValue isKindOfClass:[NSNull class]]) {
        type = @"NULL";
        value = @"NULL";
    } else if ([dataValue isKindOfClass:[MODSortedDictionary class]]) {
        NSUInteger count = [dataValue count];
      
        if ([dataValue objectForKey:@"$ref"]) {
            if ([dataValue objectForKey:@"$db"]) {
                type = [NSString stringWithFormat:@"Ref(%@.%@)", [dataValue objectForKey:@"$db"], [dataValue objectForKey:@"$ref"]];
            } else {
                type = [NSString stringWithFormat:@"Ref(%@)", [dataValue objectForKey:@"$ref"]];
            }
        } else if (count == 0) {
            type = NSLocalizedString(@"Object, no item", @"about an dictionary");
        } else if (count == 1) {
            type = NSLocalizedString(@"Object, 1 item", @"about an dictionary");
        } else {
            type = [NSString stringWithFormat:NSLocalizedString(@"Object, %d items", @"about an dictionary"), count];
        }
        child = [self convertForOutlineWithObject:dataValue jsonKeySortOrder:jsonKeySortOrder];
    } else if ([dataValue isKindOfClass:[MODSymbol class]]) {
        type = @"Symbol";
        value = [dataValue value];
    } else if ([dataValue isKindOfClass:[NSArray class]]) {
        NSUInteger ii, count = [dataValue count];
        
        if (count == 0) {
            type = NSLocalizedString(@"Array, no item", @"about an array");
        } else if (count == 1) {
            type = NSLocalizedString(@"Array, 1 item", @"about an array");
        } else {
            type = [NSString stringWithFormat:NSLocalizedString(@"Array, %d items", @"about an array"), count];
        }
        child = [NSMutableArray arrayWithCapacity:[dataValue count]];
        for (ii = 0; ii < count; ii++) {
            NSString *arrayDataKey;
            id arrayDataValue;
            
            arrayDataValue = [dataValue objectAtIndex:ii];
            arrayDataKey = [[NSString alloc] initWithFormat:@"%ld", (long)ii];
            [(NSMutableArray *)child addObject:[self convertForOutlineWithValue:arrayDataValue dataKey:arrayDataKey jsonKeySortOrder:jsonKeySortOrder]];
            [arrayDataKey release];
        }
    } else if ([dataValue isKindOfClass:[MODUndefined class]]) {
        type = @"Undefined";
        value = [dataValue jsonValueWithPretty:YES strictJSON:NO];
    } else if ([dataValue isKindOfClass:[MODFunction class]]) {
        type = @"Function";
        value = [dataValue function];
    } else if ([dataValue isKindOfClass:[MODScopeFunction class]]) {
        type = @"ScopeFunction";
        value = [dataValue function];
    } else {
        NSLog(@"type %@ value %@", [dataValue class], dataValue);
        NSAssert(NO, @"unknown type %@ value %@", [dataValue class], dataValue);
    }
    if (value) {
        result = [NSMutableDictionary dictionaryWithCapacity:4];
        [result setObject:value forKey:@"value"];
        [result setObject:dataKey forKey:@"name"];
        [result setObject:type forKey:@"type"];
        [result setObject:dataValue forKey:@"objectvalueid"];
        if (child) {
            [result setValue:child forKey:@"child"];
        }
    }
    return result;
}

@end
