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
	$env:PSModulePath
	"$PSScriptRoot\CustomModules"
	"$PSScriptRoot\UnmaintainedModules"
	"$PSScriptRoot\ZLocation" # custom ZLocation fork
) -join [IO.Path]::PathSeparator


# set global path to data directory, this is used by multiple other custom modules in this repository
Set-PSDataRoot $PSScriptRoot\..\data


if ($IsWindows) {
	# create a new aliased drive for HKCR
	$null = New-PSDrive -Scope Global -PSProvider Registry -Root HKEY_CLASSES_ROOT -Name HKCR
}

# set path where command history is saved
Set-PSReadLineOption -HistorySavePath (Get-PSDataPath "ConsoleHost_history.txt")
# set database path for ZLocation
$env:PS_ZLOCATION_DATABASE_PATH = Get-PSDataPath "z-location.db" -NoCreate

# set env:LANG, which makes `git diff` and other originally Linux commands print stuff with correct encoding
$env:LANG = "C.UTF-8"

$_Times.setup = Get-Date

# a collection of random useful functions; -Global is used so that the module is visible externally
#  (among other benefits, this means that it can be reloaded separately)
Import-Module -Global $PSScriptRoot\functions.psm1 -DisableNameChecking
# custom private functions, not commited to git
Import-Module -Global $PSScriptRoot\functions_custom.psm1 -ErrorAction Ignore -DisableNameChecking

# delay the import of remaining modules after the profile is loaded to improve startup time
Register-EngineEvent PowerShell.OnIdle -MaxTriggerCount 1 -Action {
	# delay the load of modules that take a long time to load, and are not immediately needed
	# this is better than just directly importing the modules here, because once the OnIdle
	#  callback is started, it cannot be iterrupted and the shell could be left unresponsive
	#  for a long time until all modules are loaded
	Import-Module DelayLoad 4>$null
	
	# setup ZLocation (my fork with some change)
	# if user types `z` immediately after prompt loads, this will not be loaded yet,
	#  so he'll have to wait for a bit, but the command will still work
	Import-ModuleDelayed ZLocation
	# completions for git, much faster than posh-git; ignore error, may not be installed
	Import-ModuleDelayed PSGitCompletions -ErrorAction Ignore
	# random argument completers
	Import-ModuleDelayed ArgumentCompleters
	Import-ModuleDelayed WSLTabCompletion -ErrorAction Ignore
}

$_Times.imports = Get-Date


# do not setup custom prompt and banner if set
if (-not (Test-Path Env:PS_SIMPLE_PROMPT)) {
	Import-Module $PSScriptRoot\Prompt\Colors
	# if set, do not show custom banner (TODO, version, calendar,...)
	if (-not (Test-Path Env:PS_NO_BANNER)) {
		& $PSScriptRoot\Prompt\banner.ps1
		$_Times.banner = Get-Date
	}
	# setup prompt
	Import-Module $PSScriptRoot\Prompt\Prompt -ArgumentList @($_Times)
	$_Times.prompt = Get-Date
}

