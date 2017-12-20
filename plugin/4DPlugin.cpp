/* --------------------------------------------------------------------------------
 #
 #	4DPlugin.cpp
 #	source generated by 4D Plugin Wizard
 #	Project : Purge
 #	author : miyako
 #	2017/11/22
 #
 # --------------------------------------------------------------------------------*/


#include "4DPluginAPI.h"
#include "4DPlugin.h"

#define PURGE_PROXY_NAME @"com.4D.purge.proxy"
#define PURGE_PLUGIN_UTI @"com.4D.purge.plugin"
#define PURGE_INSTALLER_NAME @"Purge.app"

#pragma mark Information

NSString *helperToolPath()
{
	NSArray *paths = NSSearchPathForDirectoriesInDomains(NSLibraryDirectory, NSLocalDomainMask, YES);
	
	return [[[paths objectAtIndex:0]
					 stringByAppendingPathComponent:@"PrivilegedHelperTools"]
					stringByAppendingPathComponent:kHelperToolMachServiceName];
}

NSString *proxyPath()
{
	NSBundle *thisBundle = [NSBundle bundleWithIdentifier:PURGE_PLUGIN_UTI];
	if(thisBundle)
	{
		NSURL *proxyURL = [[[thisBundle executableURL] URLByDeletingLastPathComponent]
										 URLByAppendingPathComponent:PURGE_PROXY_NAME];
		if(proxyURL)
		{
			return [proxyURL path];
		}
	}
	return @"";
}

BOOL isHelperToolInstalled()
{
	return [[NSFileManager defaultManager]fileExistsAtPath:helperToolPath()];
}

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
	[task release];
	
	NSData *data = [file readDataToEndOfFile];
	[file closeFile];
	
	if([data length])
	{
		NSString *path = [[NSString alloc]initWithData:data
																					encoding:NSUTF8StringEncoding];
		purgePath = [path stringByReplacingOccurrencesOfString:@"\n" withString:@""];
		[path release];
	}
	
	return purgePath;
}

#pragma mark -

void PluginMain(PA_long32 selector, PA_PluginParameters params)
{
	try
	{
		PA_long32 pProcNum = selector;
		sLONG_PTR *pResult = (sLONG_PTR *)params->fResult;
		PackagePtr pParams = (PackagePtr)params->fParameters;

		CommandDispatcher(pProcNum, pResult, pParams); 
	}
	catch(...)
	{

	}
}

#pragma mark -

bool IsProcessOnExit()
{
	C_TEXT name;
	PA_long32 state, time;
	PA_GetProcessInfo(PA_GetCurrentProcessNumber(), name, &state, &time);
	CUTF16String procName(name.getUTF16StringPtr());
	CUTF16String exitProcName((PA_Unichar *)"$\0x\0x\0\0\0");
	return (!procName.compare(exitProcName));
}

void OnStartup()
{

}

void OnCloseProcess()
{
//	if(IsProcessOnExit())
//	{
//		if(helperToolConnection != nil)
//		{
//			PA_RunInMainProcess((PA_RunInMainProcessProcPtr)disconnect_from_helper_tool, 0);
//		}
//	}
}

#pragma mark -

void CommandDispatcher (PA_long32 pProcNum, sLONG_PTR *pResult, PackagePtr pParams)
{
	switch(pProcNum)
	{
		case kInitPlugin :
		case kServerInitPlugin :
			OnStartup();
			break;
			
		case kCloseProcess :
			OnCloseProcess();
			break;
			
// --- Purge

		case 1 :
			PURGE_DISK_CACHE(pResult, pParams);
			break;

	}
}

#pragma mark JSON

void json_stringify(JSONNODE *json, C_TEXT& param, BOOL pretty)
{
#if VERSIONMAC
	json_char *json_string = pretty ? json_write_formatted(json) : json_write(json);
	std::wstring wstr = std::wstring(json_string);
	uint32_t dataSize = (uint32_t)((wstr.length() * sizeof(wchar_t))+ sizeof(PA_Unichar));
	std::vector<char> buf(dataSize);
	//returns byte size in toString (in this case, need to /2 to get characters)
	uint32_t len = PA_ConvertCharsetToCharset((char *)wstr.c_str(),
																						(PA_long32)(wstr.length() * sizeof(wchar_t)),
																						eVTC_UTF_32,
																						(char *)&buf[0],
																						dataSize,
																						eVTC_UTF_16);
	param.setUTF16String((const PA_Unichar *)&buf[0], len/sizeof(PA_Unichar));
	json_free(json_string);
#else
	json_char *json_string = pretty ? json_write_formatted(json) : json_write(json);
	std::wstring wstr = std::wstring(json_string);
	param.setUTF16String((const PA_Unichar *)wstr.c_str(), wstr.length());
	json_free(json_string);
#endif
}

void json_wconv(const char *value, std::wstring &u32)
{
	if((value) && strlen(value))
	{
		C_TEXT t;
		CUTF8String u8 = CUTF8String((const uint8_t *)value);
		
		t.setUTF8String(&u8);
		
		uint32_t dataSize = (t.getUTF16Length() * sizeof(wchar_t))+ sizeof(wchar_t);
		std::vector<char> buf(dataSize);
		
		PA_ConvertCharsetToCharset((char *)t.getUTF16StringPtr(),
															 t.getUTF16Length() * sizeof(PA_Unichar),
															 eVTC_UTF_16,
															 (char *)&buf[0],
															 dataSize,
															 eVTC_UTF_32);
		
		u32 = std::wstring((wchar_t *)&buf[0]);
		
	}else
	{
		u32 = L"";
	}
	
}

void json_set_s(JSONNODE *n, json_char *key, const char *value)
{
	if(n)
	{
		if(value)
		{
			std::wstring w32;
			json_wconv(value, w32);
			
			JSONNODE *e = json_get(n, key);
			if(e)
			{
				json_set_a(e, w32.c_str());//over-write existing value
			}else
			{
				json_push_back(n, json_new_a(key, w32.c_str()));
			}
			
		}else
		{
			JSONNODE *e = json_get(n, key);
			if(e)
			{
				json_nullify(e);//over-write existing value
			}else
			{
				JSONNODE *node = json_new_a(key, L"");
				json_nullify(node);
				json_push_back(n, node);
			}
		}
	}
}

void json_set_b(JSONNODE *n, json_char *key, BOOL value)
{
	if(n)
	{
		JSONNODE *e = json_get(n, key);
		if(e)
		{
			json_set_b(e, value);//over-write existing value
		}else
		{
			json_push_back(n, json_new_b(key, value));
		}
	}
}

void json_set_i(JSONNODE *n, json_char *key, int value)
{
	if(n)
	{
		JSONNODE *e = json_get(n, key);
		if(e)
		{
			json_set_i(e, value);//over-write existing value
		}else
		{
			json_push_back(n, json_new_i(key, value));
		}
	}
}

static const char json_x_table[65] = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/";

void json_set_x(JSONNODE *n, json_char *key, void *payload, size_t binlen)
{
	std::vector<uint8_t>buf(binlen);
	if(payload)
	{
		PA_MoveBlock(payload, (char *)&buf[0], binlen);
		
		::std::size_t olen = (((binlen + 2) / 3) * 4);
		olen += olen / 72; /* line feeds */
		// Use = signs so the end is properly padded.
		std::string retval(olen, '=');
		::std::size_t outpos = 0;
		::std::size_t line_len = 0;
		int bits_collected = 0;
		unsigned int accumulator = 0;
		const std::vector<uint8_t>::const_iterator binend = buf.end();
		for (std::vector<uint8_t>::const_iterator i = buf.begin(); i != binend; ++i)
		{
			accumulator = (accumulator << 8) | (*i & 0xffu);
			bits_collected += 8;
			while (bits_collected >= 6)
			{
				bits_collected -= 6;
				retval[outpos++] = json_x_table[(accumulator >> bits_collected) & 0x3fu];
				line_len++;
				if (line_len >= 72) {
					retval[outpos++] = '\n';
					line_len = 0;
					//breathe every 8KO
					if((outpos % 0x2000)==0) {
						PA_YieldAbsolute();
					}
				}
			}
		}
		if (bits_collected > 0) { // Any trailing bits that are missing.
			//	assert(bits_collected < 6);
			accumulator <<= 6 - bits_collected;
			retval[outpos++] = json_x_table[accumulator & 0x3fu];
		}
		json_set_s(n, key, retval.c_str());
	}
}

#pragma mark -

// ------------------------------------- Purge ------------------------------------

void install_helper_tool() /* launch installer */
{
	/*
	 * avoid NSWorkspace::URLForApplicationWithBundleIdentifier because there may be multiple copies
	 */
	@autoreleasepool
	{
		if(!isHelperToolInstalled())
		{
			NSBundle *thisBundle = [NSBundle bundleWithIdentifier:PURGE_PLUGIN_UTI];
			if(thisBundle)
			{
				NSURL *appURL = [[[thisBundle executableURL] URLByDeletingLastPathComponent]
												 URLByAppendingPathComponent:PURGE_INSTALLER_NAME];
				if(appURL)
				{
                    
                    @autoreleasepool
                    {
                        NSTask *task = [[NSTask alloc]init];
                        task.launchPath = @"/usr/bin/xattr";
                        task.arguments = @[@"-c", @"-r", [appURL path]];
                        [task launch];
                        [task waitUntilExit];
                        [task release];
                    }
 
					NSError *error;
					if([[NSWorkspace sharedWorkspace]
							launchApplicationAtURL:appURL
							options:
							NSWorkspaceLaunchWithoutActivation|NSWorkspaceLaunchAsync
							configuration:[NSDictionary dictionaryWithObject:[NSArray array]
																												forKey:NSWorkspaceLaunchConfigurationArguments]
							error:&error])
					{
						NSLog(@"%@ launched", PURGE_INSTALLER_NAME);
					}
				}
			}
		}
	}
}

int call_helper_tool()
{
	if(isHelperToolInstalled())
	{
		NSPipe *pipe = [NSPipe pipe];
		NSFileHandle *file = pipe.fileHandleForReading;
		NSTask *task = [[NSTask alloc]init];
		task.launchPath = proxyPath();
		task.standardOutput = pipe;
		[task launch];
		
		NSData *data = [file readDataToEndOfFile];
		[file closeFile];
		
		if([data length])
		{
			NSString *pid = [[NSString alloc]initWithData:data
																					 encoding:NSUTF8StringEncoding];
			return [pid intValue];
		}
	}
	
	return 0;
}

void PURGE_DISK_CACHE(sLONG_PTR *pResult, PackagePtr pParams)
{
	C_TEXT Param1_report;

	install_helper_tool();

	JSONNODE *json = json_new(JSON_NODE);
	
	@autoreleasepool
	{
		json_set_s(json, L"helperToolPath", [helperToolPath() UTF8String]);
		json_set_s(json, L"purgePath", [purgePath() UTF8String]);
		json_set_b(json, L"isHelperToolInstalled", isHelperToolInstalled());
		json_set_s(json, L"proxyPath", [proxyPath() UTF8String]);
		json_set_i(json, L"pid", call_helper_tool());
	}

	json_stringify(json, Param1_report, FALSE);
	json_delete(json);
	Param1_report.toParamAtIndex(pParams, 1);
}

