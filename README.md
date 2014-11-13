4d-plugin-purge
===============

Privileged HelperTool to execute purge on OS X 10.9

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
