/*
 *  Common.c
 *  Part of ChemLook
 *   by Geoffrey Hutchison
 * 
 *  Based on: QLColorCode
 *  Created by Nathaniel Gray on 12/6/07.
 *  Copyright 2007 Nathaniel Gray.
 *
 */

#import <CoreFoundation/CoreFoundation.h>
#import <CoreServices/CoreServices.h>
#import <Foundation/Foundation.h>
#import <limits.h>  // PATH_MAX

#include "Common.h"

NSString *runTask(NSString *script, NSDictionary *env, int *exitCode) {
    NSTask *task = [[NSTask alloc] init];
    [task setCurrentDirectoryPath:@"/tmp"];     /* XXX: Fix this */
    [task setEnvironment:env];
    [task setLaunchPath:@"/bin/sh"];
    [task setArguments:[NSArray arrayWithObjects:@"-c", script, nil]];
    
    NSPipe *pipe;
    pipe = [NSPipe pipe];
    [task setStandardOutput: pipe];
    // Let stderr go to the usual place
    //[task setStandardError: pipe];
    
    NSFileHandle *file;
    file = [pipe fileHandleForReading];
    
    [task launch];
    
    NSData *data;
    data = [file readDataToEndOfFile];
    [task waitUntilExit];
    
    *exitCode = [task terminationStatus];
    [task release];
    /* The docs claim this isn't needed, but we leak descriptors otherwise */
    [file closeFile];
    /*[pipe release];*/
    
	NSString* output = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
    return output;
}

NSString *pathOfURL(CFURLRef url)
{
    NSString *targetCFS = [[(NSURL *)url absoluteURL] path];
    return targetCFS;
}

NSString *babelURL(CFBundleRef bundle, CFURLRef url, int *status)
{
    NSString *output = NULL;
    NSString *targetEsc = pathOfURL(url);
    
    // Set up preferences
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    NSMutableDictionary *env = [NSMutableDictionary dictionaryWithDictionary:
                                [[NSProcessInfo processInfo] environment]];
	[env addEntriesFromDictionary:[defaults persistentDomainForName:myDomain]];
    
    NSString *cmd = [NSString stringWithFormat:
                     @"'/usr/local/bin/babel' -l 1 -xs '%@' -omol", 
                     targetEsc];
    
    output = runTask(cmd, env, status);
    if (*status != 0) {
        NSLog(@"ChemLook: babel failed with exit code %d.  Command was (%@).", 
              *status, cmd);
    }
    return output;
}
