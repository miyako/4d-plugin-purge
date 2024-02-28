Use privileged HelperTool to execute [``purge``](https://developer.apple.com/legacy/library/documentation/Darwin/Reference/ManPages/man8/purge.8.html) on macOS.

**Note**: You need to install `purge` with Xocde or manually with ``xcode-select --install``.

# About

When you call the plugin for the first time, the system prompt to install a new helper tool

<img src="https://github.com/miyako/4d-plugin-purge/assets/1725068/798e06db-cdd2-419a-9ebc-a44256c680fb" style="height:240px;width:auto;" />

If you accept, a background item is added to the system.

This means `com.4D.purge.HelperTool` is added to `/Library/PrivilegedHelperTools`.

Now you can start using the plugin command, which internally calls `purge` via the helper tool.

<img src="https://github.com/miyako/4d-plugin-purge/assets/1725068/8ae0124a-046c-4575-a70d-b7616674a3b2" style="height:360px;width:auto;" />

* Structure of returned object

|property|type|description|
|:-|:-:|:-:|
|helperToolPath|Text||
|purgePath|Text||
|proxyPath|Text||
|isHelperToolInstalled|Boolean||
|pid|Number||

``purgePath`` is searched by ``/usr/bin/which``

``helperToolPath`` is searched in ``Library/PrivilegedHelperTools``

The installer is lanched if ``!isHelperToolInstalled``.

# Build Information

Based on [EvenBetterAuthorizationSample](https://developer.apple.com/library/content/samplecode/EvenBetterAuthorizationSample/Introduction/Intro.html).

As explained [here](https://github.com/atnan/SMJobBlessXPC/issues/7), it is imperative to run ``SMJobBlessUtil.py`` before building the application. Do **not** update the project version, or the python script will fail.

python3 version: https://gist.github.com/mikeyh/89a1e2ecc6849ff6056b7391c5216799

The syntax is 

```
SMJobBlessUtil.py setreq {app} {App-Info.plist} {HelperTool-Info.plist}
```

This updates ``SMPrivilegedExecutables`` in ``App-Info.plist`` and ``SMAuthorizedClients`` in ``HelperTool-Info.plist``.

It seems ``SMJobBless`` and ``launchd`` reads ``Info.plist`` of the main application, not of the plugin (which makes sense). The plugin uses a small app (hidden, ``LSBackgroundOnly``) to install the helper. The "installer" app displays a simple user interface if the argument ``--debug`` is passed.

It seems like there is no easy way to call ``NSXPCConnection`` or ``NSXPCInterface`` from the plugin, especially if the plugin is reloaded without terminating the main application. As a workaround, a proxy console application is called each time to run ``purge``.
