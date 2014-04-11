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

NSString *runTask(NSString *script, NSDictionary *env, int *exitCode) {
    NSTask *task = [[NSTask alloc] init];
    [task setCurrentDirectoryPath:@"/tmp"];     /* XXX: Fix this */
    [task setEnvironment:env];
    [task setLaunchPath:@"/bin/sh"];
    [task setArguments:[NSArray arrayWithObjects:@"-c", script, nil]];
    
    NSPipe *pipe;
    pipe = [NSPipe pipe];
    [task setStandardOutput: pipe];
    // Let stderr go to the usual place
    //[task setStandardError: pipe];
    
    NSFileHandle *file;
    file = [pipe fileHandleForReading];
    
    [task launch];
    
    NSData *data;
    data = [file readDataToEndOfFile];
    [task waitUntilExit];
    
    *exitCode = [task terminationStatus];
    
    /* The docs claim this isn't needed, but we leak descriptors otherwise */
    [file closeFile];
    
	NSString* output = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
    return output;
}

NSString *pathOfURL(CFURLRef url) {
    NSString *targetCFS = [[(__bridge NSURL *)url absoluteURL] path];
    return targetCFS;
}

NSString *babelURL(CFBundleRef bundle, CFURLRef url, int *status, bool singleMol) {
    NSString *output = NULL;
    NSString *targetEsc = pathOfURL(url);
    
    // Set up preferences
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    NSMutableDictionary *env = [NSMutableDictionary dictionaryWithDictionary:
                                [[NSProcessInfo processInfo] environment]];
	[env addEntriesFromDictionary:[defaults persistentDomainForName:myDomain]];
    
    NSString *cmd = [NSString stringWithFormat:
                     @"'/usr/local/bin/babel' %@ '%@' -omol",
					 singleMol ? @"-l 1" : @"--join",
                     targetEsc];
    
    output = runTask(cmd, env, status);
    if (*status != 0) {
        NSLog(@"ChemLook: babel failed with exit code %d.  Command was (%@).", *status, cmd);
    }
    return output;
}

NSString *PreviewUrl(CFBundleRef bundle, NSURL *url, NSError *error, bool thumbnail) {
	// Save the extension for future comparisons
	//CFStringRef extension = CFURLCopyPathExtension(url);
    NSString *extension = [[[url path] pathExtension] lowercaseString];
	
	// Now we load the molecule, but it depends on the extension
	// SDF / MOLfile can be read directly
	// PDB can be read directly, but we use a different JavaScript function in the HTML
	NSString *moleculeData = NULL;
	bool singleMol = true;
    
    // TODO: Pass SDF through Open Babel because ChemDoodle only reads first molecule
    NSArray* formats = @[@"sdf", @"mdl", @"mol", @"cif", @"pdb"];
	if ([formats containsObject:extension]) {
		// use this file directly, we can read it using JavaScript
		moleculeData = [NSString stringWithContentsOfURL:url encoding:NSUTF8StringEncoding error:&error];
		if (moleculeData == nil) {
			NSLog(@"Error reading molecule %@", [error localizedFailureReason]);
			return nil;
		}		
	} else {
		// We need to pass this through babel to read
		int status;
		// If we have a CDX or CDXML, try to join all molecules into one SDF
		singleMol = !([@[@"cdx", @"cdxml"] containsObject:extension]);
		moleculeData = babelURL(bundle, url, &status, singleMol);
		if (status != 0 || moleculeData == nil) {
			NSLog(@"Error reading molecule %@", [error localizedFailureReason]);
			return nil;
		}		
	}
    	
	// Load the chemlook.html file template as a string for substitution
	CFURLRef templateURL;
	if (!thumbnail) {
		if (singleMol) {
			templateURL = CFBundleCopyResourceURL(bundle, CFSTR("chemlook.html"), NULL, NULL);
		} else {
			templateURL = CFBundleCopyResourceURL(bundle, CFSTR("chemlook-2d.html"), NULL, NULL);
		}
	} else {
		templateURL = CFBundleCopyResourceURL(bundle, CFSTR("chemlook-thumb.html"), NULL, NULL);
	}
	
    NSString *templateString = [NSString stringWithContentsOfURL:(__bridge NSURL*)templateURL
														encoding:NSUTF8StringEncoding
														   error:&error];
    if (templateString == nil) {
		// an error occurred
		NSLog(@"Error reading template %@\n",
			  [error localizedFailureReason]);
    }
	CFRelease(templateURL);
	
	// Now load the JavaScript files
	CFURLRef libsURL = CFBundleCopyResourceURL(bundle, CFSTR("ChemDoodleWeb-libs.js"), NULL, NULL);
	NSString *libsData = [NSString stringWithContentsOfURL:(__bridge NSURL*)libsURL
												  encoding:NSUTF8StringEncoding
													 error:&error];
	if (libsData == nil){
		// an error occurred
		NSLog(@"Error reading libs %@\n",
			  [error localizedFailureReason]);		
	}
	CFRelease(libsURL);
	
	CFURLRef mainURL = CFBundleCopyResourceURL(bundle, CFSTR("ChemDoodleWeb.js"), NULL, NULL);
	NSString *mainData = [NSString stringWithContentsOfURL:(__bridge NSURL*)mainURL
												  encoding:NSUTF8StringEncoding
													 error:&error];
	if (mainData == nil){
		// an error occurred
		NSLog(@"Error reading main %@\n",
			  [error localizedFailureReason]);		
	}
	CFRelease(mainURL);
	
	NSString *escapedMol = [[[moleculeData stringByReplacingOccurrencesOfString:@"\n"
																 withString:@"\\n"]
                            stringByReplacingOccurrencesOfString:@"'"
                            withString:@"\\'"]
                            stringByReplacingOccurrencesOfString:@"\r"
                            withString:@""];
	
	NSString *readFunction = @"ChemDoodle.readMOL";
	if (CFStringCompare(extension, CFSTR("pdb"), kCFCompareCaseInsensitive) == 0)
		readFunction = @"ChemDoodle.readPDB";
    else if (CFStringCompare(extension, CFSTR("cif"), kCFCompareCaseInsensitive) == 0)
        readFunction = @"ChemDoodle.readCIF";
	// OK, the template has several strings, so let's format them
	NSString *outputString = [NSString stringWithFormat:templateString,
								  libsData,
								  mainData,
								  escapedMol,
								  readFunction,
								  nil];
		
    CFRelease(extension);
    return outputString;
}
