//
//  main.m
//  com.4D.purge.proxy
//
//  Created by miyako on 2017/11/23.
//
//

#import <Foundation/Foundation.h>

#include "HelperTool.h"

NSString *purgePath()
{
	NSString *purgePath = @"";
	
	NSPipe *pipe = [NSPipe pipe];
	NSFileHandle *file = pipe.fileHandleForReading;
	NSTask *task = [[NSTask alloc]init];
	task.launchPath = @"/usr/bin/which";
	task.arguments = @[@"purge"];
	task.standardOutput = pipe;
	[task launch];
	
	NSData *data = [file readDataToEndOfFile];
	[file closeFile];
	
	if([data length])
	{
		NSString *path = [[NSString alloc]initWithData:data
																					encoding:NSUTF8StringEncoding];
		purgePath = [path stringByReplacingOccurrencesOfString:@"\n" withString:@""];
	}
	
	return purgePath;
}

int main(int argc, const char * argv[])
{
	__block int purge_pid = 0;
	
	@autoreleasepool
	{
		NSXPCConnection *helperToolConnection = [[NSXPCConnection alloc]initWithMachServiceName:kHelperToolMachServiceName
																																										options:NSXPCConnectionPrivileged];

		if(helperToolConnection)
		{
			NSXPCInterface *remoteObjectInterface = [NSXPCInterface interfaceWithProtocol:@protocol(HelperToolProtocol)];
			if(remoteObjectInterface)
			{
				helperToolConnection.remoteObjectInterface = remoteObjectInterface;
				HelperTool *helperTool = [helperToolConnection remoteObjectProxyWithErrorHandler:^(NSError * proxyError)
																	{
																		NSLog(@"remoteObjectProxyError:%@", proxyError);
																	}];
				if(helperTool)
				{
					[helperToolConnection resume];
					[helperTool doItForPath:purgePath()
												withReply:^(NSNumber * pid){
													purge_pid = [pid intValue];
													printf("%d", purge_pid);
													CFRunLoopStop(CFRunLoopGetMain());
												}];
					CFRunLoopRun();
					[helperToolConnection suspend];
					[helperToolConnection invalidate];
					helperToolConnection.remoteObjectInterface = nil;
					helperTool = nil;
				}/* helperTool */
				remoteObjectInterface = nil;
			}/* remoteObjectInterface */
			helperToolConnection = nil;
		}/* helperToolConnection */
	}
	return 0;
}
