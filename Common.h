/*
 *  Common.h
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
#import <Foundation/Foundation.h>

NSString *PreviewURL(CFBundleRef bundle, NSURL *url, NSError *error);
NSString *ThumbnailURL(NSURL *url, NSError *error);
