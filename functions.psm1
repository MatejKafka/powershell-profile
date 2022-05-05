Set-StrictMode -Version Latest


New-Alias ipy ipython
New-Alias rms Remove-ItemSafely

if ($IsWindows) {
	# where is masked by builtin alias for Where-Object
	New-Alias which where.exe
	New-Alias py python.exe

	New-Alias grep Select-String

	if (Get-Command delta.exe) {
		Remove-Alias diff -Force -ErrorAction Ignore
		New-Alias diff delta.exe
	}
}


New-Alias / Invoke-Scratch
New-Alias // Invoke-LastScratch
New-Alias venv Activate-Venv
New-Alias npp Invoke-Notepad
New-Alias e Push-ExternalLocation
New-Alias o Open-TextFile


function .. {
	cd ..
}

<# "mkdir and enter" #>
function mke($Path) {
	$null = mkdir $Path
	cd $Path
}

<# remove dir and cd .. #>
function rme {
	$wd = Get-Location
	cd ..
	rm -Recurse -Force $wd
}

function msvc([ValidateSet('x86','amd64','arm','arm64')]$Arch = 'amd64') {
	# 2019
	#& 'C:\Program Files (x86)\Microsoft Visual Studio\2019\BuildTools\Common7\Tools\Launch-VsDevShell.ps1'
	# 2022, doesn't work from my pwsh config, uses an undefined variable
	#& 'C:\Program Files\Microsoft Visual Studio\2022\Enterprise\Common7\Tools\Launch-VsDevShell.ps1'
	
	# replacement manual script
	$VsWherePath = Join-Path ${env:ProgramFiles(x86)} "\Microsoft Visual Studio\Installer\vswhere.exe"
	$VsPath = & $VsWherePath -products * -latest -property installationPath
	if ($null -eq $VsPath) {
		throw "'vswhere.exe' could not find any MSVC installation."
	}
	Import-Module (Join-Path $VsPath "\Common7\Tools\Microsoft.VisualStudio.DevShell.dll")
	Enter-VsDevShell -Arch $Arch -HostArch amd64 -VsInstallPath $VsPath
}

function todo ([string]$TodoText) {
	if ([string]::IsNullOrEmpty($TodoText)) {
		Write-HostColor "TODO:" -ForegroundColor "#909060"
		Get-Todo | % {" $_"} | Write-HostColor -ForegroundColor "#909060"
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
function so([ValidateSet("Left", "Right", "Active", "L", "R", "A")]$Pane = "Right", $Path = (Get-Location)) {
	& "C:\Program Files\Altap Salamander\salamand.exe" $(switch -Wildcard ($Pane) {
		L* {"-O", "-P", 1, "-L", $Path}
		R* {"-O", "-P", 2, "-R", $Path}
		A* {"-O", "-A", $Path}
	})
}
<# Set current directory to the dir open in Altap Salamander. #>
function s {
	Get-AltapSalamanderDirectory | select -First 1 | % FullName | Set-Location
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
		$CommandName,
			[switch]
		$Gui
	)

	$Cmd = Get-Command $CommandName -Type Alias, Cmdlet, ExternalScript, "Function"
	while ($Cmd.CommandType -eq "Alias") {
		# resolve alias
		$Cmd = $Cmd.ResolvedCommand
	}

	$EditorArgs = switch ($Cmd.CommandType) {
		ExternalScript {$Cmd.Source}
		"Function" {@($Cmd.ScriptBlock.File, $Cmd.ScriptBlock.StartPosition.StartLine)}
		Cmdlet {
			# we cannot edit cmdlet, it's a DLL; instead, open the module directory
			explorer $Cmd.Module.ModuleBase
			return
		}
	}

	if ($EditorArgs) {
		Open-TextFile @EditorArgs -Gui:$Gui
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
	[array]$Dirs = Get-FileManagerDirectory

	$Clip = Get-Clipboard | select -First 1 # only get first line of clipboard
	if (Test-Path -Type Container $Clip) {
		$Dirs += Get-Item $Clip
	} elseif (Test-Path -Type Leaf $Clip) {
		$Dirs += Get-Item (Split-Path $Clip)
	}

	$Selected = Read-HostListChoice $Dirs -Prompt "Select directory to cd to:" `
			-NoInputMessage "No Explorer, Altap Salamander or clipboard locations found."
	Set-Location $Selected
}

function ssh-config {
	Open-TextFile $HOME\.ssh\config
}


function oris {
	Get-OrisEnrolledEvents | Format-OrisEnrolledEvents
}

function BulkRename() {
	[array]$Items = Get-Item @Args
	if ($null -eq $Items) {throw "No items to rename"}
	$TempFile = New-TemporaryFile
	$Items | select -ExpandProperty Name | Out-File $TempFile
	Open-TextFile $TempFile
	[array]$NewNames = cat $TempFile
	rm $TempFile
	if ($Items.Count -ne $NewNames.Count) {
		throw "You must not add, delete or reorder lines"
	}

	$Renames = @()
	for ($i = 0; $i -lt $Items.Count; $i++) {
		if ($Items[$i].Name -ne $NewNames[$i]) {
			$Renames += ,@($Items[$i], $NewNames[$i])
		}
	}

	Write-Host "The following items will be renamed:"
	$Renames | % {
		Write-Host "    $($_[0]) -> $($_[1])"
	}

	if (@($Renames).Count -eq 0) {
		Write-Host "No files renamed."
		return
	}

	$Options = @("&Yes", "&No")
	$Continue = switch ($Host.UI.PromptForChoice("Execute renames?", $null, $Options, 0)) {
		0 {$true} # Yes
		1 {$false} # No
	}

	if ($Continue) {
		$Renames | % {Rename-Item $_[0] $_[1]}
		Write-Host "Renamed $(@($Renames).Count) items."
	} else {
		Write-Host "Rename aborted."
	}
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


$NotebookPath = Get-PSDataPath "Notebook.txt"
function Get-Notebook {
	Get-Content -Raw $NotebookPath
}
function notes {
	Open-TextFile $NotebookPath
}

Export-ModuleMember -Function * -Cmdlet * -Alias *
