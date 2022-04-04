Import-Module $PSScriptRoot\_Colors

Write-HostColor ("PowerShell v" + [string]$PSVersionTable.PSVersion) `
		-ForegroundColor $UIColors.PowerShellVersion

$NotebookStr = Get-Notebook
if (-not [string]::IsNullOrWhitespace($NotebookStr)) {
	Write-HostColor "`n"
	Write-HostColor $NotebookStr -ForegroundColor $UIColors.Notebook
}
