#Requires -Modules Wait-FileChange

Function Invoke-Notepad {
	Param(
			[Parameter(ValueFromPipeline, Mandatory)]
		$Path,
			[switch]
		$NonModal
	)

	$File = if (-not (Test-Path -Type Leaf $Path)) {
		$null = Read-Host "Provided path does not exist - press Enter to create it"
		New-Item $Path
	} else {
		Get-Item $Path
	}

	if ($nonModal) {
		# start in a normal window
		& "D:\_\Notepad++\Notepad++.lnk" $File
		return
	}

	# passing -multiInst and -nosession allows us to open
	#  separate window in case some tabs are already open
	$nppProc = Start-Process "D:\_\Notepad++\Notepad++.lnk" -PassThru `
			-ArgumentList @("`"$File`"", "-multiInst", "-nosession", "-notabbar")

	try {
		#$nppProc | Wait-Process
		$null = Wait-FileChange $File {$nppProc.HasExited}
	} finally {
		# short sleep to finish longer writes to the file
		# FIXME: hacky
		sleep 0.1
		Stop-Process $nppProc
	}
}
