/*
 *  Common.h
 *  Part of ChemLook
 *   by Geoffrey Hutchison
 * 
 *  Based on: QLColorCode
 *  Created by Nathaniel Gray on 12/6/07.
 *  Copyright 2007 Nathaniel Gray.
 *
 */
#import <CoreFoundation/CoreFoundation.h>
#import <Foundation/Foundation.h>

#define myDomain @"net.openmolecules.ChemLook"

// Status is 0 on success, nonzero on error (like a shell command)
NSString *babelURL(CFBundleRef myBundle, NSURL *url, int *status, bool singleMol);
NSString *PreviewUrl(CFBundleRef myBundle, NSURL *url, NSError *error, bool thumbnail);
