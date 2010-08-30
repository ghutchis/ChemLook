/* This code is copyright Geoffrey Hutchison, licensed under the GPL v2.
   It is based in part on QLColorCode by Nathaniel Gray.
 <http://code.google.com/p/qlcolorcode/>
    See LICENSE.txt for details. */

#import <CoreFoundation/CoreFoundation.h>
#import <CoreServices/CoreServices.h>
#import <Foundation/Foundation.h>
#import <QuickLook/QuickLook.h>

#import "Common.h"

/* -----------------------------------------------------------------------------
 Generate a preview for file
 
 This function's job is to create preview for designated file
 ----------------------------------------------------------------------------- */

OSStatus GeneratePreviewForURL(void *thisInterface, QLPreviewRequestRef preview, 
                               CFURLRef url, CFStringRef contentTypeUTI, 
                               CFDictionaryRef options)
{
    if (QLPreviewRequestIsCancelled(preview))
        return noErr;
    
    NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
    NSError *error;
    
	// Save the extension for future comparisons
	CFStringRef extension = CFURLCopyPathExtension(url);
	
	// We need the path of the bundle to get the HTML template and JavaScript
    CFBundleRef bundle = QLPreviewRequestGetGeneratorBundle(preview);

	// Now we load the molecule, but it depends on the extension
	// SDF / MOLfile can be read directly
	// PDB can be read directly, but we use a different JavaScript function in the HTML
	NSString *moleculeData = NULL;
	bool singleMol = true;
	if (CFStringCompare(extension, CFSTR("sdf"), kCFCompareCaseInsensitive) == 0
		|| CFStringCompare(extension, CFSTR("mdl"), kCFCompareCaseInsensitive) == 0
		|| CFStringCompare(extension, CFSTR("mol"), kCFCompareCaseInsensitive) == 0
		|| CFStringCompare(extension, CFSTR("pdb"), kCFCompareCaseInsensitive) == 0) {
		// use this file directly, we can read it using JavaScript
		moleculeData = [NSString stringWithContentsOfURL:(NSURL*)url
														  encoding:NSUTF8StringEncoding
															 error:&error];
		if (moleculeData == nil) {
			// an error occurred
			NSLog(@"Error reading molecule %@\n",
				  [error localizedFailureReason]);
			goto done;
		}		
	} else {
		// We need to pass this through babel to read
		int status;
		// If we have a CDX or CDXML, try to join all molecules into one SDF
		singleMol = !(CFStringCompare(extension, CFSTR("cdx"), kCFCompareCaseInsensitive) == 0
						   || CFStringCompare(extension, CFSTR("cdxml"), kCFCompareCaseInsensitive) == 0);
		
		moleculeData = babelURL(bundle, url, &status, singleMol);
		if (status != 0 || moleculeData == nil) {
			// an error occurred
			NSLog(@"Error reading molecule %@\n",
				  [error localizedFailureReason]);
			goto done;
		}		
	}

	// Load the chemlook.html file template as a string for substitution
	CFURLRef templateURL;
	if (singleMol) {
		templateURL = CFBundleCopyResourceURL(bundle, CFSTR("chemlook.html"), NULL, NULL);
	} else {
		templateURL = CFBundleCopyResourceURL(bundle, CFSTR("chemlook-2d.html"), NULL, NULL);
	}

    NSString *templateString = [NSString stringWithContentsOfURL:(NSURL*)templateURL
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
	NSString *libsData = [NSString stringWithContentsOfURL:(NSURL*)libsURL
												  encoding:NSUTF8StringEncoding
													 error:&error];
	if (libsData == nil){
		// an error occurred
		NSLog(@"Error reading libs %@\n",
			  [error localizedFailureReason]);		
	}
	CFRelease(libsURL);
	
	CFURLRef mainURL = CFBundleCopyResourceURL(bundle, CFSTR("ChemDoodleWeb.js"), NULL, NULL);
	NSString *mainData = [NSString stringWithContentsOfURL:(NSURL*)mainURL
												  encoding:NSUTF8StringEncoding
													 error:&error];
	if (mainData == nil){
		// an error occurred
		NSLog(@"Error reading main %@\n",
			  [error localizedFailureReason]);		
	}
	CFRelease(mainURL);

	NSString *cleanedMol = [moleculeData stringByReplacingOccurrencesOfString:@"\r"
																   withString:@""];
	NSString *escapedMol = [cleanedMol stringByReplacingOccurrencesOfString:@"\n"
																 withString:@"\\n"];

	NSString *readFunction = @"readMOL";
	if (CFStringCompare(extension, CFSTR("pdb"), kCFCompareCaseInsensitive) == 0)
		readFunction = @"readPDB";		
	// OK, the template has several strings, so let's format them
	NSString *outputString = [NSString stringWithFormat:templateString,
							  libsData,
							  mainData,
							  escapedMol,
							  readFunction,
							  nil];

    // Set the properties of the QuickLook view
    // UTF-8 -- not that there's text
    // text/html content to use WebKit preview
    NSMutableDictionary *properties = [[NSMutableDictionary alloc] init];
    [properties setObject:@"UTF-8" forKey:(NSString *)kQLPreviewPropertyTextEncodingNameKey];
    [properties setObject:@"text/html" forKey:(NSString *)kQLPreviewPropertyMIMETypeKey];

	// OK, pass everything along to QuickLook
	// Create a CFDataRef from the in-memory template, then pass back to QuickLook as HTML
	CFDataRef output = CFStringCreateExternalRepresentation(NULL, (CFStringRef)outputString, kCFStringEncodingUTF8, 0);
    QLPreviewRequestSetDataRepresentation(preview,
                                          output, 
                                          kUTTypeHTML, 
                                          (CFDictionaryRef)properties);

	// Free up and clean
done:
    [pool release];
    return noErr;
}

void CancelPreviewGeneration(void* thisInterface, QLPreviewRequestRef preview)
{
    // implement only if supported
}
