Import-Module $PSScriptRoot\_Colors

Write-Host ("PowerShell v" + [string]$PSVersionTable.PSVersion) `
		-ForegroundColor $UIColors.PowerShellVersion

#Import-Module TODO
#Write-Host ""
#Get-Todo | Format-Todo -Color $UIColors.TODO

$NotebookStr = Get-Notebook
if (-not [string]::IsNullOrWhitespace($NotebookStr)) {
	Write-Host ""
	Write-Host -ForegroundColor $UIColors.Notebook $NotebookStr
}
