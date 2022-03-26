function Read-HostListChoice {
	[CmdletBinding()]
	param(
			[Parameter(Mandatory, ValueFromPipeline)]
		$Choices,
			[string]
		$Message = $null,
			[string]
		$Prompt = "Enter your choice",
			[string]
		$NoInputMessage = "No inputs provided, cannot choose.",
			[switch]
		$NoAutoSelect
	)

	if ($MyInvocation.ExpectingInput) {
		# to get whole pipeline input as array
		$Choices = @($input)
	}

	if (@($Choices).Count -eq 0) {
		throw $NoInputMessage
	}

	if (-not [string]::IsNullOrEmpty($Message)) {
		Write-Host $Message
	}

	$i = 0
	$Choices | % {
		Write-Host "    ($i) $_"
		$i += 1
	}

	if ($i -eq 1 -and -not $NoAutoSelect) {
		Write-Host "Automatically selected only possible option: '$Choices'."
		return $Choices
	}

	while ($true) {
		$ChoiceStr = Read-Host ($Prompt + " (0 - $($i-1))")
		try {
			$Choice = [int]::Parse($ChoiceStr)
		} catch {
			Write-Host "Input must be a number."
			continue
		}
		if ($Choice -ge 0 -and $Choice -lt $i) {break}
		Write-Host "Input not in range."
	}
	return $Choices[$Choice]
}