#Requires -Modules Wait-FileChange, Format-TimeSpan, ScratchFile, Oris, Recycle, Invoke-Notepad

New-Alias ipy ipython
# where is masked by builtin alias for Where-Object
New-Alias which where.exe
New-Alias py python3.exe
New-Alias python python3.exe

Remove-Alias rm
New-Alias rm Remove-ItemSafely
New-Alias rmp Remove-Item

New-Alias / Invoke-Scratch
New-Alias // Invoke-LastScratch
New-Alias env Update-EnvVar
New-Alias venv Activate-Venv
New-Alias todo New-Todo
New-Alias npp Invoke-Notepad

function cal {
	Set-Notebook CALENDAR
}

function history-npp {
	npp (Get-PSReadLineOption).HistorySavePath
}

function Test-UdpConnection {
	param(
			[Parameter(Mandatory)]
			[string]
		$Host_,
			[Parameter(Mandatory)]
			[int]
		$Port,
			[string]
		$Message = "test"
	)

	$sock = New-Object System.Net.Sockets.UdpClient
	$enc = New-Object System.Text.ASCIIEncoding
	$bytes = $enc.GetBytes($Message)
	$sock.Connect($Host_, $Port)
	[void]$sock.Send($bytes, $bytes.Length)
	$sock.Close()
}

function ip {
	Get-NetIPAddress
		| ? {$_.AddressFamily -eq "IPv4" -and $_.SuffixOrigin -in @("Dhcp", "Manual") `
			-and !$_.InterfaceAlias.StartsWith("vEthernet")}
		| select InterfaceAlias, IPAddress
}

function oris {
	Get-OrisEnrolledEvents | Format-OrisEnrolledEvents
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
	
	$Machine = [Environment]::GetEnvironmentVariable($VarName, [EnvironmentVariableTarget]::Machine)
	$User = [Environment]::GetEnvironmentVariable($VarName, [EnvironmentVariableTarget]::User)
	
	$Value = if ($null -eq $Machine -or $null -eq $User) {
		[string]($Machine + $User)
	} else {
		$Machine + [IO.Path]::PathSeparator + $User
	}
	[Environment]::SetEnvironmentVariable($VarName, $Value)
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