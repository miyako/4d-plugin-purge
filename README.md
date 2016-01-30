4d-plugin-purge
===============

Privileged HelperTool to execute purge on OS X 10.9+

##Platform

| carbon | cocoa | win32 | win64 |
|:------:|:-----:|:---------:|:---------:|
|🆗|🆗|🚫|🚫|

About
---
In earlier version of OS X, it was enough to call [purge] (https://developer.apple.com/library/mac/documentation/Darwin/Reference/ManPages/man8/purge.8.html) via LAUNCH EXTERNAL PROCESS.

**Note**: "purge" is not installed by default, you have to install X code and/or [Developer Tools](https://developer.apple.com/downloads/index.action).

```
xcode-select --install
```

Since 10.9, purge requires [sudo](https://developer.apple.com/library/mac/documentation/Darwin/Reference/ManPages/man8/sudo.8.html#//apple_ref/doc/man/8/sudo).

Technically you could specify the "-S" option and hard code the admin password, but normally you wouldn't want to do that in a distributed app.

This plugin offers an alternative way of calling "purge" with elevated privileges.

First, you need to open the plugin bundle and locate the "Purge Helper" application inside ```Contents/MacOS/``` and launch it directly.

In the first instance, the OS will ask whether you want to install a "Helper Tool" and prompt for an admin password.

**Note**: A similar procedure is required when you starting the web server with a port number below 1024 for the first time.

Once the helper tool is installed (it is a daemon), you can call "purge" via the plugin without entering the admin password each time.

Example
---
```
  //since OS X 10.9 the /usr/sbin/purge command requires sudo!
  //this commands launches a background app,
  //which installs a privileged helper tool:
  //Library/PrivilegedHelperTools/com.apple.bsd.purge.HelperTool
  //once the user authorizes this helper tool,
  //the preferences is stores in defaults, so no need to authorize each time.
  //if successful, the "file cache" size in activity monitor should decrease.
PURGE DISK BUFFERS 

If (False)
  //(debug) force the authorization dialog:
PURGE DISK BUFFERS (Purge request authorization)
End if 
```
