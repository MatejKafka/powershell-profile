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


# to support symlinked profile path
$CONFIG_DIR = Get-Item $PSCommandPath | % {if ($null -ne $_.Target) {$_.Target} else {$_}} | Split-Path
$DATA_DIR = Resolve-Path $CONFIG_DIR\..\data
# add custom module directory
$env:PSModulePath += [IO.Path]::PathSeparator + (Resolve-Path $CONFIG_DIR"\Custom")
# set path where command history is saved
Set-PSReadLineOption -HistorySavePath (Join-Path $DATA_DIR "ConsoleHost_history.txt")
# set database path for ZLocation
$env:PS_ZLOCATION_DATABASE_PATH = Join-Path $DATA_DIR "z-location.db"

# set env:LANG, which makes `git diff` and other originally Linux commands print stuff with correct encoding
$env:LANG = "C.UTF-8"

$_Times.setup = Get-Date

# RGB colors for Write-Host
Import-Module Pansies
# custom functions
Import-Module $CONFIG_DIR\functions.psm1 -DisableNameChecking
# custom private functions, not commited to git
if (Test-Path $CONFIG_DIR\functions_custom.psm1) {
	Import-Module $CONFIG_DIR\functions_custom.psm1 -DisableNameChecking
}
# native command arg completers
. $CONFIG_DIR\arg_completer.ps1

# reload path from system env
Update-EnvVar Path

$_Times.imports = Get-Date


# do not setup custom prompt and banner if set
if (-not (Test-Path Env:PS_SIMPLE_PROMPT)) {
	# do not show custom banner (TODO, version, calendar,...) if set
	if (-not (Test-Path Env:PS_NO_BANNER)) {
		& $CONFIG_DIR\banner.ps1
		$_Times.banner = Get-Date
	}
	# setup prompt
	Import-Module $CONFIG_DIR\FSNav
	. $CONFIG_DIR\prompt.ps1 $_Times
	# setup ZLocation
	Import-Module ZLocation
}