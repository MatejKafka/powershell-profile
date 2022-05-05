Import-Module $PSScriptRoot\Colors

Write-HostColor ("PowerShell v" + [string]$PSVersionTable.PSVersion) `
		-ForegroundColor $UIColors.PowerShellVersion

$NotebookStr = Get-Notebook
if (-not [string]::IsNullOrWhitespace($NotebookStr)) {
	Write-HostColor ""
	Write-HostColor $NotebookStr -ForegroundColor $UIColors.Notebook
}
