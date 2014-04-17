/*
 *  GeneratePreviewForURL.m
 *  Part of ChemLook
 *  Copyright 2010-2014 Geoffrey Hutchison
 *  Some portions Copyright 2014 Matt Swain
 *  Licensed under the GPL v2
 *
 *  Based on QLColorCode
 *  Copyright 2007 Nathaniel Gray
 *
 */

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

        NSLog(@"%@", contentTypeUTI);
        
        // We need the path of the bundle to get the HTML template and JavaScript
        CFBundleRef bundle = QLPreviewRequestGetGeneratorBundle(preview);
        NSError *error = 0;
        NSString *outputString = PreviewURL(bundle, (__bridge NSURL *)url, error, false);
        NSLog(@"%@", outputString);
        if (error != nil || outputString == nil) {
            NSLog(@"Error generating preview: %@", [error localizedFailureReason]);
            return noErr;
        }

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
