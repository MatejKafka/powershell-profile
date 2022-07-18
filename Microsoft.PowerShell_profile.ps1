<# Entry point to my profile, automatically loaded by pwsh on startup. #>
Set-StrictMode -Version Latest

# only load the full profile on Windows when running inside Windows Terminal or explicitly requested
# change this if you don't use Windows Terminal
if (-not $IsWindows -or (Test-Path Env:WT_SESSION) -or (Test-Path Env:PS_FULL_PROFILE)) {
	# this file ($PSCommandPath) is symlinked from $PROFILE in my configuration, resolve the real target
	#  (.ResolvedTarget was added in v7.3.0-preview.2)
	Import-Module -DisableNameChecking `
		(Join-Path (Split-Path (Get-Item $PSCommandPath).ResolvedTarget) "profile_full")
} else {
	# function to load the full profile manually, if needed
	function full-profile {
		$ProfileDir = Split-Path (Get-Item $PSCommandPath).ResolvedTarget
		Import-Module $ProfileDir\profile_full -DisableNameChecking
	}
}
