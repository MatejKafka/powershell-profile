#Requires -Modules Format-TimeSpan

function Start-Stopwatch {
	try {
		[Console]::CursorVisible = $false
		$rui = $Host.UI.RawUI
		$Cursor = $rui.CursorPosition
		$SecondsCounter = 0
		while ($true) {
			$rui.CursorPosition = $Cursor
			Write-Host "$SecondsCounter seconds"
			# quick & dirty & inaccurate
			$SecondsCounter++
			Sleep 1
		}
	} finally {
		[Console]::CursorVisible = $true
	}
}