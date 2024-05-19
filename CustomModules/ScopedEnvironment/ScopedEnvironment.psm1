Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"


function Invoke-WithEnvironment {
	if (-not $Args) {
		return ls Env:
	}

	# parse arguments
	$NewEnv = @{}
	$CommandArgs = @()
	$ParsingEnv = $true
	foreach ($Arg in $Args) {
		if ($ParsingEnv) {
			# FIXME: is this pattern ok?
			if ($Arg -match '(^[^ ^=]+)=(.*)$') {
				$NewEnv[$Matches[1]] = $Matches[2]
			} else {
				$ParsingEnv = $false
				$Command = $Arg
			}
		} else {
			$CommandArgs += $Arg
		}
	}

	if ($ParsingEnv) {
		throw "No command passed."
	}

	$OrigEnv = ls Env:
	try {
		# set new environment
		foreach ($e in $NewEnv.GetEnumerator()) {
			$null = New-Item "Env:$($e.Name)" -Value $e.Value -Force
		}
		# for some reason, splatting everything (even the command) doesn't work
		& $Command @CommandArgs
	} finally {
		# revert back to the old environment
		# remove extra variables
		ls Env: | ? Name -notin $OrigEnv.Name | % {Remove-Item "Env:$($_.Name)"}
		# reset values of existing variables
		foreach ($e in $OrigEnv) {
			$null = New-Item "Env:$($e.Name)" -Value $e.Value -Force
		}
	}
}

New-Alias env Invoke-WithEnvironment
