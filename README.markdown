XcodeSelectionColorFix
===========

*NOTE: Xcode 5.0.1 (possibly 5.0) fixes the issue this plugin solves, so no need to use it unless you are on Xcode 4.x*

When an Xcode editor is in a non-key window, it draws with `+secondarySelectedControlColor` as the background color for selected text. But, if you prefer to use a dark theme (like the included Midnight), this is illegible since the light text color and light background color are too similar.

This Xcode plugin hacks around and makes Xcode draw using a 50/50 mixture of the background color and selection color you specified in your theme.

Installation
------------

- Build and install the bundle where ever you like
- Inform Xcode of its location with:

		defaults write com.apple.Xcode ExtraPlugInFolders -array-add "/path/to/folder/containing/plugin"

- Relaunch Xcode
