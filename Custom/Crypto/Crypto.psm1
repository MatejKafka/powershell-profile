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
		$Cleartext = $Ciphertext.ToCharArray()
			| % {
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
			}
			| Join-String
		Write-Host ""
		Write-Host ("Cleartext: " + $Cleartext)
		Write-Host ""
	}
}