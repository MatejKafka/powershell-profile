<# 
	Waits until file pointed to by $Path changes (content change or rename).
	
	Watching restarts every 100 ms (otherwise the function wouldn't be responsive to
	Ctrl-C. On every iteration, $periodicCb is called - if it returns $true, the whole
	function returns, although the file has not changed.
#>
function Wait-FileChange {
	[OutputType([Boolean])]
	Param(
			[Parameter(Mandatory)]
			[ValidateScript({Test-Path $_})]
		$Path,
			[ScriptBlock]
		$periodicCb
	)

	$Path = Resolve-Path $Path
	
	$watcher = New-Object System.IO.FileSystemWatcher
	$watcher.Path = Split-Path $Path -Parent
	$watcher.IncludeSubdirectories = $false
	$watcher.EnableRaisingEvents = $false
	$watcher.Filter = Split-Path $Path -Leaf

	while ($true) {
		# short timeout to remain responsive to Ctrl-C
		$result = $watcher.WaitForChanged(
			[System.IO.WatcherChangeTypes]::Changed -bor
			[System.IO.WatcherChangeTypes]::Renamed, 100)
		if(-not $result.TimedOut){
			return $true
		}
		if (($null -ne $periodicCb) -and (. $periodicCb)) {
			return $false
		}
	}
}