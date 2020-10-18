# read current time for startup measurement
$_Times = @{
	internal = Get-Date
}

Set-StrictMode -Version Latest
# stop even on non-critical errors
# unfortunately, this only works for cmdlets and functions, not native commands
$ErrorActionPreference = "Stop"
$PSDefaultParameterValues["*:ErrorAction"] = $ErrorActionPreference
$PSDefaultParameterValues["*:Encoding"] = "utf8"
# $ProgressPreference = "SilentlyContinue"


# to support symlinked profile path
$CONFIG_DIR = Split-Path (Get-Item $PSCommandPath).Target
# add custom module directory
$env:PSModulePath += [IO.Path]::PathSeparator + (Resolve-Path $CONFIG_DIR"\Custom")

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

if ($env:SIMPLE_PROMPT -ne $null) {
	return # do not setup custom prompt and banner
}

Import-Module $CONFIG_DIR\FSNav
$_Times.imports = Get-Date

& $CONFIG_DIR\banner.ps1

$_Times.banner = Get-Date
# setup prompt
. $CONFIG_DIR\prompt.ps1 $_Times
# setup ZLocation
Import-Module ZLocation