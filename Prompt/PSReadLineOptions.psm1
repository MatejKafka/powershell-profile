using namespace Microsoft.PowerShell

Set-StrictMode -Version Latest
Export-ModuleMember # don't export anything

Set-PSReadLineKeyHandler -Key Shift+UpArrow -Function HistorySearchBackward
Set-PSReadLineKeyHandler -Key Shift+DownArrow -Function HistorySearchForward
Set-PSReadLineKeyHandler -Key Enter -Function ValidateAndAcceptLine

Set-PSReadLineOption -HistorySearchCursorMovesToEnd
# disable default history handler, which filters "sensitive" commands from being written to the history file
#  (see https://github.com/PowerShell/PSReadLine/issues/3243)
Set-PSReadLineOption -AddToHistoryHandler $null

# enable fish-like autocompletion
Set-PSReadLineOption -PredictionSource History

# set which part of prompt is highlighted in red for invalid input
Set-PSReadLineOption -PromptText "> "
# inform PSReadLine that our prompt has 2 lines
Set-PSReadLineOption -ExtraPromptLineCount 1

# increase history file size
Set-PSReadLineOption -MaximumHistoryCount 100000

Set-PSReadLineOption -Colors @{ InlinePrediction = '#555555'}


# if at the beginning of a line, add Tab (4 spaces), otherwise open autocomplete dropdown
Set-PSReadLineKeyHandler -Key "Tab" -ScriptBlock {
	param($key, $arg)

	$line = $null
	$cursor = $null
	[PSConsoleReadLine]::GetBufferState([ref]$line, [ref]$cursor)

	$lineStartI = $line.LastIndexOf("`n", [Math]::max(0, $cursor - 1)) + 1
	if ($line.Substring($lineStartI, $cursor - $lineStartI).Trim() -eq "") {
		[PSConsoleReadLine]::Insert("    ")
	} else {
		[PSConsoleReadLine]::MenuComplete($key, $arg)
	}
}

# if at the beginning of a line, remove all indentation
Set-PSReadLineKeyHandler -Key "Shift+Tab" -ScriptBlock {
	param($key, $arg)

	$line = $null
	$cursor = $null
	[PSConsoleReadLine]::GetBufferState([ref]$line, [ref]$cursor)

	$lineStartI = $line.LastIndexOf("`n", [Math]::max(0, $cursor - 1)) + 1
	if ($line.Substring($lineStartI, $cursor - $lineStartI).Trim() -eq "") {
		[PSConsoleReadLine]::Delete($lineStartI, $cursor - $lineStartI)
	} else {
		[PSConsoleReadLine]::TabCompletePrevious($key, $arg)
	}
}


Set-PSReadLineKeyHandler -Key "End" -ScriptBlock {
    param($key, $arg)

    $line = $null
    $cursor = $null
    [PSConsoleReadLine]::GetBufferState([ref]$line, [ref]$cursor)

    if ($cursor -lt $line.Length) {
        [PSConsoleReadLine]::EndOfLine($key, $arg)
    } else {
        [PSConsoleReadLine]::AcceptSuggestion($key, $arg)
    }
}


Set-PSReadLineKeyHandler -Key RightArrow `
			 -BriefDescription ForwardCharAndAcceptNextSuggestionWord `
			 -LongDescription "Move cursor one character to the right in the current editing line and accept the next word in suggestion when it's at the end of current editing line" `
			 -ScriptBlock {
	param($key, $arg)

	$line = $null
	$cursor = $null
	[PSConsoleReadLine]::GetBufferState([ref]$line, [ref]$cursor)

	if ($cursor -lt $line.Length) {
		[PSConsoleReadLine]::ForwardChar($key, $arg)
	} else {
		[PSConsoleReadLine]::AcceptNextSuggestionWord($key, $arg)
	}
}

# Wrap the current whitespace-delimited token in quotes.
Set-PSReadLineKeyHandler -Key 'Ctrl+"' -ScriptBlock {
	$line, $cursor = $null
	[PSConsoleReadLine]::GetBufferState([ref]$line, [ref]$cursor)
	$whitespaceChars = [char[]]@(" ", "`n", "`t")
	$startI = $line.LastIndexOfAny($whitespaceChars, $cursor - 1) + 1

	$endI = $cursor -eq $line.Length ? -1 : $line.IndexOfAny($whitespaceChars, $cursor)
	if ($endI -eq -1) {
		$endI = $line.Length
	}

	[PSConsoleReadLine]::Replace($startI, $endI - $startI, '"' + $line.Substring($startI, $endI - $startI) + '"')
	[PSConsoleReadLine]::SetCursorPosition($cursor + 1)
}

# Sometimes you want to get a property of invoke a member on what you've entered so far
# but you need parens to do that.  This binding will help by putting parens around the current selection,
# or if nothing is selected, the whole line.
Set-PSReadLineKeyHandler -Key 'Alt+(' `
			 -BriefDescription ParenthesizeSelection `
			 -LongDescription "Put parenthesis around the selection or entire line and move the cursor to after the closing parenthesis" `
			 -ScriptBlock {
	param($key, $arg)

	$selectionStart = $null
	$selectionLength = $null
	[PSConsoleReadLine]::GetSelectionState([ref]$selectionStart, [ref]$selectionLength)

	$line = $null
	$cursor = $null
	[PSConsoleReadLine]::GetBufferState([ref]$line, [ref]$cursor)
	if ($selectionStart -ne -1) {
		[PSConsoleReadLine]::Replace($selectionStart, $selectionLength, '(' + $line.SubString($selectionStart, $selectionLength) + ')')
		[PSConsoleReadLine]::SetCursorPosition($selectionStart + $selectionLength + 2)
	} else {
		[PSConsoleReadLine]::Replace(0, $line.Length, '(' + $line + ')')
		[PSConsoleReadLine]::EndOfLine()
	}
}

# Cycle through arguments on current line and select the text. This makes it easier to quickly change the argument if re-running a previously run command from the history
# or if using a psreadline predictor. You can also use a digit argument to specify which argument you want to select, i.e. Alt+1, Alt+a selects the first argument
# on the command line. 
Set-PSReadLineKeyHandler -Key Alt+a `
			 -BriefDescription SelectCommandArguments `
			 -LongDescription "Set current selection to next command argument in the command line. Use of digit argument selects argument by position" `
			 -ScriptBlock {
	param($key, $arg)
  
	$ast = $null
	$cursor = $null
	[PSConsoleReadLine]::GetBufferState([ref]$ast, [ref]$null, [ref]$null, [ref]$cursor)
  
	$asts = $ast.FindAll({
		$args[0] -is [System.Management.Automation.Language.ExpressionAst] -and
		$args[0].Parent -is [System.Management.Automation.Language.CommandAst] -and
		$args[0].Extent.StartOffset -ne $args[0].Parent.Extent.StartOffset
	}, $true)
  
	if ($asts.Count -eq 0) {
		[PSConsoleReadLine]::Ding()
		return
	}
	
	$nextAst = $null

	if ($null -ne $arg) {
		$nextAst = $asts[$arg - 1]
	} else {
		foreach ($ast in $asts) {
			if ($ast.Extent.StartOffset -ge $cursor) {
				$nextAst = $ast
				break
			}
		} 
	
		if ($null -eq $nextAst) {
			$nextAst = $asts[0]
		}
	}

	$startOffsetAdjustment = 0
	$endOffsetAdjustment = 0

	if ($nextAst -is [System.Management.Automation.Language.StringConstantExpressionAst] -and
			$nextAst.StringConstantType -ne [System.Management.Automation.Language.StringConstantType]::BareWord) {
		$startOffsetAdjustment = 1
		$endOffsetAdjustment = 2
	}
  
	[PSConsoleReadLine]::SetCursorPosition($nextAst.Extent.StartOffset + $startOffsetAdjustment)
	[PSConsoleReadLine]::SetMark($null, $null)
	[PSConsoleReadLine]::SelectForwardChar($null, ($nextAst.Extent.EndOffset - $nextAst.Extent.StartOffset) - $endOffsetAdjustment)
}
