Set-StrictMode -Version Latest


New-Alias ipy ipython
# where is masked by builtin alias for Where-Object
New-Alias which where.exe
New-Alias py python3.exe
New-Alias python python3.exe

Remove-Alias rm
New-Alias rm Remove-ItemSafely
New-Alias rmp Remove-Item
New-Alias grep Select-String

Remove-Alias diff -Force
New-Alias diff delta.exe

New-Alias / Invoke-Scratch
New-Alias // Invoke-LastScratch
New-Alias env Update-EnvVar
New-Alias venv Activate-Venv
New-Alias npp Invoke-Notepad
New-Alias e Push-ExternalLocation

function msvc([ValidateSet('x86','amd64','arm','arm64')]$Arch = 'amd64') {
	# 2019
	#& 'C:\Program Files (x86)\Microsoft Visual Studio\2019\BuildTools\Common7\Tools\Launch-VsDevShell.ps1'
	# 2022, doesn't work from my pwsh config, uses an undefined variable
	#& 'C:\Program Files\Microsoft Visual Studio\2022\Enterprise\Common7\Tools\Launch-VsDevShell.ps1'
	
	# replacement manual script
	$VsWherePath = Join-Path ${env:ProgramFiles(x86)} "\Microsoft Visual Studio\Installer\vswhere.exe"
	$VsPath = & $VsWherePath -Property InstallationPath
	Import-Module (Join-Path $VsPath "\Common7\Tools\Microsoft.VisualStudio.DevShell.dll")
	Enter-VsDevShell -Arch $Arch -VsInstallPath $VsPath
}

function todo ([string]$TodoText) {
	if ([string]::IsNullOrEmpty($TodoText)) {
		Get-Todo | Format-Todo -Color "#909060"
	} else {
		New-Todo $TodoText
	}
}

function find($Pattern, $Path = ".", [switch]$CaseSensitive) {
	ls -Recurse $Path | Select-String $Pattern -CaseSensitive:$CaseSensitive
}

function Get-LatestEmail($HowMany, $ConfigFile) {
	$Server = Connect-EmailServer -FilePath $ConfigFile
	$Folder = $Server.Emails
	$CurrentDate = Get-Date
	$Folder.Fetch([math]::Max($Folder.Count - $HowMany, 0), -1, [MailKit.MessageSummaryItems]::Envelope)
		| % Envelope
		| % {[pscustomobject]@{
			Age = Format-Age $_.Date.DateTime $CurrentDate
			Sender = $_.From.Name ?? $_.From.Address
			Subject = $_.Subject
		}}
}



<# Open current directory in Altap Salamander. #>
function so([ValidateSet("Left", "Right", "Active", "L", "R", "A")]$Pane = "Right") {
	& "C:\Program Files\Altap Salamander\salamand.exe" $(switch -Wildcard ($Pane) {
		L* {"-O", "-P", 1, "-L", (pwd)}
		R* {"-O", "-P", 2, "-R", (pwd)}
		A* {"-O", "-A", (pwd)}
	})
}
<# Set current directory to the dir open in Altap Salamander. #>
function s {
	Get-AltapSalamanderDirectory | select -First 1 | % FullName | Push-Location
}

class _CommandName : System.Management.Automation.IValidateSetValuesGenerator {
    [String[]] GetValidValues() {
        return Get-Command -Type Alias, Cmdlet, ExternalScript, "Function" | % Name
    }
}

function edit {
	param(
			[Parameter(Mandatory)]
			[ValidateSet([_CommandName])]
			[string]
		$CommandName
	)

	$Cmd = Get-Command $CommandName -Type Alias, Cmdlet, ExternalScript, "Function"
	$Path = switch ($Cmd.CommandType) {
		Alias {$Cmd.ResolvedCommand.Module.Path}
		ExternalScript {$Cmd.Source}
		default {$Cmd.Module.Path}
	}

	if ($Path) {
		# this should open the file in editor, not execute it
		& $Path
	} else {
		throw "Could not find path of the module containing the command '$CommandName'."
	}
}

function Resolve-VirtualPath {
	param([Parameter(Mandatory)]$Path)
	return $ExecutionContext.SessionState.Path.GetUnresolvedProviderPathFromPSPath($Path)
}

function make {
	wsl -- bash -ic "make $Args"
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

class _WifiNames : System.Management.Automation.IValidateSetValuesGenerator {
	[String[]] GetValidValues() {
		return Get-WiFiProfile | % ProfileName
	}
}

function Get-Wifi {
	param(
			[ValidateSet([_WifiNames])]
			[string]
		$Name
	)
	return Get-WifiProfile -ClearKey $Name
}

function Push-ExternalLocation {
	$Dirs = @()
	$Dirs += Get-ExplorerDirectory
	$Dirs += Get-AltapSalamanderDirectory

	$Clip = Get-Clipboard | select -First 1 # only get first line of clipboard
	if (Test-Path -Type Container $Clip) {
		$Dirs += Get-Item $Clip
	} elseif (Test-Path -Type Leaf $Clip) {
		$Dirs += Get-Item (Split-Path $Clip)
	}

	$Selected = Read-HostListChoice $Dirs -Prompt "Select directory to cd to:" `
			-NoInputMessage "No Explorer, Altap Salamander or clipboard locations found."
	Push-Location $Selected
}

function ssh-config {
	Open-TextFile $env:HOME\.ssh\config
}


function oris {
	Get-OrisEnrolledEvents | Format-OrisEnrolledEvents
}

function BulkRename() {
	[array]$Items = ls @Args
	if ($null -eq $Items) {throw "No items to rename"}
	$TempFile = New-TemporaryFile
	$Items | select -ExpandProperty Name | Out-File $TempFile
	Open-TextFile $TempFile
	[array]$NewNames = cat $TempFile
	rm $TempFile
	if ($Items.Count -ne $NewNames.Count) {
		throw "You must not add, delete or reorder lines"
	}

	$Renamed = 0
	for ($i = 0; $i -lt $Items.Count; $i++) {
		if ($Items[$i].Name -ne $NewNames[$i]) {
			Rename-Item $Items[$i] $NewNames[$i]
			$Renamed++
		}
	}
	Write-Host "Renamed $Renamed items."
}

function Activate-Venv([string]$VenvName) {
	if ("" -eq $VenvName) {
		$Paths = ".\venv\Scripts\Activate.ps1", ".\.venv\Scripts\Activate.ps1"
	} else {
		$Paths = ".\$VenvName\Scripts\Activate.ps1"
	}

	$Dir = Get-Location
	while ($True) {
		$Path = $Paths | % {Join-Path $Dir $_} | ? {Test-Path $_} | select -First 1
		if ($Path) {break}

		$Dir = Split-Path $Dir
		if ($Dir -eq "") {
			throw "No venv found."
		}
	}
	& $Path
	echo "Activated venv in '$Dir'."
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


function Update-PowerShell([switch]$Stable) {
	$InstallerScript = Invoke-RestMethod https://aka.ms/install-powershell.ps1
	$Installer = [ScriptBlock]::Create($InstallerScript)
	if ($Stable) {
		& $Installer -UseMSI
	} else {
		& $Installer -UseMSI -Preview
	}
}


function Get-CmdExecutionTime($index=-1) {
	$cmd = (Get-History)[$index]
	$executionTime = $cmd.EndExecutionTime - $cmd.StartExecutionTime
	return Format-TimeSpan $executionTime
}


Export-ModuleMember -Function * -Cmdlet * -Alias *
