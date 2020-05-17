# hacked together, needs rewrite


function PadLine {
	param($str, [switch]$NoNewLine, $ForegroundColor)
	
	$rui = $Host.UI.RawUI
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


Set-PSReadLineKeyHandler -Key "Ctrl+d" -ScriptBlock {
	$rui = $Host.UI.RawUI
	$baseCursor = $rui.CursorPosition
	$buffer = ""
	$LastHeight = 0
	while ($true) {
		$origCursor = $rui.CursorPosition
		$targetCursor = $rui.CursorPosition
		$targetCursor.X = 0
		$targetCursor.Y += 1

		$rui.CursorPosition = $targetCursor
		$CurrentHeight = 0
		
		[Console]::CursorVisible = $false
		$matching = Get-MatchingDirectories $buffer
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
		$LastHeight = $CurrentHeight

		$origCursor.X = $baseCursor.X + $buffer.Length
		$rui.CursorPosition = $baseCursor
		$c = $rui.CursorPosition
		$c.X -= 2
		$rui.CursorPosition = $c
		Write-Host -NoNewLine "⸨ "
		Write-Host -NoNewLine ($buffer + " ")
		$rui.CursorPosition = $origCursor
		[Console]::CursorVisible = $true
	
		$key = $rui.ReadKey("AllowCtrlC,IncludeKeyDown")
		
		# Ctrl-C
		if ($key.VirtualKeyCode -eq 67 -and $key.ControlKeyState -eq 8) {
			break
		}
		
		# Backspace
		if ($key.VirtualKeyCode -eq 8) {
			if ($buffer.Length -gt 0) {
				$buffer = $buffer.Substring(0, $buffer.Length - 1)
			}
			continue
		}
		
		# Tab
		if ($key.VirtualKeyCode -eq 9) {
			$items = Get-MatchingDirectories $buffer
			$base = @($items)[0]
			$items | % {
				while (-not $_.StartsWith($base)) {
					$base = $base.Substring(0, $base.Length - 1)
				}
			}
			$buffer = $base
			
			if ($items.Contains($buffer)) {
				cd $buffer
				$rui.CursorPosition = $baseCursor
				Write-Host -NoNewLine (" " * $buffer.Length)
				$buffer = ""
				[Microsoft.PowerShell.PSConsoleReadLine]::InvokePrompt()
				$baseCursor = $rui.CursorPosition			
			}
			continue
		}
		
		# Up arrow
		if ($key.VirtualKeyCode -eq 38) {
			cd ..
			[Microsoft.PowerShell.PSConsoleReadLine]::InvokePrompt()
			$baseCursor = $rui.CursorPosition
			Write-Host -NoNewLine $buffer
			continue
		}
		
		# Enter
		if ($key.VirtualKeyCode -eq 13) {
			if (Test-Path $buffer) {
				cd $buffer
				$rui.CursorPosition = $baseCursor
				Write-Host -NoNewLine (" " * $buffer.Length)
				$buffer = ""
				[Microsoft.PowerShell.PSConsoleReadLine]::InvokePrompt()
				$baseCursor = $rui.CursorPosition
			}
			continue
		}
		
		# Escape
		if ($key.VirtualKeyCode -eq 27) {
			break
		}
		
		if ($key.Character -ge 32 -and $key.Character -lt 127) {
			$matching = Get-MatchingDirectories ($buffer + $key.Character)
			if (@($matching).Count -gt 0) {
				$buffer += $key.Character
				
				if (@($matching).Count -eq 1 -and @($matching)[0] -eq $buffer) {
					# there is an exact match, follow it
					cd $buffer
					$rui.CursorPosition = $baseCursor
					Write-Host -NoNewLine (" " * $buffer.Length)
					$buffer = ""
					[Microsoft.PowerShell.PSConsoleReadLine]::InvokePrompt()
					$baseCursor = $rui.CursorPosition
				}
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