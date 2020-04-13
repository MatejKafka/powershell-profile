param(
		[Parameter(Mandatory)]
		[DateTime]
	$ProfileStartTime
)

$SCRIPT_DIR = Split-Path -parent $MyInvocation.MyCommand.Path
Import-Module $CONFIG_DIR/modules/Format-TimeSpan



# RGB colors for Write-Host
Import-Module Pansies


# autocomplete should offer all options, not fill in the first one
Set-PSReadlineKeyHandler -Key Tab -Function MenuComplete


# written by our overriden version of Out-Default
$global:_LastCmdOutputTypes = @()
# without setting this, drawing prompt would fail
$global:LastExitCode = 0
# otherwise python venv would break our fancy Prompt
$Env:VIRTUAL_ENV_DISABLE_PROMPT = $true


Function global:Prompt {
	$errOcurred = -not ($? -and ($global:LastExitCode -eq 0))
	if ($errOcurred) {
		$color = [PoshCode.Pansies.RgbColor]"#906060"
		$cwdColor = [PoshCode.Pansies.RgbColor]"#C99999"
	} else {
		$color = [PoshCode.Pansies.RgbColor]"#666696"
		$cwdColor = [PoshCode.Pansies.RgbColor]"#9999C9"
	}

	if ($Host.UI.RawUI.CursorPosition.Y -eq 0) {
		# screen was cleared, create offset for our prompt
		Write-Host ""
	}

	Write-Host "╦" -NoNewLine -ForegroundColor $color
	Write-Host ("═" * ($Host.UI.RawUI.WindowSize.Width - 2)) -NoNewLine -ForegroundColor $color
	Write-Host "╩" -ForegroundColor $color

	Write-Host "╚╣ " -NoNewLine -ForegroundColor $color
	# show if we're running with active python venv
	if ($null -ne $env:VIRTUAL_ENV) {
		Write-Host "(venv) " -NoNewLine -ForegroundColor $color
	}
	Write-Host ([string](Get-Location) + ">") -NoNewLine -ForegroundColor $cwdColor
	
	
	# status string indicating outcome of previous command
	$statusStr = ""

	# render output type of previous command, unless it resulted in an error
	if ($global:_LastCmdOutputTypes.Length -gt 0 -and -not $errOcurred) {
		if ($global:_LastCmdOutputTypes.Length -gt 1) {
			$statusStr += "[" + $global:_LastCmdOutputTypes.Length + "] "
		}
		$statusStr += $global:_LastCmdOutputTypes[0].ToString() + " | "
	}

	# print exit code if error occurred
	if ($errOcurred) {
		if ($global:LastExitCode -eq -1073741510) {
			$statusStr += "Ctrl-C | "
		} else {
			$statusStr += [string]$global:LastExitCode + " | "
		}
	}
	
	# print run time of last command, or startup time if this is the first time we're rendering prompt
	if ($null -ne (Get-History -Count 1)) {
		$lastCmd = Get-History -Count 1
		$executionTime = $lastCmd.EndExecutionTime - $lastCmd.StartExecutionTime
		$statusStr += Format-TimeSpan $executionTime
	} else {
		# we just started up, display startup time
		$statusStr += "startup: "
		$statusStr += Format-TimeSpan ((Get-Date) - (Get-Process -Id $pid).StartTime)
		$statusStr += " (profile: " + (Format-TimeSpan ((Get-Date) - $global:_ProfileStartTime)) + ")"
	}
	
	# render status
	_Write-HostLineEnd ($statusStr + " ╠╗") $color -dy -2

	# reset exit code
	$global:LastExitCode = 0
	# reset last output types
	$global:_LastCmdOutputTypes = @()
	return " "
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