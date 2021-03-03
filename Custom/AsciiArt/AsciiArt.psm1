Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

Import-Module $PSScriptRoot\chars\Block.psm1


function ConvertTo-AsciiArt {
	param(
			[Parameter(Mandatory)]
			[AllowEmptyString()]
			[string]
		$Text
	)
	
	$Out = @("") * $CHAR_HEIGHT
	$Text.ToCharArray() | % {
		$Lines = $CHARS[[string]$_].Split("`n")
		for ($i = 0; $i -lt $Lines.Count; $i++) {
			$Out[$i] += $Lines[$i]
		}
	}
	return $Out
}

function PadToHostCenter($Str) {
	$Width = $Host.UI.RawUI.BufferSize.Width
	$PadLeft = ($Width - $Str.Length) / 2
	$PadRight = $Width - $Str.Length - $PadLeft - 1
	return " " * $PadLeft + $Str + " " * $PadRight
}

function Write-HostAsciiArt {
	param(
			[Parameter(Mandatory)]
			[AllowEmptyString()]
			[string]
		$Text,
			[string]
		$Color = "White",
			[switch]
		$Center
	)

	for ($i = 0; $i -lt $CHAR_HEIGHT; $i++) {
		Write-Host ""
	}
	$Rui = $Host.UI.RawUI
	$Cursor = $Rui.CursorPosition
	$Cursor.Y -= $CHAR_HEIGHT
	$Rui.CursorPosition = $Cursor
	
	ConvertTo-AsciiArt $Text `
		| % {if ($Center) {PadToHostCenter $_} else {$_}} `
		| Write-Host -ForegroundColor $Color
}

function Get-AsciiArtHeight {
	return $CHAR_HEIGHT
}