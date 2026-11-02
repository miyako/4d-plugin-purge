# 4d-plugin-purge

Purge runs macOS's [`purge`](https://developer.apple.com/legacy/library/documentation/Darwin/Reference/ManPages/man8/purge.8.html) command from 4D, which flushes the disk cache (inactive file-backed memory). `purge` needs root privileges, so the plugin installs a privileged helper tool (`com.4D.purge.HelperTool`, via `SMJobBless`) the first time you use it, and asks that helper to start `purge`. The command returns an `Object` describing the installation and the process ID of the `purge` it started.

| Command | Returns | Purpose |
|---|---|---|
| [Purge disk cache](#purge-disk-cache) | `Object` | Install the helper if needed, then start `purge` as root |

**Platforms:** macOS only (the Windows binary in the bundle is a stub)

---

## Requirements & platform notes

- **macOS only.** The command does nothing useful on Windows.
- **The first call only installs the helper.** It opens a small hidden installer app (`Purge.app`, inside the plugin bundle), and macOS asks an administrator to approve the new helper tool. The command doesn't wait for that: the first call returns with `isHelperToolInstalled` `False` and `pid` `0`. Call it again once the helper is approved.

  <img src="https://github.com/miyako/4d-plugin-purge/assets/1725068/798e06db-cdd2-419a-9ebc-a44256c680fb" style="height:240px;width:auto;" />

  Once approved, the helper is installed in `/Library/PrivilegedHelperTools` and appears as a background item in System Settings.

  <img src="https://github.com/miyako/4d-plugin-purge/assets/1725068/8ae0124a-046c-4575-a70d-b7616674a3b2" style="height:360px;width:auto;" />

- **`purge` must exist on the system.** The plugin looks for it with `/usr/bin/which purge`. On current macOS versions it is part of the system (`/usr/sbin/purge`); on older systems it came with Xcode or the command line tools (`xcode-select --install`).
- **The command doesn't wait for the purge to finish.** It returns as soon as `purge` has been started; the flush itself can take a while and the system may feel slow during it.
- **The helper stays installed** after you remove the plugin. Remove it (and its launchd job) by hand if you no longer need it.
- **Preemptive processes:** the manifest declares the command thread-safe (`Purge disk cache:J`).

---

## Purge disk cache

### Syntax

```
Purge disk cache → status
```

| Parameter | Type | Description |
|---|---|---|
| Result | Object | Installation status and the process ID of `purge` (see below) |

### Description

`Purge disk cache` takes no parameters. Each call:

1. Checks whether `/Library/PrivilegedHelperTools/com.4D.purge.HelperTool` exists. If it doesn't, it launches the installer app and continues without waiting.
2. If the helper exists, runs the small command line tool `com.4D.purge.proxy` (inside the plugin bundle), which connects to the helper over XPC and asks it to start `purge`. The helper replies with the process ID.

**Result object:**

| Property | Type | Description |
|---|---|---|
| `helperToolPath` | Text | Where the helper is (or will be) installed: `/Library/PrivilegedHelperTools/com.4D.purge.HelperTool` |
| `purgePath` | Text | Path of `purge` found by `/usr/bin/which`, or `""` if not found |
| `proxyPath` | Text | Path of the `com.4D.purge.proxy` tool inside the plugin bundle |
| `isHelperToolInstalled` | Boolean | `True` if the helper file exists |
| `pid` | Real | Process ID of the `purge` process started as root, or `0` if nothing was started |

`isHelperToolInstalled` only checks that the file exists, not that the helper is running or up to date.

With the fixed source in this repository, the command gives up waiting for the helper after 10 seconds and returns `pid` `0`; earlier builds could block the calling process indefinitely if the helper never answered.

### Example

From the plugin's own test method (`TEST.4dm`):

```4d
$info:=Purge disk cache
```

Check the result:

```4d
$info:=Purge disk cache

Case of 
	: (Not($info.isHelperToolInstalled))
		ALERT("Approve the helper tool, then try again.")
	: ($info.purgePath="")
		ALERT("purge was not found on this system.")
	: ($info.pid=0)
		ALERT("The helper did not start purge.")
	Else 
		// purge is running as process $info.pid
End case 
```

---

## Error handling & troubleshooting

- **`isHelperToolInstalled` is `False`.** This is the first call, or the administrator declined the installation. Call the command again after approving the helper.
- **`pid` is `0` although the helper is installed.** The helper didn't answer (not loaded by launchd, blocked in System Settings > Login Items, or signed by a different developer than the installer expects), or `purgePath` is empty. Check that the background item is allowed.
- **`purgePath` is empty.** `purge` isn't on the system; install the command line tools.
- **No 4D error is raised** in any of these cases; inspect the result object.

---

## Quick reference

```4d
$info:=Purge disk cache
If ($info.pid#0)
	// purge started
End if 
```

---

## Build information

Based on [EvenBetterAuthorizationSample](https://developer.apple.com/library/content/samplecode/EvenBetterAuthorizationSample/Introduction/Intro.html).

The repository has two Xcode projects: `Purge.xcodeproj` at the root builds the plugin and the `com.4D.purge.proxy` tool; `helper/Purge.xcodeproj` builds the installer app (`Purge.app`) and the helper tool it embeds. `Purge.app` and `com.4D.purge.proxy` are committed prebuilt inside the plugin bundle; the release workflow rebuilds only the plugin binary and re-signs the whole bundle.

As explained [here](https://github.com/atnan/SMJobBlessXPC/issues/7), it is imperative to run ``SMJobBlessUtil.py`` before building the application. Do **not** update the project version, or the python script will fail.

python3 version: https://gist.github.com/mikeyh/89a1e2ecc6849ff6056b7391c5216799

The syntax is 

```
SMJobBlessUtil.py setreq {app} {App-Info.plist} {HelperTool-Info.plist}
```

This updates ``SMPrivilegedExecutables`` in ``App-Info.plist`` and ``SMAuthorizedClients`` in ``HelperTool-Info.plist``.

It seems ``SMJobBless`` and ``launchd`` reads ``Info.plist`` of the main application, not of the plugin (which makes sense). The plugin uses a small app (hidden, ``LSBackgroundOnly``) to install the helper. The "installer" app displays a simple user interface if the argument ``--debug`` is passed.

It seems like there is no easy way to call ``NSXPCConnection`` or ``NSXPCInterface`` from the plugin, especially if the plugin is reloaded without terminating the main application. As a workaround, a proxy console application is called each time to run ``purge``.
