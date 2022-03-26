Set-StrictMode -Version Latest

# this file is symlinked from $PROFILE in my configuration, resolve the real target
$PSCommandPath = Get-Item $PSCommandPath | % {if ($null -ne $_.Target) {$_.Target} else {$_}}
$PSScriptRoot = Split-Path $PSCommandPath

# only load the full profile when running inside
#  Windows Terminal or explicitly requested
if ((Test-Path Env:WT_SESSION) -or (Test-Path Env:PS_FULL_PROFILE)) {
	. $PSScriptRoot\profile_full.ps1
}
