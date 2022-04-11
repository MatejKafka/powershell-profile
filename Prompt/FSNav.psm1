Set-StrictMode -Version Latest

Import-Module $PSScriptRoot\_Colors

# hacked together, needs rewrite


$IGNORED_DIRECTORIES = @("`$RECYCLE.BIN", "System Volume Information")


Set-PSReadLineKeyHandler -Key "Ctrl+UpArrow" -ScriptBlock {
	cd ..
	[Microsoft.PowerShell.PSConsoleReadLine]::InvokePrompt()
}


$rui = $Host.UI.RawUI

function PadLine {
	param($str, [switch]$NoNewLine, $ForegroundColor, $BackgroundColor)
	
	$cursorX = $rui.CursorPosition.X
	$WHArgs = @{}
	if ($ForegroundColor) {$WHArgs.ForegroundColor = $ForegroundColor}
	if ($BackgroundColor) {$WHArgs.BackgroundColor = $BackgroundColor}
	Write-Host $str -NoNewLine @WHArgs
	Write-Host (" " * ($Host.UI.RawUI.WindowSize.Width - $str.Length - $cursorX)) -NoNewLine:$NoNewLine 
}

$script:MaxListCount = 20

function PrintItemList($baseCursor, $matching, $searchBuffer) {
	$BaseColor = $UIColors.Prompt.Ok.Base
	$TextColor = $UIColors.Prompt.Ok.Highlight
	$ErrorTextColor = $UIColors.Prompt.Error.Highlight

	$rui.CursorPosition = $baseCursor
	$CurrentHeight = 0
	$bufferLength = $searchBuffer.Length
	
	Write-Host ""

	if ($null -eq $matching) {
		Write-Host -NoNewLine -ForegroundColor $BaseColor (" ╚⸨ ")
		PadLine "NO DIRECTORIES" -ForegroundColor $ErrorTextColor
		$CurrentHeight += 1
	} else {
		$matching | select -First $script:MaxListCount | % {
			Write-Host -NoNewLine -ForegroundColor $BaseColor (" ╠⸨ ")
			Write-Host -NoNewLine -BackgroundColor $BaseColor $_.Substring(0, $bufferLength)
			PadLine $_.Substring($bufferLength) -ForegroundColor $TextColor
			$CurrentHeight += 1
		}
		if (@($matching).Count -gt $script:MaxListCount) {
			PadLine -ForegroundColor $BaseColor (" ╚⸨ " + "... (+$($matching.Count - $script:MaxListCount))")
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
	
	foreach ($i in 1..($script:MaxListCount + 2)) {
		$x = $rui.CursorPosition
		# weird hack, dunno why spaces don't work
		PadLine ">" -NoNewLine
		$rui.CursorPosition = $x
		Write-Host " "
	}
	
	[Microsoft.PowerShell.PSConsoleReadLine]::AddToHistory("cd '$(pwd)'")
	[Microsoft.PowerShell.PSConsoleReadLine]::InvokePrompt()
}

# don't export anything
Export-ModuleMember
