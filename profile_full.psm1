#Requires -Version 7.2

# read current time for startup measurement
$_Times = @{
	internal = Get-Date
}

Set-StrictMode -Version Latest
# stop even on non-critical errors
$global:ErrorActionPreference = "Stop"
# throw error when native command returns non-zero exit code
$global:PSNativeCommandUseErrorActionPreference = $true
# show Information log stream
$global:InformationPreference = "Continue"
$global:PSDefaultParameterValues["*:ErrorAction"] = $ErrorActionPreference
# this shouldn't be necessary anymore
#$PSDefaultParameterValues["*:Encoding"] = "utf8"

# add custom module directories
$env:PSModulePath = @(
	$env:PSModulePath,
	(Resolve-Path $PSScriptRoot\CustomModules),
	(Resolve-Path $PSScriptRoot\UnmaintainedModules)
	(Resolve-Path $PSScriptRoot\ZLocation) # custom ZLocation fork
) -join [IO.Path]::PathSeparator


# set global path to data directory, this is used by multiple other custom modules in this repository
Set-PSDataRoot $PSScriptRoot\..\data


if ($IsWindows) {
	# create a new aliased drive for HKCR
	$null = New-PSDrive -PSProvider Registry -Root HKEY_CLASSES_ROOT -Name HKCR
}

# set path where command history is saved
Set-PSReadLineOption -HistorySavePath (Get-PSDataPath "ConsoleHost_history.txt")
# set database path for ZLocation
$env:PS_ZLOCATION_DATABASE_PATH = Get-PSDataPath "z-location.db" -NoCreate

# set env:LANG, which makes `git diff` and other originally Linux commands print stuff with correct encoding
$env:LANG = "C.UTF-8"

$_Times.setup = Get-Date

# custom functions
Import-Module $PSScriptRoot\functions.psm1 -DisableNameChecking
# custom private functions, not commited to git
if (Test-Path $PSScriptRoot\functions_custom.psm1) {
	Import-Module $PSScriptRoot\functions_custom.psm1 -DisableNameChecking
}

$_Times.imports = Get-Date


# reload path from system env
Update-EnvVar Path


# do not setup custom prompt and banner if set
if (-not (Test-Path Env:PS_SIMPLE_PROMPT)) {
	# do not show custom banner (TODO, version, calendar,...) if set
	if (-not (Test-Path Env:PS_NO_BANNER)) {
		& $PSScriptRoot\Prompt\banner.ps1
		$_Times.banner = Get-Date
	}
	# setup prompt
	Import-Module $PSScriptRoot\Prompt\Prompt -ArgumentList @($_Times)
}


# delay the load of modules that take a long time to load, and are not immediately needed
# OnIdle is triggered when user hasn't typed anything in 300ms and the input buffer is empty;
# often, this is all loaded before the user starts typing the first command
#
# to not block for too long if the OnIdle event triggers just before user starts typing a command,
#  the loading is split into multiple stages (apparently creating multiple event listeners on top
#  level always fires them one after another, without checking if the engine is still idle between them)
Register-EngineEvent PowerShell.OnIdle -MaxTriggerCount 1 -Action {
	if (-not (Test-Path Env:PS_SIMPLE_PROMPT)) {
		# setup ZLocation (my fork with some change)
		# if user types `z` immediately after prompt loads, this will not be loaded yet,
		#  so he'll have to wait for a bit, but the command will still work
		Import-Module -Global ZLocation
	}

	Register-EngineEvent PowerShell.OnIdle -MaxTriggerCount 1 -Action {
		# native command arg completers
		Import-Module -Global ArgumentCompleters

		Register-EngineEvent PowerShell.OnIdle -MaxTriggerCount 1 -Action {
			# among others, completions for git
			if (Get-Module posh-git -ListAvailable) {
				Import-Module -Global posh-git
			}
		}
	}
}
