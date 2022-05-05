<#
	Returns all directories opened in File Explorer.
	File Explorer must have the option to list full path as window title enabled for this to work.
#>
function Get-ExplorerDirectory {
	[CmdletBinding()]
	[OutputType([IO.DirectoryInfo])]
	param()

	$ExplorerPids = Get-Process explorer -ErrorAction Ignore | % Id
	return [FileManagerDirectory.Win32Window]::GetWindows()
		| ? ProcessId -in $ExplorerPids
		| % Title
		# File Explorer windows have the full path as window title
		| ? {Test-Path -Type Container $_}
		| Get-Item
}

function Get-AltapSalamanderDirectory {
	[CmdletBinding()]
	[OutputType([IO.DirectoryInfo])]
	param()

	$SalamanderPids = Get-Process salamand -ErrorAction Ignore | % Id
	return [FileManagerDirectory.Win32Window]::GetWindows()
		| ? ProcessId -in $SalamanderPids
		| % Title
		# filter out windows like Find, Configuration,...
		| ? {$_ -like "*Altap Salamander*"}
		# Title is something like 'C:\Path - Altap Salamander 4.0 (x64)'
		| % {$i = $_.LastIndexOf(" - "); $_.Substring(0, $i)}
		| ? {Test-Path -Type Container $_}
		| Get-Item
}

function Get-FileManagerDirectory {
	[CmdletBinding()]
	[OutputType([IO.DirectoryInfo])]
	param()

	Get-ExplorerDirectory
	Get-AltapSalamanderDirectory
}
