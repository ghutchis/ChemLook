/*
 *  GenerateThumbnailForURL.m
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
#import <Cocoa/Cocoa.h>
#import <QuickLook/QuickLook.h>
#import <WebKit/WebKit.h>

#import "Common.h"

/* -----------------------------------------------------------------------------
    Generate a thumbnail for file

   This function's job is to create thumbnail for designated file as fast as possible
   ----------------------------------------------------------------------------- */

OSStatus GenerateThumbnailForURL(void *thisInterface, QLThumbnailRequestRef thumbnail, CFURLRef url, CFStringRef contentTypeUTI, CFDictionaryRef options, CGSize maxSize) {
    @autoreleasepool {

        // Use Open Babel to generate SVG representation as string
        NSError *error = 0;
        NSString *svg = ThumbnailURL((__bridge NSURL *)url, error);
        if (error != nil || svg == nil) {
            NSLog(@"Error generating preview: %@", [error localizedFailureReason]);
            return noErr;
        }

        // Render as if there is a 600x800px window
        NSRect renderRect = NSMakeRect(0.0, 0.0, 600.0, 800.0);
        float scale = maxSize.height / 800.0;
        NSSize scaleSize = NSMakeSize(scale, scale);
        CGSize thumbSize = NSSizeToCGSize(NSMakeSize((maxSize.width * (600.0/800.0)), maxSize.height));

        // Create WebView with SVG data
        WebView *webView = [[WebView alloc] initWithFrame:renderRect];
        [webView scaleUnitSquareToSize:scaleSize];
        [[[webView mainFrame] frameView] setAllowsScrolling:NO];
        NSData *svgData = [svg dataUsingEncoding:NSUTF8StringEncoding];
        [[webView mainFrame] loadData:svgData MIMEType:@"image/svg+xml" textEncodingName:@"UTF-8" baseURL:nil];
        while([webView isLoading]) {
            CFRunLoopRunInMode(kCFRunLoopDefaultMode, 0, true);
        }

        // Draw WebView in NSGraphicsContext
        CGContextRef context = QLThumbnailRequestCreateContext(thumbnail, thumbSize, false, NULL);
        if (context != NULL) {
            NSGraphicsContext *nsContext = [NSGraphicsContext graphicsContextWithGraphicsPort:(void*)context flipped:[webView isFlipped]];
            [webView displayRectIgnoringOpacity:[webView bounds] inContext:nsContext];
            QLThumbnailRequestFlushContext(thumbnail, context);
            CFRelease(context);
        }
        return noErr;
    }
}

void CancelThumbnailGeneration(void* thisInterface, QLThumbnailRequestRef thumbnail) {
    // implement only if supported
}
 
