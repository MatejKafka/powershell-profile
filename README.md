# powershell-profile
Snippets from my Powershell 7 profile directory.

## ./Custom
Directory of custom modules, either made by me, or copied from the internet (source is noted in manifest file where appropriate).

## profile.ps1
Main profile file, I have it symlinked from the default `Documents\Powershell\Microsoft.PowerShell_profile.ps1` path. Sets sane defaults for error handling and imports other parts.

## prompt.ps1
Custom Powershell 7 prompt, showing last command run time, it's return type (currently shows the first one, with count in case an array is returned) and return code (if the command did not finish correctly).

Also supports python venv (activate with `Activate-Venv`, indicator is then added to prompt; deactivate as usual with `deactivate`).

**Requires the Pansies module (https://www.powershellgallery.com/packages/Pansies) for RGB color support.**

<br>

![Screenshot of pwsh.exe](https://i.imgur.com/11lNgtK.png)

## FSNav.psm1
Adds a `Ctrl+d` hotkey that allows you to navigate folders just by typing parts of the desired directory, similar to GUI file managers.
Also adds `Ctrl+UpArrow`, equivalent to `cd ..`.

## arg_completer.ps1
Adds argument completion support for native commands, currently `winget`.