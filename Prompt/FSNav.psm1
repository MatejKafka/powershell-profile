Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"
Export-ModuleMember # don't export anything

Import-Module $PSScriptRoot\Colors

# hacked together, needs rewrite


$IGNORED_DIRECTORIES = @("`$RECYCLE.BIN", "System Volume Information")


Set-PSReadLineKeyHandler -Key "Ctrl+UpArrow" -ScriptBlock {
	cd ..
	[Microsoft.PowerShell.PSConsoleReadLine]::InvokePrompt()
}


$rui = $Host.UI.RawUI

New-Alias color Get-ColorEscapeSequence
$Reset = $PSStyle.Reset
function padding($TextLength) {
	return " " * ($rui.WindowSize.Width - $TextLength) + "`n"
}

$script:MaxListCount = 20

function PrintItemList($baseCursor, $matching, $searchBuffer) {
	$BaseColor = $UIColors.Prompt.Ok.Base
	$TextColor = $UIColors.Prompt.Ok.Highlight
	$ErrorTextColor = $UIColors.Prompt.Error.Highlight

	$rui.CursorPosition = $baseCursor
	$CurrentHeight = 0
	$bufferLength = $searchBuffer.Length
	
	$s = "`n"

	if ($null -eq $matching) {
		$s += (color Foreground $BaseColor) + " ╚⸨ "
		$s += (color Foreground $ErrorTextColor) + "NO DIRECTORIES" + $Reset
		$s += padding 18
		$CurrentHeight += 1
	} else {
		foreach ($_ in $matching | select -First $script:MaxListCount) {
			$s += (color Foreground $BaseColor) + " ╠⸨ " + $Reset
			$s += (color Background $BaseColor) + $_.Substring(0, $bufferLength) + $Reset
			$s += (color Foreground $TextColor) + $_.Substring($bufferLength) + $Reset
			$s += padding (4 + $_.Length)
			$CurrentHeight += 1
		}
		if (@($matching).Count -gt $script:MaxListCount) {
			$countStr = " ╚⸨ ... (+$($matching.Count - $script:MaxListCount))"
			$s += (color Foreground $BaseColor) + $countStr + $Reset
			$s += padding $countStr.Length
			$Host.UI.Write($s.Substring(0, $s.Length - 1))
			return
		}
	}
	
	$s += (padding 0) * ($script:MaxListCount - $CurrentHeight + 1)
	$Host.UI.Write($s.Substring(0, $s.Length - 1))
}

function PrintCurrentInput($baseCursor, $buffer) {
	$sc = $baseCursor
	$sc.X -= 2
	$rui.CursorPosition = $sc
	
	$Host.UI.Write("⸨ " + $buffer + (padding ($sc.X + 2 + $buffer.Length)))

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
	if (-not $items) {
		return ""
	}
	
	$origCount = @(GetMatching $buffer $items).Count
	do {
		$buffer = $buffer.Substring(0, $buffer.Length - 1)
	} while (@(GetMatching $buffer $items).Count -eq $origCount)
	
	return $buffer
}

function GetAvailableItems {
	# some locations, like Registry don't have directories and Get-ChildItem reflects that in its params
	$dirs = if ((Get-Command Get-ChildItem).Parameters.ContainsKey("Directory")) {
		Get-ChildItem -Name -Force -Directory
		ls -File -Filter "./*.lnk" | Select-Object -ExpandProperty Name
	} else {
		Get-ChildItem -Name -Force
	}
	return $dirs | where {$_ -notin $IGNORED_DIRECTORIES}
}

function SelectItem($Item) {
	if (Test-Path -Type Container $Item) {
		# use -LiteralPath, otherwise "+" and "-" have specific handling
		cd -LiteralPath $Item
	} else {
		$Lnk = (New-Object -ComObject WScript.Shell).CreateShortcut((Resolve-Path $Item))
		cd -LiteralPath $Lnk.TargetPath
	}
}

function GetMatching($prefix, $strings) {
	$strings | where {$_ -like ($prefix + "*")} # StartsWith is case-sensitive, we don't want that
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
	$MaxLines = $script:MaxListCount + 1
	$y = $script:baseCursor.Y + $MaxLines
	if ($y -ge $rui.BufferSize.Height) {
		# create space for list
		$Host.UI.Write("`n" * $MaxLines)
		$script:baseCursor.Y = $rui.BufferSize.Height - $MaxLines - 1
		# -1 for y to compensate multiline prompt
		[Microsoft.PowerShell.PSConsoleReadLine]::InvokePrompt($null, $script:baseCursor.Y - 1)
	}
	
	while ($true) {
		$dirs = GetAvailableItems
		$matching = GetMatching $script:buffer $dirs
	
		if ($script:buffer -ne "") {
			$script:buffer = CompleteNext $script:buffer $matching
			$matching = GetMatching $script:buffer $dirs
		}
		
		if ($script:buffer -in $matching -and @($matching).Count -eq 1) {
			# we have single exact match
			SelectItem $matching
			Refresh
			continue
		}
		
		[Console]::CursorVisible = $false
		PrintItemList $script:baseCursor $matching $script:buffer
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
				SelectItem ($matching -eq $script:buffer)[0]
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
			cd C:
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
			if (@(GetMatching ($script:buffer + $key.Character) $dirs).Count -gt 0) {
				$script:buffer += $key.Character
			}
		}
	}
	
	# clear the list entries
	# it seems that writing whitespace-only is for some reason ignored, so we write '>', which gets overwritten by the refreshed prompt
	$s = ">`n" + (padding 0) * $MaxLines
	$Host.UI.Write($s.Substring(0, $s.Length - 1))
	
	[Microsoft.PowerShell.PSConsoleReadLine]::AddToHistory("cd '$(pwd)'")
	[Microsoft.PowerShell.PSConsoleReadLine]::InvokePrompt()
}

# don't export anything
Export-ModuleMember
