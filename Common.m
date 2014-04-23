/*
 *  Common.m
 *  Part of ChemLook
 *  Copyright 2010-2014 Geoffrey Hutchison
 *  Some portions Copyright 2014 Matt Swain
 *  Licensed under the GPL v2
 * 
 *  Based on QLColorCode
 *  Copyright 2007 Nathaniel Gray
 *
 */

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

NSString *MolDataFromOpenBabel(NSURL *url, NSString *options) {
    int status;
    NSString *cmd = [NSString stringWithFormat:@"'/usr/local/bin/obabel' '%@' %@", [[url absoluteURL] path], options];
    NSString *output = RunTask(cmd, &status);
    if (status != 0) {
        NSLog(@"Error running command: %@", cmd);
        return nil;
    }
    return output;
}

NSString *TextFromBundle(CFBundleRef bundle, NSString *filename, NSError *error) {
    CFURLRef url = CFBundleCopyResourceURL(bundle, (__bridge CFStringRef)filename, NULL, NULL);
    NSString *text = [NSString stringWithContentsOfURL:(__bridge_transfer NSURL *)url encoding:NSUTF8StringEncoding error:&error];
    return text;
}

NSString *EscapeStringForJavascript(NSString *string) {
    if (string == nil) {
        return @"";
    }
    return [[[[string stringByReplacingOccurrencesOfString:@"\\" withString:@"\\\\"]
               stringByReplacingOccurrencesOfString:@"\n" withString:@"\\n"]
              stringByReplacingOccurrencesOfString:@"'" withString:@"\\'"]
              stringByReplacingOccurrencesOfString:@"\r" withString:@""];
}

NSString *PreviewURL(CFBundleRef bundle, NSURL *url, NSError *error) {
    NSString *extension = [[[url path] pathExtension] lowercaseString];

    // Use Open Babel to generate ChemDoodle JSON from file contents
    NSString *options = @"-ocdjson -l 20";
    if ([@[@"smiles", @"smi", @"inchi"] containsObject:extension]) {
        options = [options stringByAppendingString:@" --gen2d"];
    }
    NSString *cdjson = MolDataFromOpenBabel(url, options);

    // Read the raw file contents if Open Babel failed or if a cif (for unit cell info)
    NSString *raw = nil;
    if ((cdjson == nil) || [extension isEqualToString:@"cif"]) {
        // Only worth reading the raw file contents if ChemDoodle supports the format
        if ([@[@"sdf", @"sd", @"mdl", @"mol", @"cif", @"pdb", @"xyz"] containsObject:extension]) {
            raw = [NSString stringWithContentsOfURL:url encoding:NSUTF8StringEncoding error:&error];
        }
    }
    if (cdjson == nil && raw == nil) {
        return nil;
    }
    
    // Escape strings to insert into template as javascript variables
    raw = EscapeStringForJavascript(raw);
    cdjson = EscapeStringForJavascript(cdjson);

    // Load the template file as a string for substitution
    NSString *template = TextFromBundle(bundle, @"chemlook.html", error);
    NSString *chemdoodle = TextFromBundle(bundle, @"ChemDoodleWeb.js", error);
    if (template == nil || chemdoodle == nil) {
        return nil;
    }

    // Insert variables into template
	NSString *output = [NSString stringWithFormat:template, chemdoodle, raw, cdjson, extension];
    return output;
}

NSString *ThumbnailURL(NSURL *url, NSError *error) {

    // Don't bother generating thumbnail for some formats
    NSString *extension = [[[url path] pathExtension] lowercaseString];
    if ([@[@"pdb"] containsObject:extension]) {
        return nil;
    }

    // Use Open Babel to generate SVG from file contents
    NSString *options = @"-osvg -xd -xA -xC -xN 1 -xP 600";
    NSString *svg = MolDataFromOpenBabel(url, options);
    return svg;
}
