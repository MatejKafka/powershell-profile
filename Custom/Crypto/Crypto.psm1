Set-StrictMode -Version Latest

function Invoke-MonoalphabeticDecryption {
	param(
			[Parameter(Mandatory)]
			[string]
		$Ciphertext
	)

	$ALPHABET = "ABCDEFGHIJKLMNOPQRSTUVWXYZ"
	$Ciphertext = $Ciphertext.ToUpper()

	while ($true) {
		Write-Host ("     " + $ALPHABET)
		$Key = (Read-Host "Key").ToUpper()

		if ($Key -in @("/QUIT", "/EXIT", "/Q")) {
			break
		}

		# TODO: add hotkey to plot frequency analysis

		$DecryptionMapping = @{}
		for ($i = 0; $i -lt $Key.Length; $i++) {
			if ($Key[$i] -in @("-", "_")) {
				continue
			}
			$DecryptionMapping[$Key[$i]] = $ALPHABET[$i]
		}

		Write-Host ""
		Write-Host -NoNewline "           "
		$Cleartext = $Ciphertext.ToCharArray() | % {
			if ($_ -eq " ") {
				Write-Host -NoNewline " "
				return " "
			}
			if ($DecryptionMapping.ContainsKey($_)) {
				Write-Host -NoNewline " "
				$DecryptionMapping[$_]
			} else {
				Write-Host -NoNewline $_
				"-"
			}
		} | Join-String
		Write-Host ""
		Write-Host ("Cleartext: " + $Cleartext)
		Write-Host ""
	}
}


function _SliceString($Str, $Start, $Length) {
	return $Str.Substring($Start, [Math]::Min($Length, $Str.Length - $Start))
}

function _ChunkString($Str, $ChunkLength) {
	for ($i = 0; $i -lt $Str.Length; $i += $ChunkLength) {
		_SliceString $Str $i $ChunkLength
	}
}

function Invoke-TranspositionColumnDecryption {
	param(
			[Parameter(Mandatory)]
			[string]
		$Ciphertext,
		$TranspositionCallback = {param($T) $T | Write-Host}
	)

	Write-Host ""
	Write-Host "Ciphertext length: $($Ciphertext.Length)"

	$Factors = @()
	for ($i = 2; $i -lt $Ciphertext.Length; $i++) {
		if ($Ciphertext.Length % $i -eq 0) {
			$Factors += $i
		}
	}

	$Factors | % {
		Write-Host ""
		Write-Host "$_ * $($Ciphertext.Length / $_):"
		$Out = @("") * $_
		_ChunkString $Ciphertext $_ | % {
			$_.ToCharArray() | % {$i = 0} {$Out[$i] += [string]$_; $i++}
		}
		& $TranspositionCallback $Out
		pause
	}
}
