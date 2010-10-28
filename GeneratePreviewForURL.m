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
    	
	// We need the path of the bundle to get the HTML template and JavaScript
    CFBundleRef bundle = QLPreviewRequestGetGeneratorBundle(preview);

	NSString *outputString = PreviewUrl(url, bundle);
    
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
