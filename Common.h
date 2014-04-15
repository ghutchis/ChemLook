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

NSString *PreviewURL(CFBundleRef bundle, NSURL *url, NSError *error, bool thumbnail);
