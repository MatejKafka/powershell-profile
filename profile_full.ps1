# read current time for startup measurement
$_Times = @{
	internal = Get-Date
}

Set-StrictMode -Version Latest
# stop even on non-critical errors
# unfortunately, this only works for cmdlets and functions, not native commands
$ErrorActionPreference = "Stop"
# show Information log stream
$InformationPreference = "Continue"
$PSDefaultParameterValues["*:ErrorAction"] = $ErrorActionPreference
# this shouldn't be necessary anymore
#$PSDefaultParameterValues["*:Encoding"] = "utf8"
# throw error when native command returns non-zero exit code
$PSNativeCommandUseErrorActionPreference = $true


# set global path to data directory, this is used by multiple other custom modules in this repository
Set-PSDataRoot $PSScriptRoot\..\data


# add custom module directories
$env:PSModulePath = @($env:PSModulePath, (Resolve-Path $PSScriptRoot\CustomModules), (Resolve-Path $PSScriptRoot\UnmaintainedModules)) -join [IO.Path]::PathSeparator
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
# native command arg completers
Import-Module ArgumentCompleters

# reload path from system env
Update-EnvVar Path

$_Times.imports = Get-Date


# do not setup custom prompt and banner if set
if (-not (Test-Path Env:PS_SIMPLE_PROMPT)) {
	# do not show custom banner (TODO, version, calendar,...) if set
	if (-not (Test-Path Env:PS_NO_BANNER)) {
		& $PSScriptRoot\Prompt\banner.ps1
		$_Times.banner = Get-Date
	}
	# setup prompt
	Import-Module $PSScriptRoot\Prompt\Prompt -ArgumentList @($_Times)
	# setup ZLocation (my fork with some change)
	Import-Module $PSScriptRoot\ZLocation\ZLocation
}

Remove-Variable _Times
