#import "HelperTool.h"

#import "Common.h"

@interface HelperTool () <NSXPCListenerDelegate, HelperToolProtocol>

@property (atomic, strong, readwrite) NSXPCListener *    listener;

@end

@implementation HelperTool

- (id)init
{
	self = [super init];
	if (self != nil) {
		// Set up our XPC listener to handle requests on our Mach service.
		self->_listener = [[NSXPCListener alloc] initWithMachServiceName:kHelperToolMachServiceName];
		self->_listener.delegate = self;
	}
	return self;
}

- (void)run
{
	// Tell the XPC listener to start processing requests.
	
	[self.listener resume];
	
	// Run the run loop forever.
	
	[[NSRunLoop currentRunLoop] run];
}

- (BOOL)listener:(NSXPCListener *)listener shouldAcceptNewConnection:(NSXPCConnection *)newConnection
// Called by our XPC listener when a new connection comes in.  We configure the connection
// with our protocol and ourselves as the main object.
{
	assert(listener == self.listener);
#pragma unused(listener)
	assert(newConnection != nil);
	
	newConnection.exportedInterface = [NSXPCInterface interfaceWithProtocol:@protocol(HelperToolProtocol)];
	newConnection.exportedObject = self;
	[newConnection resume];
	
	return YES;
}

- (NSError *)checkAuthorization:(NSData *)authData command:(SEL)command
// Check that the client denoted by authData is allowed to run the specified command.
// authData is expected to be an NSData with an AuthorizationExternalForm embedded inside.
{
#pragma unused(authData)
	NSError *                   error;
	OSStatus                    err;
	OSStatus                    junk;
	AuthorizationRef            authRef;
	
	assert(command != nil);
	
	authRef = NULL;
	
	// First check that authData looks reasonable.
	
	error = nil;
	if ( (authData == nil) || ([authData length] != sizeof(AuthorizationExternalForm)) ) {
		error = [NSError errorWithDomain:NSOSStatusErrorDomain code:paramErr userInfo:nil];
	}
	
	// Create an authorization ref from that the external form data contained within.
	
	if (error == nil) {
		err = AuthorizationCreateFromExternalForm([authData bytes], &authRef);
		
		// Authorize the right associated with the command.
		
		if (err == errAuthorizationSuccess) {
			AuthorizationItem   oneRight = { NULL, 0, NULL, 0 };
			AuthorizationRights rights   = { 1, &oneRight };
			
			oneRight.name = [[Common authorizationRightForCommand:command] UTF8String];
			assert(oneRight.name != NULL);
			
			err = AuthorizationCopyRights(
																		authRef,
																		&rights,
																		NULL,
																		kAuthorizationFlagExtendRights | kAuthorizationFlagInteractionAllowed,
																		NULL
																		);
		}
		if (err != errAuthorizationSuccess) {
			error = [NSError errorWithDomain:NSOSStatusErrorDomain code:err userInfo:nil];
		}
	}
	
	if (authRef != NULL) {
		junk = AuthorizationFree(authRef, 0);
		assert(junk == errAuthorizationSuccess);
	}
	
	return error;
}

#pragma mark * HelperToolProtocol implementation

// IMPORTANT: NSXPCConnection can call these methods on any thread.  It turns out that our
// implementation of these methods is thread safe but if that's not the case for your code
// you have to implement your own protection (for example, having your own serial queue and
// dispatching over to it).

- (void)connectWithEndpointReply:(void (^)(NSXPCListenerEndpoint *))reply
// Part of the HelperToolProtocol.  Not used by the standard app (it's part of the sandboxed
// XPC service support).  Called by the XPC service to get an endpoint for our listener.  It then
// passes this endpoint to the app so that the sandboxed app can talk us directly.
{
	reply([self.listener endpoint]);
}

- (void)getVersionWithReply:(void(^)(NSString * version))reply
// Part of the HelperToolProtocol.  Returns the version number of the tool.  Note that never
// requires authorization.
{
	// We specifically don't check for authorization here.  Everyone is always allowed to get
	// the version of the helper tool.
	reply([[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleVersion"]);
}

- (void)doItForPath:(NSString *)path withReply:(void(^)(NSNumber * pid))reply
{
	int pid = 0;
	
	NSTask *task = [[NSTask alloc]init];
	task.launchPath = path;
	[task launch];
	pid = [task processIdentifier];
	
	reply([NSNumber numberWithInt:pid]);
}

- (void)doItForPath:(NSString *)path authorization:(NSData *)authData withReply:(void(^)(NSError * error, NSNumber * pid))reply
{
	NSError *error = [self checkAuthorization:authData command:_cmd];

	int pid = 0;
	
	if (error == nil)
	{
		/* system([path UTF8String]); */
		/* [NSTask launchedTaskWithLaunchPath:path arguments:@[]]; */
		NSTask *task = [[NSTask alloc]init];
		task.launchPath = path;
		[task launch];
		pid = [task processIdentifier];
	}
	
	reply(error, [NSNumber numberWithInt:pid]);
}

@end
