<#
	Returns all directories opened in File Explorer.
	File Explorer must have the option to list full path as window title enabled for this to work.
#>
function Get-ExplorerDirectory {
	[CmdletBinding()]
	[OutputType([IO.DirectoryInfo])]
	param()

	return AutoHotkey (Resolve-Path $PSScriptRoot\getWindows.ahk) `
		| ? {$_ -like "explorer.exe*"} `
		| % {$_.Split(" ", 2)[1]} `
		| ? {$_ -notin @("", "Program Manager")} `
		| ? {[IO.Path]::IsPathRooted($_)} `
		| Get-Item
}

function Get-AltapSalamanderDirectory {
	[CmdletBinding()]
	[OutputType([IO.DirectoryInfo])]
	param()

	return AutoHotkey (Resolve-Path $PSScriptRoot\getWindows.ahk) `
		| ? {$_ -like "salamand.exe*"} `
		| % {$_.Split(" ", 2)[1]} `
		| % {$i = $_.LastIndexOf(" - "); $_.Substring(0, $i)}
		| ? {[IO.Path]::IsPathRooted($_)} `
		| Get-Item
}