#Requires -Modules Invoke-Notepad

$script:_LastTmpFile = $null
$script:_LastTmpContent = $null


Function Invoke-Scratch([switch]$ContinueLast) {
	if ($ContinueLast) {
		if ($null -eq $script:_LastTmpFile) {
			throw "There is no previous editing session."
		}
		$temp = $script:_LastTmpFile
	} else {
		$temp = New-TemporaryFile |
			Rename-Item -PassThru -NewName {[IO.Path]::ChangeExtension($_.Name, "psm1")}
		$script:_LastTmpFile = $temp
	}
	Write-Host $temp
	Invoke-Notepad $temp
	
	$content = Get-Content -Raw $temp
	if ($content -ne $null -and $content.Length -gt 0) {
		$script:_LastTmpContent = $content
		try {
			# append export declaration to end of file
			echo "`n`nExport-ModuleMember -Function * -Cmdlet * -Variable * -Alias *" >> $temp
			Import-Module -Scope Global $temp
		} finally {
			# restore original content
			Set-Content $temp $content
		}
		
		[Microsoft.PowerShell.PSConsoleReadLine]::AddToHistory($content)
	} else {
		Write-Host -ForegroundColor Red "Scratch file is empty, ignoring...."
	}
}


Function Invoke-LastScratch {
	Invoke-Scratch -ContinueLast
}
