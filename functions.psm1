#Requires -Modules Wait-FileChange, Format-TimeSpan, ScratchFile, Oris, Recycle, Invoke-Notepad
Set-StrictMode -Version Latest

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
New-Alias e Push-ExplorerLocation

function cal {
	Set-Notebook CALENDAR
}

function history-npp {
	npp (Get-PSReadLineOption).HistorySavePath
}

function make {
	wsl -- make @Args
}

function manl {
	wsl -- man @Args
}

function Sleep-Computer {
	Add-Type -AssemblyName System.Windows.Forms
	$null = [System.Windows.Forms.Application]::SetSuspendState("Suspend", $false, $false)
}

class _CwdLnkShortcuts : System.Management.Automation.IValidateSetValuesGenerator {
    [String[]] GetValidValues() {
        return ls -File -Filter "./*.lnk" | Select-Object -ExpandProperty Name
    }
}

function lnk {
	param(
			[Parameter(Mandatory)]
			[ValidateSet([_CwdLnkShortcuts])]
			[string]
		$LnkPath
	)
	$Lnk = (New-Object -ComObject WScript.Shell).CreateShortcut((Resolve-Path $LnkPath))
	cd -LiteralPath $Lnk.TargetPath
}

function Push-ExplorerLocation {
	$Dirs = Get-ExplorerDirectories
	$Selected = Read-HostListChoice $Dirs -Prompt "Select directory to cd to:" `
			-NoInputMessage "No explorer windows found."
	Push-Location $Selected
}

function Test-SshConnection {
	param(
			[Parameter(Mandatory)]
			[string]
		$Login,
			[ValidateScript({Test-Path $_})]
			[string]
		$KeyFilePath
	)
	
	$OrigLEC = $LastExitCode
	$Arg = if ([string]::IsNullOrEmpty($KeyFilePath)) {@()} else {@("-i", $KeyFilePath)}
	try {
		$null = $(ssh $Login -o PasswordAuthentication=no @Arg exit) 2>&1
		return $LastExitCode -eq 0
	} catch {
		return $False
	} finally {
		$LastExitCode = $OrigLEC
	}
}

function Copy-SshId {
	param(
			[Parameter(Mandatory)]
			[string]
		$Login,
			[Parameter(Mandatory)]
			[ValidateScript({Test-Path $_})]
			[string]
		$KeyFilePath
	)
	
	$PubKeyPath = if ([IO.Path]::GetExtension($KeyFilePath) -eq "") {
		$KeyFilePath + ".pub"
	} else {
		$KeyFilePath
	}
	
	$KeyFilePath = Resolve-Path $KeyFilePath
	
	Write-Verbose "Testing if key is already installed..."
	if (Test-SSHConnection $Login $KeyFilePath) {
		return "Key already installed."
	}

	Write-Verbose "Installing key..."
	Get-Content $PubKeyPath | ssh $Login "mkdir -p ~/.ssh && cat >> ~/.ssh/authorized_keys"
	if ($LastExitCode -gt 0) {
		throw "Could not install public key for '$Login'."
	}
	Write-Verbose "Public key successfully installed for '$Login', trying to log in..."
	if (Test-SSHConnection $Login $KeyFilePath) {
		return "Key successfully installed."
	}
	throw "Key installation failed."
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


function Activate-Venv([string]$VenvName) {
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


function Get-ProcessHistory($Last = 10) {
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


#function Pause {
#	Write-Host -NoNewLine 'Press any key to continue...'
#	$null = $Host.UI.RawUI.ReadKey('NoEcho,IncludeKeyDown')
#}


# function sudo {
#	Start-Process -Verb RunAs -FilePath "pwsh" -ArgumentList (@("-NoExit", "-Command") + $args)
# }


function Update-PowerShell([switch]$Stable) {
	$InstallerScript = Invoke-RestMethod https://aka.ms/install-powershell.ps1
	$Installer = [ScriptBlock]::Create($InstallerScript)
	if ($Stable) {
		& $Installer -UseMSI
	} else {
		& $Installer -UseMSI -Preview
	}
	#Invoke-Expression "& { $(Invoke-RestMethod https://aka.ms/install-powershell.ps1) } -UseMSI -Preview"
}


function Get-CmdExecutionTime($index=-1) {
	$cmd = (Get-History)[$index]
	$executionTime = $cmd.EndExecutionTime - $cmd.StartExecutionTime
	return Format-TimeSpan $executionTime
}


Export-ModuleMember -Function * -Cmdlet * -Alias *