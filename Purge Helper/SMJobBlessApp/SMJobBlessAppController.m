/*
 
    File: SMJobBlessAppController.m
Abstract: The main application controller. When the application has finished
launching, the helper tool will be installed.
 Version: 1.2

Disclaimer: IMPORTANT:  This Apple software is supplied to you by Apple
Inc. ("Apple") in consideration of your agreement to the following
terms, and your use, installation, modification or redistribution of
this Apple software constitutes acceptance of these terms.  If you do
not agree with these terms, please do not use, install, modify or
redistribute this Apple software.

In consideration of your agreement to abide by the following terms, and
subject to these terms, Apple grants you a personal, non-exclusive
license, under Apple's copyrights in this original Apple software (the
"Apple Software"), to use, reproduce, modify and redistribute the Apple
Software, with or without modifications, in source and/or binary forms;
provided that if you redistribute the Apple Software in its entirety and
without modifications, you must retain this notice and the following
text and disclaimers in all such redistributions of the Apple Software.
Neither the name, trademarks, service marks or logos of Apple Inc. may
be used to endorse or promote products derived from the Apple Software
without specific prior written permission from Apple.  Except as
expressly stated in this notice, no other rights or licenses, express or
implied, are granted by Apple herein, including but not limited to any
patent rights that may be infringed by your derivative works or by other
works in which the Apple Software may be incorporated.

The Apple Software is provided by Apple on an "AS IS" basis.  APPLE
MAKES NO WARRANTIES, EXPRESS OR IMPLIED, INCLUDING WITHOUT LIMITATION
THE IMPLIED WARRANTIES OF NON-INFRINGEMENT, MERCHANTABILITY AND FITNESS
FOR A PARTICULAR PURPOSE, REGARDING THE APPLE SOFTWARE OR ITS USE AND
OPERATION ALONE OR IN COMBINATION WITH YOUR PRODUCTS.

IN NO EVENT SHALL APPLE BE LIABLE FOR ANY SPECIAL, INDIRECT, INCIDENTAL
OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF
SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS
INTERRUPTION) ARISING IN ANY WAY OUT OF THE USE, REPRODUCTION,
MODIFICATION AND/OR DISTRIBUTION OF THE APPLE SOFTWARE, HOWEVER CAUSED
AND WHETHER UNDER THEORY OF CONTRACT, TORT (INCLUDING NEGLIGENCE),
STRICT LIABILITY OR OTHERWISE, EVEN IF APPLE HAS BEEN ADVISED OF THE
POSSIBILITY OF SUCH DAMAGE.

Copyright (C) 2011 Apple Inc. All Rights Reserved.

 
*/

#import <ServiceManagement/ServiceManagement.h>
#import <Security/Authorization.h>
#import "SMJobBlessAppController.h"

#define kHelperToolId "com.apple.bsd.purge.HelperTool"

@interface SMJobBlessAppController ()

- (BOOL)blessHelperWithLabel:(NSString *)label error:(NSError **)error;

@end

@implementation SMJobBlessAppController

- (void)appendLog:(NSString *)log {
    NSLog(@"%@", log);
}

- (BOOL)isHelperInstalled {
    return ([[NSUserDefaults standardUserDefaults] boolForKey:@"IsHelperInstalled"]);
}

- (void)applicationDidFinishLaunching:(NSNotification *)notification {
    
	NSError *error = nil;
    NSProcessInfo *processInfo = [NSProcessInfo processInfo]; 
    NSArray *arguments = [processInfo arguments];
    
    if(([arguments indexOfObject:@"--install"] != NSNotFound) || (![self isHelperInstalled])){
        if (![self blessHelperWithLabel:@kHelperToolId error:&error]) {
            [self appendLog:[NSString stringWithFormat:@"Failed to bless helper. Error: %@", error]];
            [NSApp terminate:self]; 
        }    
    }
    
    xpc_connection_t connection = [self findConnection];
            
    if (!connection) {
        [self appendLog:@"Failed to create XPC connection."];
        [NSApp terminate:self]; 
    }
    
    [self appendLog:@"Helper available."];
    
    xpc_connection_set_event_handler(connection, ^(xpc_object_t event) {
        xpc_type_t type = xpc_get_type(event);
        if (type == XPC_TYPE_ERROR) {
            if (event == XPC_ERROR_CONNECTION_INTERRUPTED) {
                [self appendLog:@"XPC connection interupted."];[NSApp terminate:self]; 
            } else if (event == XPC_ERROR_CONNECTION_INVALID) {
                [self appendLog:@"XPC connection invalid, releasing."];
                xpc_release(connection);[NSApp terminate:self]; 
            } else {
                [self appendLog:@"Unexpected XPC connection error."];[NSApp terminate:self];
            }
        } else {
            [self appendLog:@"Unexpected XPC connection event."];[NSApp terminate:self];
        }
    });
    
    xpc_connection_resume(connection);
    
    xpc_object_t message = xpc_dictionary_create(NULL, NULL, 0);
    const char* request = "/usr/sbin/purge";
    xpc_dictionary_set_string(message, "request", request);
    
    [self appendLog:[NSString stringWithFormat:@"Sending request: %s", request]];
    
    xpc_connection_send_message_with_reply(connection, message, dispatch_get_main_queue(), ^(xpc_object_t event) {
        const char* response = xpc_dictionary_get_string(event, "reply");
        const char* echo = xpc_dictionary_get_string(event, "echo");
        int64_t result = xpc_dictionary_get_int64(event, "result");
        [self appendLog:[NSString stringWithFormat:@"Received echo: %s.", echo]];        
        [self appendLog:[NSString stringWithFormat:@"Received response: %s.", response]];
        [self appendLog:[NSString stringWithFormat:@"Received result: %d", (int)result]];
        [NSApp terminate:self];  
    });
}

- (xpc_connection_t)findConnection{
    return xpc_connection_create_mach_service(kHelperToolId, NULL, XPC_CONNECTION_MACH_SERVICE_PRIVILEGED);
}

- (BOOL)blessHelperWithLabel:(NSString *)label
                       error:(NSError **)error {
    
	BOOL result = NO;

	AuthorizationItem authItem		= { kSMRightBlessPrivilegedHelper, 0, NULL, 0 };
	AuthorizationRights authRights	= { 1, &authItem };
	AuthorizationFlags flags		=	kAuthorizationFlagDefaults				| 
										kAuthorizationFlagInteractionAllowed	|
										kAuthorizationFlagPreAuthorize			|
										kAuthorizationFlagExtendRights;

	AuthorizationRef authRef = NULL;
	
	/* Obtain the right to install privileged helper tools (kSMRightBlessPrivilegedHelper). */
	OSStatus status = AuthorizationCreate(&authRights, kAuthorizationEmptyEnvironment, flags, &authRef);
	if (status != errAuthorizationSuccess) {
        [self appendLog:[NSString stringWithFormat:@"Failed to create AuthorizationRef. Error code: %ld", (long)status]];
        
	} else {
		/* This does all the work of verifying the helper tool against the application
		 * and vice-versa. Once verification has passed, the embedded launchd.plist
		 * is extracted and placed in /Library/LaunchDaemons and then loaded. The
		 * executable is placed in /Library/PrivilegedHelperTools.
		 */
		result = SMJobBless(kSMDomainSystemLaunchd, (CFStringRef)label, authRef, (CFErrorRef *)error);
	}
	
    NSUserDefaults *standardUserDefaults = [NSUserDefaults standardUserDefaults];
    [standardUserDefaults setBool:result forKey:@"IsHelperInstalled"]; 
    [standardUserDefaults synchronize];

	return result;
}

@end
