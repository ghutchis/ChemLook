/* This code is copyright Geoffrey Hutchison, licensed under the GPL v2.
   It is based in part on QLColorCode by Nathaniel Gray.
 <http://code.google.com/p/qlcolorcode/>
    See LICENSE.txt for details. */

#import <CoreFoundation/CoreFoundation.h>
#import <CoreServices/CoreServices.h>
#import <Foundation/Foundation.h>
#import <QuickLook/QuickLook.h>


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
    
	// We need the path of the bundle to get the HTML template and JavaScript
    CFBundleRef bundle = QLPreviewRequestGetGeneratorBundle(preview);

	// Load the chemlook.html file template as a string for substitution
	CFURLRef templateURL = CFBundleCopyResourceURL(bundle, CFSTR("chemlook.html"), NULL, NULL);
    NSString *templateString = [NSString stringWithContentsOfURL:(NSURL*)templateURL
														encoding:NSUTF8StringEncoding
														   error:&error];
    if (templateString == nil) {
      // an error occurred
      NSLog(@"Error reading template %@\n",
            [error localizedFailureReason]);
    }

	// OK for now, we'll load 250.js as a model molecule
	CFURLRef moleculeURL = CFBundleCopyResourceURL(bundle, CFSTR("benzene.sdf"), NULL, NULL);
    NSString *sdfData = [NSString stringWithContentsOfURL:(NSURL*)moleculeURL
												 encoding:NSUTF8StringEncoding
													error:&error];
    if (sdfData == nil) {
		// an error occurred
		NSLog(@"Error reading molecule %@\n",
			  [error localizedFailureReason]);
    }
	NSString *sdfEscaped = [sdfData stringByReplacingOccurrencesOfString:@"\n"
															  withString:@"\\n"];
	
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
	
	// Now load the JavaScript files
	CFURLRef mainURL = CFBundleCopyResourceURL(bundle, CFSTR("ChemDoodleWeb.js"), NULL, NULL);
	NSString *mainData = [NSString stringWithContentsOfURL:(NSURL*)mainURL
												  encoding:NSUTF8StringEncoding
													 error:&error];
	if (mainData == nil){
		// an error occurred
		NSLog(@"Error reading main %@\n",
			  [error localizedFailureReason]);		
	}	

	// OK, the template has several strings
	NSString *outputString = [NSString stringWithFormat:templateString,
							  libsData,
							  mainData,
							  sdfEscaped,
							  @"Test Molecule",
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
    
done:
    [pool release];
    return noErr;
}

void CancelPreviewGeneration(void* thisInterface, QLPreviewRequestRef preview)
{
    // implement only if supported
}
