Set-StrictMode -Version Latest


function Read-HostListChoice {
	[CmdletBinding()]
	param(
			[Parameter(ValueFromPipeline)]
			[array]
		$Item,
			[string]
		$Header = $null,
			[string]
		$Prompt = "Enter your choice",
			[string]
		$NoInputMessage = "No inputs provided, cannot choose.",
			[switch]
		$NoAutoSelect,
			[scriptblock]
		$FormatSb = {[string]$_}
	)

	begin {
		$i = 0
		[array]$Options = @()
	}

	process {
		if ($i -eq 0 -and $Header) {
			Write-Host $Header
		}

		$Options += $Item
		foreach ($ii in $Item) {
			Write-Host "    ($i) $(% $FormatSb -InputObject $ii)"
			$i += 1
		}
	}

	end {
		if ($i -eq 0) {
			throw $NoInputMessage
		}

		if ($i -eq 1 -and -not $NoAutoSelect) {
			Write-Host "Automatically selected only possible option: '$Options'."
			return $Options
		}

		while ($true) {
			$ChoiceStr = Read-Host ($Prompt + " (0 - $($i-1))")
			try {
				$UserChoice = [int]::Parse($ChoiceStr)
			} catch {
				Write-Host "Input must be a number."
				continue
			}
			if ($UserChoice -ge 0 -and $UserChoice -lt $i) {break}
			Write-Host "Input not in range."
		}
		return $Options[$UserChoice]
	}
}
