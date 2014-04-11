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

OSStatus GeneratePreviewForURL(void *thisInterface, QLPreviewRequestRef preview, CFURLRef url, CFStringRef contentTypeUTI, CFDictionaryRef options) {
    @autoreleasepool {
        if (QLPreviewRequestIsCancelled(preview))
            return noErr;
        
        // We need the path of the bundle to get the HTML template and JavaScript
        CFBundleRef bundle = QLPreviewRequestGetGeneratorBundle(preview);
        NSError *error = 0;
        NSString *outputString = PreviewUrl(bundle, (__bridge NSURL *)url, error, false);
        
        // Set the properties of the QuickLook view
        CFDictionaryRef properties = (__bridge CFDictionaryRef)@{
            (NSString *)kQLPreviewPropertyTextEncodingNameKey: @"UTF-8",
            (NSString *)kQLPreviewPropertyMIMETypeKey: @"text/html"
        };
        
        // Create a CFDataRef from the in-memory template, then pass back to QuickLook as HTML
        CFDataRef output = CFStringCreateExternalRepresentation(NULL, (CFStringRef)outputString, kCFStringEncodingUTF8, 0);
        QLPreviewRequestSetDataRepresentation(preview, output, kUTTypeHTML, properties);
        CFRelease(output);
        return noErr;
    }
}

void CancelPreviewGeneration(void* thisInterface, QLPreviewRequestRef preview) {
    // implement only if supported
}
