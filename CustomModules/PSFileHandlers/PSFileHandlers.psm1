Set-StrictMode -Version Latest

$script:ConfigPath = Get-PSDataPath "PSFileHandlers.psd1" `
		-DefaultContentPath $PSScriptRoot\_DefaultConfig_DO_NOT_EDIT.psd1


function ReadConfig {
	# validate that the config file is valid .psd1
	$null = Import-PowerShellDataFile $ConfigPath
	# you may be asking, "why not use Import-PowerShellDataFile instead?"
	#  https://github.com/PowerShell/PowerShell/issues/12789, that's why
	return Invoke-Expression (Get-Content -Raw $ConfigPath)
}

function OpenItem($ItemConfig, $Item, $ExtraArgs) {
	if ($ItemConfig -is [scriptblock]) {
		& $ItemConfig $Item @ExtraArgs
	} else {
		# FIXME: hacky
		if ($null -ne $ExtraArgs) {
			Write-Warning "PSFileHandlers: Passing -LineNumber is only supported when the file handler is defined as a ScriptBlock in the config file at '$ConfigPath'."
		}
		if ($ItemConfig -is [string]) {
			& (Get-Command $ItemConfig) $Item
		} elseif ($ItemConfig -is [object[]]) {
			$Command = $ItemConfig[0]
			$CmdArgs = $ItemConfig | select -Skip 1
			& (Get-Command $ItemConfig) @CmdArgs $Item
		} else {
			throw "Invalid value in config file, must be either command string, argument array, or a scriptblock: $ItemConfig (config file path: '$ConfigPath')"
		}
	}
}

function Open-Url {
	[CmdletBinding()]
	param(
			[Parameter(Mandatory, ValueFromPipeline)]
			[string]
			[ValidateScript({([Uri]$_).IsAbsoluteUri})]
		$Url
	)
	
	begin {
		# load the config here; this way, user doesn't have to explicitly reload it when it changes
		$Config = ReadConfig
	}

	process {
		OpenItem $Config.Browser $Url
	}
}

function Open-TextFile {
	[CmdletBinding()]
	param(
			[Parameter(Mandatory, ValueFromPipeline)]
			[string]
			[ValidateScript({
				if (Test-Path -Type Leaf $_) {$True}
				else {throw "File does not exist, or it's a directory: $_"}
			})]
		$Path,
			[Nullable[uint64]]
		$LineNumber,
			[switch]
		$Gui
	)

	begin {
		$Config = ReadConfig
	}

	process {
		$Path = Resolve-Path $Path
		$ExtraArgs = if ($null -ne $LineNumber) {@($LineNumber)} else {$null}

		if ($Gui) {
			OpenItem $Config.TextEditor.GUI $Path -ExtraArgs $ExtraArgs
		} else {
			OpenItem $Config.TextEditor.Terminal $Path -ExtraArgs $ExtraArgs
		}
	}
}
