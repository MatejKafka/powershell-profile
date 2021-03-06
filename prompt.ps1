#Requires -Modules Format-TimeSpan, Write-HostLineEnd, Pansies, posh-git
param(
		[Parameter(Mandatory)]
		[HashTable]
	$Times
)


Set-PSReadLineKeyHandler -Key Shift+UpArrow -Function HistorySearchBackward
Set-PSReadLineKeyHandler -Key Shift+DownArrow -Function HistorySearchForward
Set-PSReadLineOption -HistorySearchCursorMovesToEnd 

# enable fish-like autocompletion
Set-PSReadLineOption -PredictionSource History

# autocomplete should offer all options, not fill in the first one
Set-PSReadLineKeyHandler -Key Tab -Function MenuComplete
# set which part of prompt is highlighted in red for invalid input
Set-PSReadLineOption -PromptText "> "
# inform PSReadLine that our prompt has 2 lines
Set-PSReadLineOption -ExtraPromptLineCount 1


# written by our overriden version of Out-Default
$script:_LastCmdOutputTypes = @()
# without setting this, drawing prompt would fail
$global:LastExitCode = 0
# otherwise python venv would break our fancy Prompt
$Env:VIRTUAL_ENV_DISABLE_PROMPT = $true

$script:FirstPromptTime = $null


Function Get-LastCommandStatus {
	param(
			[Parameter(Mandatory)]
			[boolean]
		$ErrorOccurred,
			[Parameter(Mandatory)]
			[int]
		$LastExitCode
	)

	# status string indicating outcome of previous command
	$StatusStr = ""

	# render output type of previous command, unless it resulted in an error
	if ($script:_LastCmdOutputTypes.Length -gt 0 -and -not $ErrorOccurred) {
		if ($script:_LastCmdOutputTypes.Length -gt 1) {
			$StatusStr += "[" + $script:_LastCmdOutputTypes.Length + "]"
		}
		$StatusStr += $script:_LastCmdOutputTypes[0].ToString() + " | "
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


$script:LastCmdId = $null

Function global:Prompt {
	$ErrorOccurred = -not ($? -and ($global:LastExitCode -eq 0))
	if ($ErrorOccurred) {
		$Color = [PoshCode.Pansies.RgbColor]"#906060"
		$CwdColor = [PoshCode.Pansies.RgbColor]"#C99999"
	} else {
		$Color = [PoshCode.Pansies.RgbColor]"#666696"
		$CwdColor = [PoshCode.Pansies.RgbColor]"#9999C9"
	}

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
		Get-LastCommandStatus $ErrorOccurred $global:LastExitCode
	} else {
		"" # should be empty, as sometimes we rerender prompt in same place, which should keep previous time
	}
	Write-HostLineEnd ($StatusStr + " ╠╗") $Color -dy -1
	
	
	# write horizontal separator
	Write-Host ("╦" + "═" * ($Host.UI.RawUI.WindowSize.Width - 2) + "╩") -ForegroundColor $Color
	Write-Host  "╚╣ " -NoNewLine -ForegroundColor $Color
	
	if (Test-Path -Type Container .) {
		# show if we're running with active python venv
		if ($null -ne $env:VIRTUAL_ENV) {
			Write-Host "(venv) " -NoNewLine -ForegroundColor $Color
		}
		
		# show if we're inside a git repository
		$GitDir = Get-GitDirectory
		if ($GitDir) {
			$GitStr = try {
				$RefStr = cat (Join-Path $GitDir "./HEAD")
				# "ref: refs/heads/".Length
				$BranchName = $RefStr.Substring(16)
				"(git:" + $BranchName + ")"
			} catch {"(git)"}
			Write-Host ($GitStr + " ") -NoNewLine -ForegroundColor $Color
		}
	} else {
		Write-Host "(X) " -NoNewLine -ForegroundColor "Red"
	}
	
	# write prompt itself
	Write-Host ([string](Get-Location)) -NoNewLine -ForegroundColor $CwdColor
	
	# reset exit code
	$global:LastExitCode = 0
	# reset last output types
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