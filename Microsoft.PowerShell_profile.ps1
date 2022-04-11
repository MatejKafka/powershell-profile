<# Entry point to my profile. #>
Set-StrictMode -Version Latest


# this file is symlinked from $PROFILE in my configuration, resolve the real target
$PSCommandPath = Get-Item $PSCommandPath
		| % {if ($null -ne $_.Target) {$_.Target} else {$_}}
		| % {[IO.Path]::Combine($PSScriptRoot, $_)}
		| Resolve-Path
$PSScriptRoot = Split-Path $PSCommandPath

# only load the full profile on Windows when running inside Windows Terminal or explicitly requested
# change this if you don't use Windows Terminal
if (-not $IsWindows -or (Test-Path Env:WT_SESSION) -or (Test-Path Env:PS_FULL_PROFILE)) {
	Import-Module $PSScriptRoot\profile_full -DisableNameChecking
}
