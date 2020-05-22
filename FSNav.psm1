# hacked together, needs rewrite

$rui = $Host.UI.RawUI

function PadLine {
	param($str, [switch]$NoNewLine, $ForegroundColor)
	
	$cursorX = $rui.CursorPosition.X
	Write-Host ($str + " " * ($Host.UI.RawUI.WindowSize.Width - $str.Length - $cursorX)) `
		-NoNewLine:$NoNewLine -ForegroundColor $ForegroundColor
}


function Get-MatchingDirectories {
	param([Parameter(Mandatory)]$prefix)
	
	return ls -Directory -Filter ($prefix + "*") | select -ExpandProperty Name
}


Set-PSReadLineKeyHandler -Key "Ctrl+UpArrow" -ScriptBlock {
	cd ..
	[Microsoft.PowerShell.PSConsoleReadLine]::InvokePrompt()
}


function PrintDirectoryList($baseCursor, $dir, $prevCount) {
	$printCursor = $baseCursor
	$printCursor.X = 0
	$printCursor.Y += 1
	$rui.CursorPosition = $printCursor

	$CurrentHeight = 0
	$matching = Get-MatchingDirectories $dir

	if (@($matching).Count -eq 0) {
		Write-Host -NoNewLine -ForegroundColor "#666696" (" ╠" + "⸨ ")
		PadLine "NO DIRECTORIES" -ForegroundColor "#C99999"
		$CurrentHeight = 1
	} else {
		$matching | % {
			Write-Host -NoNewLine -ForegroundColor "#666696" (" ╠" + "⸨ ")
			PadLine $_ -ForegroundColor "#9999C9"
		}
		$CurrentHeight = @($matching).Count
	}
	
	if ($CurrentHeight -lt $LastHeight) {
		foreach ($i in $CurrentHeight..$LastHeight) {
			PadLine ""
		}
	}

	return $CurrentHeight
}

function PrintCurrentInput($baseCursor, $buffer) {
	$sc = $baseCursor
	$sc.X -= 2
	$rui.CursorPosition = $sc
	
	PadLine -NoNewLine ("⸨ " + $buffer)

	$c = $baseCursor
	$c.X += $buffer.Length
	$rui.CursorPosition = $c
}

function CompleteNext($buffer) {
	# complete to nearest different char
	$items = Get-MatchingDirectories $buffer
	if (@($items).Count -eq 0) {
		return ""
	}
	$base = @($items)[0].ToLower()
	$items | % {
		while (-not $_.ToLower().StartsWith($base)) {
			$base = $base.Substring(0, $base.Length - 1)
		}
	}
	return $base
}

function DeleteNext($buffer) {
	if ($buffer -eq "") {
		return ""
	}
	$c = @(Get-MatchingDirectories $buffer).Count
	if ($c -eq 0) {
		return ""
	}
	
	do {
		$buffer = $buffer.Substring(0, $buffer.Length - 1)
	} while (@(Get-MatchingDirectories $buffer).Count -eq $c)
	return $buffer
}

Set-PSReadLineKeyHandler -Key "Ctrl+d" -ScriptBlock {
	$baseCursor = $rui.CursorPosition
	
	$buffer = ""
	$LastHeight = 0
	while ($true) {
		if ($buffer -ne "") {
			$buffer = CompleteNext $buffer
		}
		
		if (Test-Path -PathType Container $buffer) {
			cd $buffer
			$rui.CursorPosition = $baseCursor
			Write-Host -NoNewLine (" " * $buffer.Length)
			$buffer = ""
			[Microsoft.PowerShell.PSConsoleReadLine]::InvokePrompt()
			$baseCursor = $rui.CursorPosition
			continue
		}
		
		[Console]::CursorVisible = $false
		$LastHeight = PrintDirectoryList $baseCursor $buffer $LastHeight
		PrintCurrentInput $baseCursor $buffer
		[Console]::CursorVisible = $true
	
		$key = $rui.ReadKey("AllowCtrlC,IncludeKeyDown")
		
		# Escape or Ctrl-C
		if ($key.VirtualKeyCode -eq 27 -or ($key.VirtualKeyCode -eq 67 -and $key.ControlKeyState -eq 8)) {
			break
		}
		
		# Backspace
		if ($key.VirtualKeyCode -eq 8) {
			$buffer = DeleteNext $buffer
			continue
		}
		
		# Up arrow
		if ($key.VirtualKeyCode -eq 38) {
			cd ..
			$buffer = ""
			[Microsoft.PowerShell.PSConsoleReadLine]::InvokePrompt()
			$baseCursor = $rui.CursorPosition
			continue
		}
		
		if ($key.Character -ge 32 -and $key.Character -lt 127) {
			$matching = Get-MatchingDirectories ($buffer + $key.Character)
			if (@($matching).Count -gt 0) {
				$buffer += $key.Character
			}
		}
	}
	
	foreach ($i in 0..$LastHeight) {
		$x = $rui.CursorPosition
		# weird hack, dunno why spaces don't work
		PadLine ">" -NoNewLine
		$rui.CursorPosition = $x
		Write-Host " "
	}
	[Microsoft.PowerShell.PSConsoleReadLine]::InvokePrompt()
}

# don't export anything
Export-ModuleMember