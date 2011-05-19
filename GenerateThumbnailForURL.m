
#include <CoreFoundation/CoreFoundation.h>
#include <CoreServices/CoreServices.h>
#include <QuickLook/QuickLook.h>
#include <WebKit/WebKit.h>

#import "Common.h"

#define minSize 32
#define windowSize 512.0

/* -----------------------------------------------------------------------------
    Generate a thumbnail for file

   This function's job is to create thumbnail for designated file as fast as possible
   ----------------------------------------------------------------------------- */

OSStatus 
GenerateThumbnailForURL(void *thisInterface, 
                                 QLThumbnailRequestRef thumbnail, 
                                 CFURLRef url, 
                                 CFStringRef contentTypeUTI, 
                                 CFDictionaryRef options, 
                                 CGSize maxSize)
{
	return noErr;
  // The code doesn't seem to work, we always get black thumbnails

	// For some reason we seem to get called for small thumbnails even though
	// we put a min size in our .plist file...
	if (maxSize.width < minSize || maxSize.height < minSize)
		return noErr;
	NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
	NSError *error;
	
	// Render as though there is an 512x512 window, and fill the thumbnail 
	// vertically.
	
	NSRect renderRect = NSMakeRect(0.0, 0.0, windowSize, windowSize);
	float scale = maxSize.height/windowSize;
	NSSize scaleSize = NSMakeSize(scale, scale);
	CGSize thumbSize = NSSizeToCGSize(NSMakeSize(maxSize.width, maxSize.height));
	
	// Based on example code from quicklook-dev mailing list
	// NSSize previewSize = NSSizeFromCGSize(maxSize);
	CFBundleRef bundle = QLThumbnailRequestGetGeneratorBundle(thumbnail);
	NSString *outputString = PreviewUrl(bundle, url, error, true);
	
	CFDataRef data = CFStringCreateExternalRepresentation(NULL, (CFStringRef)outputString, kCFStringEncodingUTF8, 0);
	
	//NSRect previewRect;
	//previewRect.size = previewSize;
	
	WebView* webView = [[WebView alloc] initWithFrame:renderRect];
	[webView scaleUnitSquareToSize:scaleSize];
	[[[webView mainFrame] frameView] setAllowsScrolling:NO];
	
	[[webView mainFrame] loadData:(NSData*)data MIMEType:@"text/html"
				 textEncodingName:@"UTF-8" baseURL:nil];
	
	while([webView isLoading]) {
		CFRunLoopRunInMode(kCFRunLoopDefaultMode, 0, true);
	}
	
	// Get a context to render into
	CGContextRef context = 
	QLThumbnailRequestCreateContext(thumbnail, thumbSize, false, NULL);
	
	if(context != NULL) {
		NSGraphicsContext* nsContext = 
		[NSGraphicsContext
		 graphicsContextWithGraphicsPort:(void *)context 
		 flipped:[webView isFlipped]];
		
		[webView displayRectIgnoringOpacity:[webView bounds]
								  inContext:nsContext];
		
		QLThumbnailRequestFlushContext(thumbnail, context);
		
		CFRelease(context);
	}
	
	[pool release];
	return noErr;
}

void CancelThumbnailGeneration(void* thisInterface, 
                               QLThumbnailRequestRef thumbnail)
{
    // implement only if supported
}
 
