#Requires -Modules Wait-FileChange

$NOTEPAD_PATH = "D:\_\Notepad++\Notepad++.lnk"


Function Invoke-Notepad {
	Param(
			[Parameter(ValueFromPipeline, Mandatory)]
		$Path,
			[switch]
		$NonModal
	)
	
	if (-not (Test-Path -Type Leaf $Path)) {
		Read-Host "Provided path does not exist - press Enter to create it"
		$null = New-Item $Path
	}
	
	$Path = Resolve-Path $Path
	
	if ($nonModal) {
		# start in a normal window
		& $NOTEPAD_PATH $Path
		return
	}
	
	# passing -multiInst and -nosession allows us to open
	#  separate window in case some tabs are already open
	$nppProc = Start-Process -PassThru $NOTEPAD_PATH `
			-ArgumentList @("-multiInst", "-nosession", "-notabbar", $Path)
	
	try {
		#$nppProc | Wait-Process
		$null = Wait-FileChange $Path {$nppProc.HasExited}
	} finally {
		Stop-Process $nppProc
	}
}
