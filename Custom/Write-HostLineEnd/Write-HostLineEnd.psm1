Function Write-HostLineEnd($message, $foregroundColor, $dy = 0) {
	$origCursor = $Host.UI.RawUI.CursorPosition

	$targetCursor = $Host.UI.RawUI.CursorPosition
	$targetCursor.X = $Host.UI.RawUI.WindowSize.Width - $message.Length
	$targetCursor.Y += $dy

	$Host.UI.RawUI.CursorPosition = $targetCursor
	Write-Host $message -NoNewLine -ForegroundColor $foregroundColor

	$Host.UI.RawUI.CursorPosition = $origCursor
}