Function Copy-ToVM {
	param(
			[Parameter(Mandatory)]
			[string]
			[ValidateScript({
				if (!(Test-Path $_)){
					throw "File does not exist."
				}
				return $true
			})]
		$src,
			[Parameter(Mandatory)]
			[string]
			[ValidateScript({
				if (![System.IO.Path]::IsPathRooted($_)) {
					throw "VM destination path must be absolute."
				}
				return $true
			})]
		$dst
	)

	$src = Resolve-Path $src

	$VM_NAME = "Windows 10 Pro - IDA"
	function copy-file([string]$src, [string]$dst) {
		Copy-VMFile $VM_NAME -CreateFullPath -FileSource Host `
				-SourcePath $src -DestinationPath $dst
	}

	
	if (Test-Path -PathType Leaf $src) {
		copy-file $src $dst
	} else {
		Push-Location $src
		Get-ChildItem $src -Recurse -File | % {
			$rel_path = Get-Item $_.FullName | Resolve-Path -Relative
			$target_path = Join-Path $dst $rel_path
			copy-file $_.FullName $target_path
		}
		Pop-Location
	}
}

Export-ModuleMember -Function Copy-ToVM