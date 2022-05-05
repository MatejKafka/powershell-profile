# powershell-profile
My heavily customized Powershell 7 profile directory. Primarily developed for Windows, but my colleague also uses it on Linux and it seems to work.

![Screenshot of pwsh.exe in dark mode](./screenshot-dark-mode.png)

![Screenshot of pwsh.exe in light mode](./screenshot-light-mode.png)

## Installation

Run this in PowerShell Core:

```powershell
# clone this repository wherever you prefer
git clone https://github.com/MatejKafka/powershell-profile
cd powershell-profile
# clone git submodules
git submodule update --init --recursive

# symlink the main profile from $PROFILE (default profile file path)
New-Item -Type SymbolicLink $PROFILE -Target (Resolve-Path ./Microsoft.PowerShell_profile.ps1)

# if you want git autocompetion, also install posh-git
Install-Module posh-git
```

## Setup (issues)

### Nothing loads?

If you're not running in Windows Terminal, nothing will be loaded. I have it setup this way to make PowerShell load faster when invoked inside an IDE or from a script that does not specify the `-noprofile` PowerShell option. If you want to always load the profile, open `.\Microsoft.PowerShell_profile.ps1` in a text editor and remove the `if` condition around the last line, where `$PSScriptRoot\profile_full` is imported.

### Some error is thrown from `Set-PSDataRoot` during startup?

This function is called in `profile_full.psm1`. Over time, I wrote multiple custom PowerShell modules that needed to store data somewhere (RSS feeds, TODO,...). To make this data directory configurable, all these modules get the data path from the custom `PSDirectories` module.

Root directory of the data path is configured by calling `Set-PSDataRoot` during the profile setup. Change this to a directory of your choosing – default is `$PSScriptRoot\..\data`, a reasonable choice on a Windows install would be something like `"$env:APPDATA\powershell-profile"`.

### How do I change the color scheme?

Modify the color scheme file `PromptColorScheme.psd1` in the data directory (see the previous issue about `Set-PSDataRoot` to know where to look).

### `Ctrl-d` does not work as EOF?

I'm a Windows guy, so I don't need `Ctrl-d`, and I'm using it to open `FSNav` (see below) instead. If you don't like that, change the key-binding in `Prompt/FSNav.psm1`.

### Wow, the startup is slow!

Sorry, I spent quite a lot of time on optimizing it, but yeah, it's an order of magnitude slower than other shells, and quite a major part is the startup time of PowerShell itself, before my profile is even loaded. Hopefully the features will make it worth it for you.

## Module description

### `./CustomModules`

Directory of custom modules, either made by me, or copied from the internet (source is noted in manifest file where applicable).

### `./UnmaintainedModules`

Modules which I once wrote (or copied), but I don't actively use them anymore, or they're under development and not working reasonably well yet. Some of them may work OK, other not so much.

### `Microsoft.PowerShell_profile.ps1`

Base profile script, loaded by PowerShell on startup. I have it symlinked from the default `Documents\Powershell\Microsoft.PowerShell_profile.ps1` path. Checks if we're running in Windows Terminal (or Linux/MacOS), and imports the main profile module.

### `profile_full.psm1`

Main profile module, imported from the previous script. Sets sane defaults for error handling, sets up some data and module paths and imports other parts of the profile, most notably the custom prompt and custom functions.

### `Prompt/Prompt.psm1`

Custom PowerShell prompt, showing last command run time, its return type (currently shows the first one, with item count prepended in case multiple values are returned) and return code (if the command did not finish correctly).

Also shows git status and python virtual environment (activate with `Activate-Venv`, indicator is then added to the prompt; deactivate as usual with `deactivate`).

### `Prompt/FSNav.psm1`

Adds a `Ctrl+d` hotkey that allows you to navigate folders just by typing parts of the desired directory, similar to GUI file managers.
Also adds `Ctrl+UpArrow`, equivalent to `cd ..`.

### `functions.psm1`

Many random useful functions that I use, but are not large enough to warrant a separate module. Read through it, maybe you'll find something useful for you. 

I'll highlight the `edit` function, which lets you edit any defined PowerShell function in a text editor by calling `edit <function-name>`. Also useful may be the `notes` function, which lets you add short notes that are shown at the top of each PowerShell session.