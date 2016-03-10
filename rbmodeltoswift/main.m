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

int main(int argc, const char * argv[]) {
    @autoreleasepool {
        NSDictionary *typeMap = @{@"text": @"String",
                                  @"string": @"String",
                                  @"integer": @"Int",
                                  @"datetime": @"NSDate",
                                  @"boolean": @"Bool",
                                  @"float": @"CGFloat"
                                  };
        NSDictionary *valueMap = @{@"text": @"\"\"",
                                   @"string": @"\"\"",
                                   @"integer": @"0",
                                   @"datetime": @"NSDate()",
                                   @"boolean": @"false",
                                   @"float": @"0"
                                   };

        NSMutableCharacterSet *nameCharacterSet = [NSMutableCharacterSet alphanumericCharacterSet];
        [nameCharacterSet  addCharactersInString:@"_"];

        NSString *input = [NSString stringWithContentsOfFile:[[NSBundle mainBundle] pathForResource:@"input" ofType:@"txt"] encoding:NSUTF8StringEncoding error:nil];

        NSScanner *scanner = [[NSScanner alloc] initWithString:input];

        NSString *firstLine;
        [scanner scanUpToString:@"\n" intoString:&firstLine];
        NSScanner *firstLineScanner = [NSScanner scannerWithString:firstLine];
        NSString *model;
        [firstLineScanner scanUpToCharactersFromSet:[NSCharacterSet characterSetWithCharactersInString:@"\""] intoString:nil];
        firstLineScanner.scanLocation++;
        [firstLineScanner scanCharactersFromSet:nameCharacterSet intoString:&model];
        model = toCamelCase(model);
        NSString *Model = [model capitalizedString];

        NSMutableString *allVars = [[NSMutableString alloc] init];
        NSMutableString *allMaps = [[NSMutableString alloc] init];

        NSString *line;
        while ([scanner scanUpToString:@"\n" intoString:&line]) {
            if ([line isEqualToString:@"end"]) break;

            NSScanner *lineScanner = [NSScanner scannerWithString:line];

            NSString *type;
            lineScanner.scanLocation = 2;
            [lineScanner scanCharactersFromSet:[NSCharacterSet alphanumericCharacterSet] intoString:&type];


            NSString *name;
            [lineScanner scanCharactersFromSet:[NSCharacterSet characterSetWithCharactersInString:@"\""] intoString:nil];
            [lineScanner scanCharactersFromSet:nameCharacterSet intoString:&name];
            NSString *camelName = toCamelCase(name);

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
    return 0;
}
