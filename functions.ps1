#Requires -Modules Wait-FileChange, Format-TimeSpan, Invoke-Notepad, ScratchFile

New-Alias npp Invoke-Notepad
New-Alias / Invoke-Scratch
New-Alias // Invoke-LastScratch
New-Alias env Update-EnvVar


Function Activate-Venv {
	.\venv\Scripts\Activate.ps1
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