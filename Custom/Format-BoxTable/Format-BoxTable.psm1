function Format-BoxTable {
	param(
			[Parameter(Mandatory)]
			[string]
		$Header,
			[Parameter(Mandatory, ValueFromPipeline)]
			[string[]]
		$Rows,
			[string]
		$EmptyMessage = "No data.",
			[int]
		$Padding = 1,
			[switch]
		$AlignCenter,
		$Color
	)

	if ($MyInvocation.ExpectingInput) {
		# to get whole pipeline input as array
		$Rows = @($input)
	}
	
	if (@($Rows).Count -eq 0) {
		$Rows = @($EmptyMessage)
	}

	$PaddingStr = " " * $Padding
	$Rows = $Rows | % {
		$PaddingStr + $_ + $PaddingStr
	}
	$Header = $PaddingStr + $Header + $PaddingStr
	
	$MaxLen = $Header.Length
	$Rows | % {
		if ($_.Length -gt $MaxLen) {
			$MaxLen = $_.Length
		}
	}
	
	$TableMargin = if ($AlignCenter) {
		[Math]::Floor(($Host.UI.RawUI.WindowSize.Width - 2 - $MaxLen) / 2)
	} else {1}
	$Spacing = " " * $TableMargin
	
	# top border
	Write-Host ($Spacing + "╔" + "═" * $MaxLen + "╗") -ForegroundColor $color
	
	# header
	$Margin = $MaxLen - $Header.Length
	$LMargin = [Math]::Floor($Margin / 2)
	Write-Host ($Spacing + "║" + " " * $LMargin + $Header + " " * ($Margin - $LMargin) + "║") -ForegroundColor $Color

	
	$Rows | % {
		$RightMargin = $MaxLen - $_.Length
		Write-Host ($Spacing + "║" + " " * $MaxLen + "║") -ForegroundColor $Color
		Write-Host ($Spacing + "║" + $_ + " " * $RightMargin + "║") -ForegroundColor $Color
	}
	
	Write-Host ($Spacing + "╚" + "═" * $MaxLen + "╝") -ForegroundColor $color
}
