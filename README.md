4d-plugin-purge
===============

Privileged HelperTool to execute purge on OS X 10.9+

### Platform

| carbon | cocoa | win32 | win64 |
|:------:|:-----:|:---------:|:---------:|
|<img src="https://cloud.githubusercontent.com/assets/1725068/22371562/1b091f0a-e4db-11e6-8458-8653954a7cce.png" width="24" height="24" />|<img src="https://cloud.githubusercontent.com/assets/1725068/22371562/1b091f0a-e4db-11e6-8458-8653954a7cce.png" width="24" height="24" />|||

### Version

<img src="https://cloud.githubusercontent.com/assets/1725068/18940649/21945000-8645-11e6-86ed-4a0f800e5a73.png" width="32" height="32" /> <img src="https://cloud.githubusercontent.com/assets/1725068/18940648/2192ddba-8645-11e6-864d-6d5692d55717.png" width="32" height="32" />

### Releases

[for macOS 10.13 (High Sierra)](https://github.com/miyako/4d-plugin-purge/releases/tag/1.0.1)

[for macOS 10.11 (El Capitan)](https://github.com/miyako/4d-plugin-purge/releases/tag/1.0.0)

## Syntax

```
PURGE DISK BUFFERS
```

## About

In earlier version of OS X, it was enough to call [purge](https://developer.apple.com/library/mac/documentation/Darwin/Reference/ManPages/man8/purge.8.html) via ``LAUNCH EXTERNAL PROCESS``.

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

## Examples

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
