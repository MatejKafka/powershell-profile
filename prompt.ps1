param(
		[Parameter(Mandatory)]
		[HashTable]
	$Times
)

. $PSScriptRoot\PSReadLineOptions.ps1

# written by our overriden version of Out-Default
$script:_LastCmdOutputTypes = @()
# without setting this, drawing prompt would fail
$global:LastExitCode = 0
# otherwise python venv would break our fancy Prompt
$Env:VIRTUAL_ENV_DISABLE_PROMPT = $true

$script:FirstPromptTime = $null


$PromptColors = @{
	Error = @{
		Color = [PoshCode.Pansies.RgbColor]"#906060"
		CwdColor = [PoshCode.Pansies.RgbColor]"#C99999"
	}
	Ok = @{
		Color = [PoshCode.Pansies.RgbColor]"#666696"
		CwdColor = [PoshCode.Pansies.RgbColor]"#9999C9"
	}
}


Function Get-LastCommandStatus {
	param(
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
		if ($LastCmdOutputTypes.Length -gt 1) {
			$StatusStr += "[" + $LastCmdOutputTypes.Length + "]"
		}
		$StatusStr += $LastCmdOutputTypes[0].ToString() + " | "
	}

	# print exit code if error occurred
	if ($ErrorOccurred) {
		if ($LastExitCode -eq -1073741510) {
			$StatusStr += "Ctrl-C | "
		} elseif ($LastExitCode -eq 0) {
			# error originates from powershell
			$StatusStr += "Error | "
		} else {
			# error from external command
			$StatusStr += [string]$LastExitCode + " | "
		}
	}

	# print run time of last command, or startup time if this is the first time we're rendering prompt
	$LastCmd = Get-History -Count 1
	if ($null -ne $LastCmd) {
		$ExecutionTime = $LastCmd.EndExecutionTime - $LastCmd.StartExecutionTime
		$StatusStr += Format-TimeSpan $ExecutionTime
	} else {
		# we just started up, display startup time
		if ($script:FirstPromptTime -eq $null) {
			$script:FirstPromptTime = Get-Date
			$Times.prompt = $script:FirstPromptTime
		}

		$LoadStartTime = (Get-Process -Id $pid).StartTime
		$StartupTime = $script:FirstPromptTime - $LoadStartTime
		$StatusStr += "startup: " + (Format-TimeSpan $StartupTime)

		$Sorted = ,@{Name = $null; Value = $LoadStartTime}
		$Sorted += $Times.GetEnumerator() | sort -Property Value
		$TimeStrings = @()
		for ($i = 1; $i -lt $Sorted.Count; $i += 1) {
			$_ = $Sorted[$i]
			$TimeStrings += $_.Name + ": " + (Format-TimeSpan ($_.Value - $Sorted[$i - 1].Value))
		}

		$StatusStr += " (" +  ($TimeStrings -join ", ") + ")"
	}

	return $StatusStr
}


Function Write-ShellStatus($InfoColor) {
	function Write-InfoStatus($Status) {
		Write-Host "($Status)" -NoNewLine -ForegroundColor $InfoColor
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
		Write-Host "(X)" -NoNewLine -ForegroundColor "Red"
	}
}


$script:LastCmdId = $null

Function global:Prompt {
	$ErrorOccurred = -not ($? -and ($global:LastExitCode -eq 0))

	$Colors = $ErrorOccurred ? $PromptColors.Error : $PromptColors.Ok
	$Color = $Colors.Color
	$CwdColor = $Colors.CwdColor

	if ($Host.UI.RawUI.CursorPosition.Y -eq 0) {
		# screen was cleared, create offset for our prompt
		Write-Host ""
	}


	$LastCmd = Get-History -Count 1
	$StatusStr = if (($LastCmd -eq $null) -or ($LastCmd.Id -ne $script:LastCmdID)) {
		if ($LastCmd -ne $null) {
			$script:LastCmdId = $LastCmd.Id
		}
		# render previous command status
		Get-LastCommandStatus $ErrorOccurred $global:LastExitCode $script:_LastCmdOutputTypes
	} else {
		"" # should be empty, as sometimes we rerender prompt in same place, which should keep previous time
	}
	Write-HostLineEnd ($StatusStr + " ╠╗") $Color -dy -1


	# write horizontal separator
	Write-Host ("╦" + "═" * ($Host.UI.RawUI.WindowSize.Width - 2) + "╩") -ForegroundColor $Color
	Write-Host  "╚╣" -NoNewLine -ForegroundColor $Color
	Write-ShellStatus $Color
	Write-Host -NoNewLine " "

	$CwdString = [string](Get-Location)
	
	# write the prompt itself
	Write-Host $CwdString -NoNewLine -ForegroundColor $CwdColor

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
	This override allows us to capture types of all output objects and display them in prompt.

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

		[Parameter(ValueFromPipeline = $true)]
		[PSObject]
		$InputObject
	)

	begin {
		$scriptCmd = { & 'Microsoft.PowerShell.Core\Out-Default' @PSBoundParameters }
		$steppablePipeline = $scriptCmd.GetSteppablePipeline($myInvocation.CommandOrigin)
		$steppablePipeline.Begin($PSCmdlet)
	}

	process {
		$steppablePipeline.Process($_)
		if ($null -ne $_) {
			$script:_LastCmdOutputTypes += $_.GetType()
		}
	}

	end {
		$steppablePipeline.End()
	}
}
