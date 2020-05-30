# Require -Modules Count

Set-StrictMode -Version Latest

# hacked together, needs rewrite


$IGNORED_DIRECTORIES = @("`$RECYCLE.BIN", "System Volume Information")


Set-PSReadLineKeyHandler -Key "Ctrl+UpArrow" -ScriptBlock {
	cd ..
	[Microsoft.PowerShell.PSConsoleReadLine]::InvokePrompt()
}


$rui = $Host.UI.RawUI

function PadLine {
	param($str, [switch]$NoNewLine, $ForegroundColor)
	
	$cursorX = $rui.CursorPosition.X
	Write-Host ($str + " " * ($Host.UI.RawUI.WindowSize.Width - $str.Length - $cursorX)) `
		-NoNewLine:$NoNewLine -ForegroundColor $ForegroundColor
}

$script:MaxListCount = 20

function PrintDirectoryList($baseCursor, $matching) {
	$rui.CursorPosition = $baseCursor
	$CurrentHeight = 0
	
	Write-Host ""

	if ($null -eq $matching) {
		Write-Host -NoNewLine -ForegroundColor "#666696" (" ╚⸨ ")
		PadLine "NO DIRECTORIES" -ForegroundColor "#C99999"
		$CurrentHeight += 1
	} else {
		$matching | select -First $script:MaxListCount | % {
			Write-Host -NoNewLine -ForegroundColor "#666696" (" ╠⸨ ")
			PadLine $_ -ForegroundColor "#9999C9"
			$CurrentHeight += 1
		}
		if ((count $matching) -gt $script:MaxListCount) {
			PadLine -ForegroundColor "#666696" (" ╚⸨ " + "... (+$($matching.Count - $script:MaxListCount))")
			return
		}
	}
	
	foreach ($i in $CurrentHeight..($script:MaxListCount)) {
		PadLine ""
	}	
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

function CompleteNext($buffer, $items) {
	# complete to nearest different char
	if ($null -eq $items) {
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

function DeleteNext($buffer, $items) {
	if ($buffer -eq "") {
		return ""
	}
	if ((count $items) -eq 0) {
		return ""
	}
	
	$origCount = count (GetMatching $buffer $items)
	do {
		$buffer = $buffer.Substring(0, $buffer.Length - 1)
	} while ((count (GetMatching $buffer $items)) -eq $origCount)
	
	return $buffer
}

function GetDirectories {
	# some locations, like Registry don't have directories and Get-ChildItem reflects that in its params
	$dirs = if ((Get-Command Get-ChildItem).Parameters.ContainsKey("Directory")) {
		Get-ChildItem -Name -Force -Directory
	} else {
		Get-ChildItem -Name -Force
	}
	return $dirs | where {$_ -notin $IGNORED_DIRECTORIES}
}

function GetMatching($prefix, $strings) {
	$strings | where {$_ -like ($prefix + "*")}
}

$script:baseCursor = $null
$script:buffer = $null
Set-PSReadLineKeyHandler -Key "Ctrl+d" -ScriptBlock {
	$script:buffer = ""
	$script:baseCursor = $rui.CursorPosition
	
	function Refresh {
		$script:buffer = ""
		[Microsoft.PowerShell.PSConsoleReadLine]::InvokePrompt()
		$script:baseCursor = $rui.CursorPosition	
	}
	
	# create space for list
	$MaxLines = $script:MaxListCount + 2
	$y = $script:baseCursor.Y + $MaxLines
	if ($y -ge $rui.BufferSize.Height) {
		foreach ($i in 1..$MaxLines) {
			Write-Host ""
		}
		$script:baseCursor.Y = $rui.BufferSize.Height - $MaxLines - 1
		# -1 for y to compensate multiline prompt
		[Microsoft.PowerShell.PSConsoleReadLine]::InvokePrompt($null, $script:baseCursor.Y - 1)
	}
	
	while ($true) {
		$dirs = GetDirectories
		$matching = GetMatching $script:buffer $dirs
	
		if ($script:buffer -ne "") {
			$script:buffer = CompleteNext $script:buffer $matching
			$matching = GetMatching $script:buffer $dirs
		}
		
		if ($script:buffer -in $matching -and (count $matching) -eq 1) {
			# we have single exact match
			cd $matching
			Refresh
			continue
		}
		
		[Console]::CursorVisible = $false
		PrintDirectoryList $script:baseCursor $matching
		PrintCurrentInput $script:baseCursor $script:buffer
		[Console]::CursorVisible = $true
	
		$key = $rui.ReadKey("AllowCtrlC,IncludeKeyDown")
		
		# Escape or Ctrl-C
		if ($key.VirtualKeyCode -eq 27 -or ($key.VirtualKeyCode -eq 67 -and $key.ControlKeyState -eq 8)) {
			break
		}
		
		# Backspace
		if ($key.VirtualKeyCode -eq 8) {
			$script:buffer = DeleteNext $script:buffer $dirs
			continue
		}
		
		# Enter
		if ($key.VirtualKeyCode -eq 13) {
			if ($script:buffer -in $matching) {
				# we have exact match
				# do not use buffer directly, as it's probably lowercase
				cd ($matching -eq $script:buffer)[0]
				Refresh
				continue
			}	
		}
		
		# Up arrow
		if ($key.VirtualKeyCode -eq 38) {
			cd ..
			Refresh
			continue
		}
		
		# Left arrow
		if ($key.VirtualKeyCode -eq 37) {
			C:
			Refresh
			continue
		}

		# Right arrow
		if ($key.VirtualKeyCode -eq 39) {
			cd D:
			Refresh
			continue
		}
		
		# Down arrow
		if ($key.VirtualKeyCode -eq 40) {
			cd HKCU:
			Refresh
			continue
		}
		
		if ($key.Character -ge 32 -and $key.Character -lt 127) {
			# only complete if it matches some dir
			if ((count (GetMatching ($script:buffer + $key.Character) $dirs)) -gt 0) {
				$script:buffer += $key.Character
			}
		}
	}
	
	foreach ($i in 1..($script:MaxListCount + 2)) {
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