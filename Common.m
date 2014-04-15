/*
 *  Common.m
 *  Part of ChemLook
 *   by Geoffrey Hutchison
 * 
 *  Based on: QLColorCode
 *  Created by Nathaniel Gray on 12/6/07.
 *  Copyright 2007 Nathaniel Gray.
 *
 */

#import <CoreFoundation/CoreFoundation.h>
#import <CoreServices/CoreServices.h>
#import <Foundation/Foundation.h>

#include "Common.h"

NSString *RunTask(NSString *cmd, int *status) {
    NSTask *task = [[NSTask alloc] init];
    [task setEnvironment:[[NSProcessInfo processInfo] environment]];
    [task setCurrentDirectoryPath:@"/tmp"];
    [task setLaunchPath:@"/bin/sh"];
    [task setArguments:@[@"-c", cmd]];
    NSPipe *pipe = [NSPipe pipe];
    [task setStandardOutput: pipe];
    NSFileHandle *file = [pipe fileHandleForReading];
    [task launch];
    NSData *data = [file readDataToEndOfFile];
    [task waitUntilExit];
    *status = [task terminationStatus];
    [file closeFile];
	NSString* output = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
    return output;
}

NSString *MolDataFromOpenBabel(NSURL *url) {
    int status;
    NSString *cmd = [NSString stringWithFormat:@"'/usr/local/bin/obabel' '%@' -ocdjson -l 20", [[url absoluteURL] path]];
    NSString *output = RunTask(cmd, &status);
    if (status != 0) {
        NSLog(@"Error running command: %@", cmd);
        return nil;
    }
    return output;
}

NSString *TextFromBundle(CFBundleRef bundle, NSString *filename, NSError *error) {
    CFURLRef url = CFBundleCopyResourceURL(bundle, (__bridge CFStringRef)filename, NULL, NULL);
    NSString *text = [NSString stringWithContentsOfURL:(__bridge NSURL *)url encoding:NSUTF8StringEncoding error:&error];
    return text;
}

NSString *PreviewURL(CFBundleRef bundle, NSURL *url, NSError *error, bool thumbnail) {
    
    // Use Open Babel to generate ChemDoodle JSON from file contents
    NSString *molData = MolDataFromOpenBabel(url);
    NSString *readFunc = @"ChemDoodle.readJSON";
    
    // If Open Babel fails, read certain file format contents directly
    NSString *extension = [[[url path] pathExtension] lowercaseString];
    if (molData == nil && [@[@"sdf", @"mdl", @"mol", @"cif", @"pdb", @"xyz"] containsObject:extension]) {
        molData = [NSString stringWithContentsOfURL:url encoding:NSUTF8StringEncoding error:&error];
        if (error != nil || molData == nil) {
            return nil;
        }
        if ([extension isEqualToString:@"pdb"]) {
            readFunc = @"ChemDoodle.readPDB";
        } else if ([extension isEqualToString:@"cif"]) {
            readFunc = @"ChemDoodle.readCIF";
        } else if ([extension isEqualToString:@"xyz"]) {
            readFunc = @"ChemDoodle.readXYZ";
        } else {
            readFunc = @"ChemDoodle.readMOL";
        }
    }

    // Escape molData to insert as javascript variable in template
    molData = [[[molData stringByReplacingOccurrencesOfString:@"\n" withString:@"\\n"]
                         stringByReplacingOccurrencesOfString:@"'" withString:@"\\'"]
                         stringByReplacingOccurrencesOfString:@"\r" withString:@""];

    // Load the template file as a string for substitution
    NSString *templateName = thumbnail ? @"chemlook-thumb.html" : @"chemlook.html";
    NSString *template = TextFromBundle(bundle, templateName, error);
    NSString *chemdoodle = TextFromBundle(bundle, @"ChemDoodleWeb.js", error);
    if (template == nil || chemdoodle == nil) {
        return nil;
    }

    // Insert variables into template
	NSString *output = [NSString stringWithFormat:template, chemdoodle, molData, readFunc];
    return output;
}
