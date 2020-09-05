4d-plugin-purge
===============

Privileged HelperTool to execute [``purge``](https://developer.apple.com/legacy/library/documentation/Darwin/Reference/ManPages/man8/purge.8.html) on macOS

### Platform

| carbon | cocoa | win32 | win64 |
|:------:|:-----:|:---------:|:---------:|
||<img src="https://cloud.githubusercontent.com/assets/1725068/22371562/1b091f0a-e4db-11e6-8458-8653954a7cce.png" width="24" height="24" />|||

### Version

<img width="32" height="32" src="https://user-images.githubusercontent.com/1725068/73986501-15964580-4981-11ea-9ac1-73c5cee50aae.png"> <img src="https://user-images.githubusercontent.com/1725068/73987971-db2ea780-4984-11ea-8ada-e25fb9c3cf4e.png" width="32" height="32" />

### Note

The [10.9](https://github.com/miyako/4d-plugin-purge/tree/10.9) branch is **deprecated**.

You might have to install ``purge`` manually with ``xcode-select --install``

Based on [EvenBetterAuthorizationSample](https://developer.apple.com/library/content/samplecode/EvenBetterAuthorizationSample/Introduction/Intro.html).

### Build Information

As explained [here](https://github.com/atnan/SMJobBlessXPC/issues/7), it is imperative to run ``SMJobBlessUtil.py`` before building the application. Do **not** update the project version, or the python script will fail.

The syntax is 

```
SMJobBlessUtil.py setrep {app} {App-Info.plist} {HelperTool-Info.plist}
```

This updates ``SMPrivilegedExecutables`` in ``App-Info.plist`` and ``SMAuthorizedClients`` in ``HelperTool-Info.plist``.

It seems ``SMJobBless`` and ``launchd`` reads ``Info.plist`` of the main application, not of the plugin (which makes sense). The plugin uses a small app (hidden, ``LSBackgroundOnly``) to install the helper. The "installer" app displays a simple user interface if the argument ``--debug`` is passed.

It seems like there is no easy way to call ``NSXPCConnection`` or ``NSXPCInterface`` from the plugin, especially if the plugin is reloaded without terminating the main application. As a workaround, a proxy console application is called each time to run ``purge``.

## Syntax

```
PURGE DISK CACHE (info)
```

Parameter|Type|Description
------------|------------|----
info|TEXT|JSON (out)

The command name and signature is different to the old version.

structure of info object:

```
helperToolPath : string (POSIX)
purgePath : string (POSIX)
proxyPath : string (POSIX)
isHelperToolInstalled : bool
pid: number 
```

``purgePath`` is searched by ``/usr/bin/which``

``helperToolPath`` is searched in ``Library/PrivilegedHelperTools``

The installer is lanched if ``!isHelperToolInstalled``.
