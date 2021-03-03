#Requires -Modules Format-TimeSpan, AsciiArt

function Start-Stopwatch {
	[Console]::CursorVisible = $false
	try {
		Write-HostAsciiArt ""
		$Rui = $Host.UI.RawUI
		$Cursor = $Rui.CursorPosition
		$Cursor.Y -= Get-AsciiArtHeight
		
		$TimerStart = Get-Date
		while ($true) {
			$Rui.CursorPosition = $Cursor
			$ElapsedStr = Format-TimeSpan ((Get-Date) - $TimerStart)
			Write-HostAsciiArt $ElapsedStr -Center
			sleep 0.1
		}
		
		$SecondsCounter = 0
		while ($true) {
			$rui.CursorPosition = $Cursor
			Write-Host -NoNewLine "$SecondsCounter seconds"
			# quick & dirty & inaccurate
			$SecondsCounter++
			Sleep 1
		}
	} finally {
		[Console]::CursorVisible = $true
	}
}