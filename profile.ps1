# read current time for startup measurement
$_ProfileStartTime = Get-Date


if ($PSVersionTable.PSVersion.Major -lt 7) {
	# older, possibly unsupported version, probably powershell.exe instead of pwsh.exe
	Write-Warning "Old powershell version, custom profile.ps1 disabled"
	exit 0
}


Set-StrictMode -Version Latest
# stop even on non-critical errors
# unfortunately, this only works for cmdlets and functions, not native commands
$ErrorActionPreference = "Stop"
$PSDefaultParameterValues['*:Encoding'] = 'utf8'


# RGB colors for Write-Host
Import-Module Pansies


New-Alias ipy ipython
# builtin alias for Where-Object masks where.exe
Remove-Alias where -Force


$CONFIG_DIR = Resolve-Path "D:\config\programs\powershell\"


. $CONFIG_DIR\functions.ps1
. $CONFIG_DIR\prompt.ps1 $_ProfileStartTime $CONFIG_DIR