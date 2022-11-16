<# Entry point to my profile, automatically loaded by pwsh on startup. #>

Set-StrictMode -Version Latest

# only load the full profile on Windows when explicitly requested or running inside one of specific terminals
# change this if you want the profile to load in other terminals
if (-not $IsWindows `
		-or [Environment]::GetEnvironmentVariable("PS_FULL_PROFILE") <# manual override #> `
		-or [Environment]::GetEnvironmentVariable("WT_SESSION") <# Windows Terminal #> `
		-or [Environment]::GetEnvironmentVariable("TERMINAL_EMULATOR") -eq "JetBrains-JediTerm" <# JetBrains IDE terminal #> `
		) {
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
