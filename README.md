4d-plugin-purge
===============

Privileged HelperTool to execute [``purge``](https://developer.apple.com/legacy/library/documentation/Darwin/Reference/ManPages/man8/purge.8.html) on macOS

### Platform

| carbon | cocoa | win32 | win64 |
|:------:|:-----:|:---------:|:---------:|
|<img src="https://cloud.githubusercontent.com/assets/1725068/22371562/1b091f0a-e4db-11e6-8458-8653954a7cce.png" width="24" height="24" />|<img src="https://cloud.githubusercontent.com/assets/1725068/22371562/1b091f0a-e4db-11e6-8458-8653954a7cce.png" width="24" height="24" />|||

### Version

<img src="https://cloud.githubusercontent.com/assets/1725068/18940649/21945000-8645-11e6-86ed-4a0f800e5a73.png" width="32" height="32" /> <img src="https://cloud.githubusercontent.com/assets/1725068/18940648/2192ddba-8645-11e6-864d-6d5692d55717.png" width="32" height="32" />

### Note

The [10.9](https://github.com/miyako/4d-plugin-purge/tree/10.9) branch is **deprecated**.

Based on [EvenBetterAuthorizationSample](https://developer.apple.com/library/content/samplecode/EvenBetterAuthorizationSample/Introduction/Intro.html).

### Build Information

As explained [here](https://github.com/atnan/SMJobBlessXPC/issues/7), it is imperative to run ``SMJobBlessUtil.py`` before building the application. Do **not** update the project version, or the python script will fail.

The syntax is 

```
SMJobBlessUtil.py setrep {app} {App-Info.plist} {HelperTool-Info.plist}
```

This updates ``SMPrivilegedExecutables`` in ``App-Info.plist`` and ``SMAuthorizedClients`` in ``HelperTool-Info.plist``.

It seems ``SMJobBless`` and ``launchd`` reads ``Info.plist`` of the main application, not of the plugin (which makes sense). The plugin uses a small app (hidden, ``LSBackgroundOnly``) to install the helper. The "installer" app displays a simple user interface if the argument ``--debug`` is passed.

## Syntax

```
PURGE DISK CACHE (info)
```

Parameter|Type|Description
------------|------------|----
info|TEXT|JSON (out)

The command name and signature is different to the old version.
