#Requires -Modules Format-TimeSpan, Write-HostLineEnd, Pansies
param(
		[Parameter(Mandatory)]
		[DateTime]
		# should be intialized at the start of $PROFILE using `$ProfileStartTime = Get-Date`
	$ProfileStartTime
)


# autocomplete should offer all options, not fill in the first one
Set-PSReadLineKeyHandler -Key Tab -Function MenuComplete
# set which part of prompt is highlighted in red for invalid input
Set-PSReadLineOption -PromptText "> "
# inform PSReadLine that our prompt has 2 lines
Set-PSReadLineOption -ExtraPromptLineCount 1


# written by our overriden version of Out-Default
$global:_LastCmdOutputTypes = @()
# without setting this, drawing prompt would fail
$global:LastExitCode = 0
# otherwise python venv would break our fancy Prompt
$Env:VIRTUAL_ENV_DISABLE_PROMPT = $true

$script:StartupTime = $null
$script:ProfileTime = $null


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
	if ($global:_LastCmdOutputTypes.Length -gt 0 -and -not $ErrorOccurred) {
		if ($global:_LastCmdOutputTypes.Length -gt 1) {
			$StatusStr += "[" + $global:_LastCmdOutputTypes.Length + "]"
		}
		$StatusStr += $global:_LastCmdOutputTypes[0].ToString() + " | "
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
		if ($script:StartupTime -eq $null) {
			$script:StartupTime = (Get-Date) - (Get-Process -Id $pid).StartTime
			$script:ProfileTime = (Get-Date) - $ProfileStartTime
		}
		$StatusStr += "startup: "
		$StatusStr += Format-TimeSpan $script:StartupTime
		$StatusStr += " (profile: " + (Format-TimeSpan $script:ProfileTime) + ")"
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
		"" # should be empty, as sometimes I rerender prompt in same place, which should keep previous time
	}
	Write-HostLineEnd ($StatusStr + " ╠╗") $Color -dy -1
	
	
	# write horizontal separator
	Write-Host ("╦" + "═" * ($Host.UI.RawUI.WindowSize.Width - 2) + "╩") -ForegroundColor $Color
	Write-Host  "╚╣ " -NoNewLine -ForegroundColor $Color
	
	# show if we're running with active python venv
	if ($null -ne $env:VIRTUAL_ENV) {
		Write-Host "(venv) " -NoNewLine -ForegroundColor $Color
	}
	
	# write prompt itself
	Write-Host ([string](Get-Location)) -NoNewLine -ForegroundColor $CwdColor
	
	# reset exit code
	$global:LastExitCode = 0
	# reset last output types
	$global:_LastCmdOutputTypes = @()
	return "> "
}


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
			$global:_LastCmdOutputTypes += $_.GetType()
		}
	}

	end {
		$steppablePipeline.End()
	}
}