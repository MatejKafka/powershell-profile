Set-StrictMode -Version Latest


Set-Alias ipy ipython
Set-Alias rms Remove-ItemSafely
Set-Alias man Get-ConciseHelp

if ($IsWindows) {
	# where is masked by builtin alias for Where-Object
	Set-Alias which where.exe
	Set-Alias py python.exe

	Set-Alias grep Select-String
}


Set-Alias / Invoke-Scratch
Set-Alias // Invoke-LastScratch
Set-Alias venv Activate-Venv
Set-Alias npp Invoke-Notepad
Set-Alias e Push-ExternalLocation
Set-Alias o Open-TextFile


function .. {
	cd ..
}

<# "mkdir and enter" #>
function mke($Path) {
	cd -LiteralPath (mkdir $Path)
}

<# remove dir and cd .. #>
function rme {
	$wd = Get-Location
	cd ..
	rm -Recurse -Force $wd
}

function gits {
	git status @Args
}
function gitd {
	git diff @Args
}
function gitdc {
	git diff --cached @Args
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

function Get-GithubVersion([string[]]$Repo) {
	foreach ($r in $Repo) {
		Get-GithubRelease $r | select -First 1 | % tag_name
			| % {if ($_ -like "v*") {$_.Substring(1)} else {$_}}
	}
}

function todo ([string]$TodoText) {
	if ([string]::IsNullOrEmpty($TodoText)) {
		Write-HostColor "TODO:" -ForegroundColor "#909060"
		Get-Todo | % {" $_"} | Write-HostColor -ForegroundColor "#909060"
	} else {
		New-Todo $TodoText
	}
}

function find($Pattern, $Path = ".", $Context = 0, [switch]$CaseSensitive) {
	ls -Recurse -File $Path | ? {$_.Target -eq $null}
		| Select-String $Pattern -Context $Context -CaseSensitive:$CaseSensitive -ErrorAction Continue
}

function findo($Pattern, $Path = ".", $Context = 0, [switch]$CaseSensitive, [switch]$Gui) {
	$Path = Resolve-Path $Path
	find $Pattern $Path $Context -CaseSensitive:$CaseSensitive
		| Read-HostListChoice -FormatSb {$_.ToEmphasizedString($Path)}
		| % {o $_.Path $_.LineNumber -Gui:$Gui}
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

# source: https://github.com/sethvs/sthArgumentCompleter/blob/master/sthArgumentCompleterFunctions.ps1
function Get-ArgumentCompleter
{
    Param (
		[switch]$Native,
		[switch]$Custom
    )

	if (-not $Native -and -not $Custom) {
		$Native = $true
		$Custom = $true
	}

    $flags = [System.Reflection.BindingFlags]'Instance,NonPublic'
    $_context = $ExecutionContext.GetType().GetField('_context',$flags).GetValue($ExecutionContext)

    if ($Custom) {
        $_context.GetType().GetProperty('CustomArgumentCompleters',$flags).GetValue($_context)
    }
	if ($Native) {
        $_context.GetType().GetProperty('NativeArgumentCompleters',$flags).GetValue($_context)
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
	[string[]] GetValidValues() {
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

function tmp($Extension, $Prefix = "") {
	$Tmp = if ($IsWindows) {$env:TEMP} else {"/tmp"}
    return Join-Path $Tmp "$Prefix$(New-Guid)$Extension"
}


# streams
function drop {
	<#
		.SYNOPSIS
		Drops items in pipeline until either `N` items are dropped, or an item satisfies the `Until` condition.
	#>
	[CmdletBinding()]
	param(
		[Parameter(Mandatory, ValueFromPipeline)]
		$InputObject,
		[Parameter(Mandatory, Position = 0, ParameterSetName = "N")]
		[int]
		$N,
		[Parameter(Mandatory, Position = 0, ParameterSetName = "Until")]
		[scriptblock]
		$Until,
		[Parameter(Mandatory, ParameterSetName = "eq")]
		[AllowNull()]
		$eq,
		[Parameter(Mandatory, ParameterSetName = "ne")]
		[AllowNull()]
		$ne
	)

	begin {
		if ($MyInvocation.BoundParameters.ContainsKey("eq")) {
			$Until = {$_ -eq $eq}
		} elseif ($MyInvocation.BoundParameters.ContainsKey("ne")) {
			$Until = {$_ -ne $ne}
		}

		$i = 0
		if ($Until) {
			$N = 1
		}
	}

	process {
		if ($i -ge $N) {
			return $_
		}

		if (-not $Until) {
			$i++
		} else {
			if ($Until.InvokeWithContext(@{}, [System.Collections.Generic.List[psvariable]][psvariable]::new('_', $_), @())) {
				$N = 0
				return $_
			}
		}
	}
}


$NotebookPath = Get-PSDataPath "Notebook.txt"
function Get-Notebook {
	Get-Content -Raw $NotebookPath
}
function notes {
	Open-TextFile $NotebookPath
}

Export-ModuleMember -Function * -Cmdlet * -Alias *
