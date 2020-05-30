#Requires -Modules Wait-FileChange, Format-TimeSpan, Invoke-Notepad, ScratchFile

Import-Module D:\_\Pkg\app\Pkg.psm1

New-Alias npp Invoke-Notepad
New-Alias / Invoke-Scratch
New-Alias // Invoke-LastScratch
New-Alias env Update-EnvVar
New-Alias venv Activate-Venv


function uip {
	Get-VMIPAddress "ubuntu"
}

function vm_ubuntu {
	$IP = Get-VMIPAddress "ubuntu"
	Set-ItemProperty "HKCU:\Software\Martin Prikryl\WinSCP 2\Sessions\vm_ubuntu" -Name "HostName" -Value $IP
	echo $IP
}


Function Activate-Venv([string]$VenvName) {
	if ("" -eq $VenvName) {
		$path = ".\venv\Scripts\Activate.ps1"
	} else {
		$path = ".\$VenvName\Scripts\Activate.ps1"
	}

	$dir = Get-Location
	while (-not (Test-Path (Join-Path $dir $path))) {
		$dir = Split-Path $dir
		if ($dir -eq "") {
			throw "No venv found."
		}
	}
	& (Join-Path $dir $path)
	echo "Activated venv in '$dir'."
}


Function mktxt($filename) {
	New-Item $filename
	Invoke-Notepad $filename
}


Function Get-ProcessHistory($Last = 10) {
	Get-WinEvent Security |
		where id -eq 4688 |
		select -First $Last |
		select TimeCreated, @{Label = "Command"; Expression = {$_.Properties[8].Value}}
}


function Update-EnvVar {
	param(
			[Parameter(Mandatory)]
			[string]
		$VarName
	)
	
	[Environment]::SetEnvironmentVariable($VarName,
		[Environment]::GetEnvironmentVariable($VarName, [EnvironmentVariableTarget]::Machine) +
		[IO.Path]::PathSeparator +
		[Environment]::GetEnvironmentVariable($VarName, [EnvironmentVariableTarget]::User))
}


#Function Pause {
#	Write-Host -NoNewLine 'Press any key to continue...'
#	$null = $Host.UI.RawUI.ReadKey('NoEcho,IncludeKeyDown')
#}


# function sudo {
#	Start-Process -Verb RunAs -FilePath "pwsh" -ArgumentList (@("-NoExit", "-Command") + $args)
# }


Function Update-PowerShell([switch]$Stable) {
	$InstallerScript = Invoke-RestMethod https://aka.ms/install-powershell.ps1
	$Installer = [ScriptBlock]::Create($InstallerScript)
	if ($Stable) {
		& $Installer -UseMSI
	} else {
		& $Installer -UseMSI -Preview
	}
	#Invoke-Expression "& { $(Invoke-RestMethod https://aka.ms/install-powershell.ps1) } -UseMSI -Preview"
}


Function Get-CmdExecutionTime($index=-1) {
	$cmd = (Get-History)[$index]
	$executionTime = $cmd.EndExecutionTime - $cmd.StartExecutionTime
	return Format-TimeSpan $executionTime
}