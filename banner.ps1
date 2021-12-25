Write-Host ("PowerShell v" + [string]$PSVersionTable.PSVersion) -ForegroundColor "#666696"

#Import-Module TODO
#Write-Host ""
#Get-Todo | Format-Todo -Color "#909060"

Import-Module Notes
$Notebooks = Get-Notebook
if ($null -ne $Notebooks) {
	Write-Host ""
	$Notebooks | % {
		Write-Host $_ -ForegroundColor "#907070"
	}
}