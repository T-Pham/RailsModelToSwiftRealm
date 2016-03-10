//
//  main.m
//  rbmodeltoswift
//
//  Created by Thanh Pham on 3/10/16.
//  Copyright © 2016 Thanh Pham. All rights reserved.
//

#import <Foundation/Foundation.h>

NSString *toCamelCase(NSString *s)
{
    NSString *titleCase = [[[s capitalizedString] componentsSeparatedByCharactersInSet:[[NSCharacterSet characterSetWithCharactersInString:@"ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789"] invertedSet]] componentsJoinedByString:@""];
    NSString *firstChar = [s substringToIndex:1];
    return [titleCase stringByReplacingCharactersInRange:(NSRange){0, 1} withString:firstChar];
}

void scanTable(NSString *input) {
    NSDictionary *typeMap = @{@"text": @"String",
                              @"string": @"String",
                              @"integer": @"Int",
                              @"datetime": @"NSDate",
                              @"date": @"NSDate",
                              @"boolean": @"Bool",
                              @"float": @"CGFloat",
                              @"inet": @"String",
                              @"decimal": @"Double",
                              @"json": @"String",
                              @"tsvector": @"String"
                              };
    NSDictionary *valueMap = @{@"text": @"\"\"",
                               @"string": @"\"\"",
                               @"integer": @"0",
                               @"datetime": @"NSDate()",
                               @"date": @"NSDate()",
                               @"boolean": @"false",
                               @"float": @"0",
                               @"inet": @"\"127.0.0.1\"",
                               @"decimal": @"0",
                               @"json": @"\"{}\"",
                               @"tsvector": @"\"\""
                               };

    NSMutableCharacterSet *nameCharacterSet = [NSMutableCharacterSet alphanumericCharacterSet];
    [nameCharacterSet  addCharactersInString:@"_"];

    NSScanner *scanner = [[NSScanner alloc] initWithString:input];

    NSString *firstLine;
    [scanner scanUpToString:@"\n" intoString:&firstLine];
    NSScanner *firstLineScanner = [NSScanner scannerWithString:firstLine];
    NSString *model;
    [firstLineScanner scanUpToCharactersFromSet:[NSCharacterSet characterSetWithCharactersInString:@"\""] intoString:nil];
    firstLineScanner.scanLocation++;
    [firstLineScanner scanCharactersFromSet:nameCharacterSet intoString:&model];
    if ([model hasSuffix:@"ies"]) {
        model = [model stringByReplacingCharactersInRange:(NSRange){model.length - 3, 3} withString:@"y"];
    } else if ([model hasSuffix:@"ses"]) {
        model = [model stringByReplacingCharactersInRange:(NSRange){model.length - 3, 3} withString:@"s"];
    } else if ([model hasSuffix:@"es"]) {
        model = [model stringByReplacingCharactersInRange:(NSRange){model.length - 2, 2} withString:@"e"];
    } else if ([model hasSuffix:@"s"]) {
        model = [model stringByReplacingCharactersInRange:(NSRange){model.length - 1, 1} withString:@""];
    }

    NSString *firstChar = [model substringToIndex:1];
    model = toCamelCase(model);
    NSString *Model = [model stringByReplacingCharactersInRange:(NSRange){0, 1} withString:[firstChar capitalizedString]];

    NSMutableString *allVars = [[NSMutableString alloc] init];
    NSMutableString *allMaps = [[NSMutableString alloc] init];

    NSString *line;
    while ([scanner scanUpToString:@"\n" intoString:&line]) {
        NSScanner *lineScanner = [NSScanner scannerWithString:line];

        NSString *type;
        lineScanner.scanLocation = 2;
        [lineScanner scanCharactersFromSet:[NSCharacterSet alphanumericCharacterSet] intoString:&type];


        NSString *name;
        [lineScanner scanCharactersFromSet:[NSCharacterSet characterSetWithCharactersInString:@"\""] intoString:nil];
        [lineScanner scanCharactersFromSet:nameCharacterSet intoString:&name];
        NSString *camelName = toCamelCase(name);

        assert(typeMap[type] != nil);
        assert(valueMap[type] != nil);

        [allVars appendFormat:@"    dynamic var %@: %@ = %@\n", camelName, typeMap[type], valueMap[type], nil];
        [allMaps appendFormat:@"        %@ <- map[\"%@\"]\n", camelName, name, nil];
    }

    NSMutableString *output = [NSMutableString stringWithContentsOfFile:[[NSBundle mainBundle] pathForResource:@"output" ofType:@"txt"] encoding:NSUTF8StringEncoding error:nil];
    [output replaceOccurrencesOfString:@"<#Model#>" withString:Model options:0 range:(NSRange){0, output.length}];
    [output replaceOccurrencesOfString:@"<#model#>" withString:model options:0 range:(NSRange){0, output.length}];
    [output replaceOccurrencesOfString:@"<#allVars#>" withString:allVars options:0 range:(NSRange){0, output.length}];
    [output replaceOccurrencesOfString:@"<#allMaps#>" withString:allMaps options:0 range:(NSRange){0, output.length}];

    NSLog(@"%@", output);
    NSString *documentsFolder = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES).firstObject;
    [[NSFileManager defaultManager] createFileAtPath:[NSString stringWithFormat:@"%@/Rmd%@.swift", documentsFolder, Model] contents:[output dataUsingEncoding:NSUTF8StringEncoding] attributes:0];
}

int main(int argc, const char * argv[]) {
    @autoreleasepool {
        NSString *input = [NSString stringWithContentsOfFile:[[NSBundle mainBundle] pathForResource:@"input" ofType:@"txt"] encoding:NSUTF8StringEncoding error:nil];

        NSScanner *scanner = [NSScanner scannerWithString:input];

        NSString *table;

        while ([scanner scanUpToString:@"create_table" intoString:nil]) {
            [scanner scanUpToString:@"end\n" intoString:&table];
            scanTable(table);
        }
    }
    return 0;
}
