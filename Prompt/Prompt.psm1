param(
		[Parameter(Mandatory)]
		[HashTable]
	$Times
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"
Export-ModuleMember # don't export anything

$script:ReuseLastCommandStatus = $false
$script:LastStatusString = ""

Import-Module $PSScriptRoot\Colors
Import-Module $PSScriptRoot\PSReadLineOptions
Import-Module $PSScriptRoot\FSNav -ArgumentList ([ref]$script:ReuseLastCommandStatus)


# written by our overriden version of Out-Default
$script:_LastCmdOutputTypes = @()
# without setting this, drawing prompt would fail
$global:LastExitCode = 0
# otherwise python venv would break our fancy Prompt
$Env:VIRTUAL_ENV_DISABLE_PROMPT = $true
# this shows a progress bar on taskbar and in terminal tab icon in Windows Terminal
$PSStyle.Progress.UseOSCIndicator = $true

$script:FirstPromptTime = $null


function Get-StartupTimeStatus {
	if ($script:FirstPromptTime -eq $null) {
		$script:FirstPromptTime = Get-Date
		$script:Times.rest = $script:FirstPromptTime
	}

	$LoadStartTime = (Get-Process -Id $pid).StartTime
	$StartupTime = $script:FirstPromptTime - $LoadStartTime
	$StartupTimeStr += "startup: " + (Format-TimeSpan $StartupTime)

	$Sorted = ,@{Name = $null; Value = $LoadStartTime}
	$Sorted += $script:Times.GetEnumerator() | Sort-Object -Property Value
	$TimeStrings = @()
	for ($i = 1; $i -lt $Sorted.Count; $i += 1) {
		$_ = $Sorted[$i]
		$TimeStrings += $_.Name + ": " + (Format-TimeSpan ($_.Value - $Sorted[$i - 1].Value))
	}

	return $StartupTimeStr + " | " +  ($TimeStrings -join ", ")
}

function Get-LastCommandStatus {
	param(
			[Parameter(Mandatory)]
			[Microsoft.PowerShell.Commands.HistoryInfo]
		$LastCmd,
			[Parameter(Mandatory)]
			[boolean]
		$ErrorOccurred,
			[Parameter(Mandatory)]
			[int]
		$LastExitCode,
			[Parameter(Mandatory)]
			[AllowEmptyCollection()]
			[System.Type[]]
		$LastCmdOutputTypes
	)

	# status string indicating outcome of previous command
	$StatusStr = ""

	# render output type of previous command, unless it resulted in an error
	if ($LastCmdOutputTypes.Length -gt 0 -and -not $ErrorOccurred) {
		$FirstType = $LastCmdOutputTypes[0].ToString()
		if ($FirstType -match "System\.(.*)") {
			$FirstType = $Matches[1] # strip System.
		}
		if ($LastCmdOutputTypes.Length -gt 1) {
			$StatusStr += "[" + $LastCmdOutputTypes.Length + "]"
		}
		$StatusStr += $FirstType + " | "
	}

	# print exit code if error occurred
	if ($ErrorOccurred) {
		if ($LastExitCode -eq -1073741510 -or $LastCmd.ExecutionStatus -eq "Stopped") {
			$StatusStr += "Ctrl-C | "
		} elseif ($LastExitCode -eq 0) {
			# error originates from powershell
			$StatusStr += "Error | "
		} else {
			# error from external command
			$StatusStr += [string]$LastExitCode + " | "
		}
	}

	$ExecutionTime = $LastCmd.EndExecutionTime - $LastCmd.StartExecutionTime
	$StatusStr += Format-TimeSpan $ExecutionTime
	return $StatusStr
}


# this function is taken from `posh-git` module and simplified a bit to speed up startup
# loading the whole posh-git module caused quite a long delay, and we only need this one function
function Get-GitDirectory {
	$pathInfo = Get-Location
	if (!$pathInfo -or ($pathInfo.Provider.Name -ne 'FileSystem')) {
		$null
	} elseif ($Env:GIT_DIR) {
		$Env:GIT_DIR -replace '\\|/', [System.IO.Path]::DirectorySeparatorChar
	} else {
		$currentDir = Get-Item -LiteralPath $pathInfo -Force
		for (; $currentDir; $currentDir = $currentDir.Parent) {
			$gitDirPath = Join-Path $currentDir .git
			if (Test-Path -LiteralPath $gitDirPath -Type Container) {
				return $gitDirPath
			}
		}
	}
}

function Write-ShellStatus($InfoColor) {
	function Write-InfoStatus($Status) {
		Write-HostColor "($Status)" -NoNewLine -ForegroundColor $InfoColor
	}

	# show if we're in debug mode; in 7.3.0-preview.2, this is currently broken due to scoping rules
	if (Get-Variable PSDebugContext -ErrorAction Ignore) {
		Write-InfoStatus "DBG"
	}

	# show if we're inside a MSVC Developer shell
	if ($null -ne $env:VSINSTALLDIR) {
		Write-InfoStatus "msvc"
	}

	# show if we're running with active python venv
	if ($null -ne $env:VIRTUAL_ENV) {
		$VenvName = Split-Path -Leaf $env:VIRTUAL_ENV
		Write-InfoStatus $VenvName
	}

	if (Test-Path -Type Container .) {
		# show if we're inside a git repository
		$GitDir = Get-GitDirectory
		if ($GitDir) {
			$GitStr = try {
				$RefStr = cat (Join-Path $GitDir "./HEAD")
				# "ref: refs/heads/".Length
				$BranchName = $RefStr.Substring(16)
				"git:" + $BranchName
			} catch {"git"}
			Write-InfoStatus $GitStr
		}
	} else {
		Write-HostColor "(X)" -NoNewLine -ForegroundColor "Red"
	}
}


$script:LastCmdId = $null

function global:Prompt {
	$ErrorOccurred = -not ($? -and ($global:LastExitCode -eq 0))

	$Colors = $ErrorOccurred ? $UIColors.Prompt.Error : $UIColors.Prompt.Ok
	$Color = $Colors.Base
	$CwdColor = $Colors.Highlight
	$StatusColor = $Colors.Status

	# render status string
	$LastCmd = Get-History -Count 1
	$StatusStr = if ($LastCmd -eq $null) {
		# render startup timings
		Get-StartupTimeStatus
	} elseif ($script:ReuseLastCommandStatus) {
		$script:ReuseLastCommandStatus = $false
		$script:LastStatusString
	} elseif ($LastCmd.Id -ne $script:LastCmdID) {
		$script:LastCmdId = $LastCmd.Id
		# render previous command status
		Get-LastCommandStatus $LastCmd $ErrorOccurred $global:LastExitCode $script:_LastCmdOutputTypes
	} else {
		"" # either we're re-rendering prompt in the same place, or user pressed enter without entering a command
	}

	$script:LastStatusString = $StatusStr

	# write the horizontal separator and status string
	if ($StatusStr) {
		Write-HostColor ("╦" + "═" * ($Host.UI.RawUI.WindowSize.Width - 4 - $StatusStr.Length) + "") -ForegroundColor $Color -NoNewLine
		Write-HostColor $StatusStr -BackgroundColor $Color -ForegroundColor $StatusColor -NoNewLine
		Write-HostColor "═" -ForegroundColor $Color
	} else {
		Write-HostColor ("╦" + "═" * ($Host.UI.RawUI.WindowSize.Width - 1)) -ForegroundColor $Color
	}
	Write-HostColor "╚╣" -NoNewLine -ForegroundColor $Color
	Write-ShellStatus $Color
	Write-HostColor -NoNewLine " "

	$CwdString = [string](Get-Location)
	
	# write the prompt itself
	Write-HostColor $CwdString -NoNewLine -ForegroundColor $CwdColor

	# set indent of continuation prompt to match the main prompt (so that multiline code in the prompt has no jumps between lines)
	Set-PSReadLineOption -ContinuationPrompt (" " * [math]::max(0, $Host.UI.RawUI.CursorPosition.X - 1) + ">> ")


	# set tab/window title to the shortened version of CWD (my Windows Terminal tab title fits roughly 25 chars (it's non-monospace))
	$Host.UI.RawUI.WindowTitle = if ($CwdString.Length -le 25) {
		$CwdString
	} else {
		$Trimmed = $CwdString.Substring($CwdString.Length - 25)
		$SlashI = $Trimmed.IndexOfAny("\/")
		"…" + $(if ($SlashI -ge 0) {$Trimmed.Substring($SlashI)} else {$Trimmed})
	}

	
	# reset exit code
	$global:LastExitCode = 0
	# reset last output types and move them to the user-accessible $global:Types variable
	$global:Types = $script:_LastCmdOutputTypes
	$script:_LastCmdOutputTypes = @()

	return "> "
}


<#
	This override allows us to capture the types of all output objects and display them in the prompt.

	ISSUE: PowerShell internally sets $_ based on success of last command;
		 this override contains some commands, so we'll lose the success status of previous
		 command entered by user, as it's overwritten by status of commands in this function
		this is tolerable, as prompt sees the correct value of $? and changes color based on it,
		so user doesn't really need to access $? from prompt (and it works as expected in scripts)
#>
function global:Out-Default {
	param(
			[switch]
		$Transcript,
			[Parameter(ValueFromPipeline)]
			[PSObject]
		$InputObject
	)

	begin {
		$ScriptCmd = { & 'Microsoft.PowerShell.Core\Out-Default' @PSBoundParameters }
		$SteppablePipeline = $scriptCmd.GetSteppablePipeline($myInvocation.CommandOrigin)
		$SteppablePipeline.Begin($PSCmdlet)
	}

	process {
		$SteppablePipeline.Process($_)
		if ($null -ne $_) {
			$script:_LastCmdOutputTypes += $_.GetType()
		}
	}

	end {
		$SteppablePipeline.End()
	}
}
