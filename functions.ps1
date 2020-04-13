function Wait-FileChange {
	[OutputType([Boolean])]
	Param(
			[Parameter(Mandatory)]
			[IO.FileInfo]
		$Path,
			[ScriptBlock]
		$periodicCb
	)

	$watcher = New-Object System.IO.FileSystemWatcher
	$watcher.Path = Split-Path $Path -Parent
	$watcher.IncludeSubdirectories = $false
	$watcher.EnableRaisingEvents = $false
	$watcher.Filter = Split-Path $Path -Leaf

	while ($true) {
		# short timeout to remain responsive to Ctrl-C
		$result = $watcher.WaitForChanged(
			[System.IO.WatcherChangeTypes]::Changed -bor
			[System.IO.WatcherChangeTypes]::Renamed -bOr
			[System.IO.WatcherChangeTypes]::Created, 100)
		if(-not $result.TimedOut){
			return $true
		}
		if (. $periodicCb) {
			return $false
		}
	}
}


Function npp {
	Param(
			[Parameter(ValueFromPipeline)]
			[IO.FileInfo]
		$Path,
			[switch]
		$NonModal
	)
	
	if ($nonModal) {
		# start in a normal window
		& "D:\config\winShortcuts-programs\Notepad++.lnk" (Resolve-Path $Path)
		return
	}
	
	# call directly the exe to pass -multiInst and -nosession
	# this allows us to open separate window in case some tabs are already open
	$nppProc = [Diagnostics.Process]::Start(
		"D:\_programs\programs\notepad++\notepad++.exe",
		@("-multiInst", "-nosession", (Resolve-Path $Path)))
	
	#$nppProc | Wait-Process
	
	# hide output with dummy variable
	$_ = Wait-FileChange $Path {$nppProc.HasExited}
	Stop-Process $nppProc
}


$global:_LastTmpFile = $null
Function /($continueLast) {
	if ($continueLast) {
		if ($null -eq $global:_LastTmpFile) {
			throw "There is no previous editing session."
		}
		$temp = $global:_LastTmpFile
	} else {
		$temp = New-TemporaryFile |
			Rename-Item -PassThru -NewName {[IO.Path]::ChangeExtension($_.Name, "ps1")}
		$global:_LastTmpFile = $temp
	}
	Write-Host $temp
	npp $temp
	
	Get-Content $temp | % {">> " + $_.Replace("`n", "`n>> ")} | Write-Host -ForegroundColor Green
	. $temp
}


Function // {
	/ $true
}


Function Activate-Venv {
	.\venv\Scripts\Activate.ps1
}


Function mktxt($filename) {
	New-Item $filename
	npp $filename
}


Function Get-ConHostCommands {
	Get-WinEvent Security |
		? id -eq 4688 |
		? { $_.Properties[5].Value -match 'conhost' } |
		Select TimeCreated,@{ Label = "ParentProcess"; Expression = { $_.Properties[13].Value } }
}


#Function Pause {
#	Write-Host -NoNewLine 'Press any key to continue...'
#	$null = $Host.UI.RawUI.ReadKey('NoEcho,IncludeKeyDown')
#}


Function Update-PowerShell {
	# fix to spawn new powershell window
	Invoke-Expression "& { $(Invoke-RestMethod https://aka.ms/install-powershell.ps1) } -UseMSI -Preview"
}


Function _Format-TimeSpan([TimeSpan]$timeSpan) {
	if ($timeSpan.TotalHours -ge 24) {
		return $timeSpan.ToString("c")
	} elseif ($timeSpan.TotalMinutes -ge 5) {
		return $timeSpan.ToString("hh\:mm\:ss")
	} elseif ($timeSpan.TotalSeconds -ge 10) {
		$time = [math]::Round($timeSpan.TotalSeconds, 1)
		return [string]$time + " s"
	} else {
		$time = [math]::Round($timeSpan.TotalMilliseconds, 2)
		return [string]$time + " ms"
	}
}


Function Get-CmdExecutionTime($index=-1) {
	$cmd = (Get-History)[$index]
	$executionTime = $cmd.EndExecutionTime - $cmd.StartExecutionTime
	return (_Format-TimeSpan $executionTime)
}


Function _Write-HostLineEnd($message, $foregroundColor, $dy = 0) {
	$origCursor = $Host.UI.RawUI.CursorPosition

	$targetCursor = $Host.UI.RawUI.CursorPosition
	$targetCursor.X = $Host.UI.RawUI.WindowSize.Width - $message.Length
	$targetCursor.Y += $dy

	$Host.UI.RawUI.CursorPosition = $targetCursor
	Write-Host $message -NoNewLine -ForegroundColor $foregroundColor

	$Host.UI.RawUI.CursorPosition = $origCursor
}