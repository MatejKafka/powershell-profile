# powershell-profile
Snippets from my Powershell 7 profile.ps1

## prompt.ps1
Custom Powershell 7 prompt, showing last command run time, it's return type (currently shows the first one, with count in case an array is returned) and return code (if the command did not finish correctly).

Also supports python venv (activate with `Activate-Venv`, indicator is then added to prompt; deactivate as usual with `deactivate`).

**Requires the Pansies module (https://www.powershellgallery.com/packages/Pansies) for RGB color support.**

<br>

![Screenshot of pwsh.exe](https://i.imgur.com/11lNgtK.png)
