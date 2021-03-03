Import-Module TODO
Import-Module Notes

Write-Host ("PowerShell v" + [string]$PSVersionTable.PSVersion) -ForegroundColor "#666696"
Write-Host ""
Get-Todo | Format-Todo -Color "#909060"
Write-Host ""
Get-Notebook | % {
	Write-Host $_ -ForegroundColor "#907070"
}