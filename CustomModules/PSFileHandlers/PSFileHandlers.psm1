Set-StrictMode -Version Latest

$script:ConfigPath = Get-PSDataPath "FileHandlers.psd1" `
		-DefaultContentPath $PSScriptRoot\_DefaultConfig_DO_NOT_EDIT.psd1


function ReadConfig {
	# you may be asking, "why not use Import-PowerShellDataFile instead?"
	#  https://github.com/PowerShell/PowerShell/issues/12789, that's why
	return Invoke-Expression (Get-Content -Raw $ConfigPath)
}

function OpenItem($ItemConfig, $Item) {
	if ($ItemConfig -is [string]) {
		& (Get-Command $ItemConfig) $Item
	} elseif ($ItemConfig -is [object[]]) {
		$Command = $ItemConfig[0]
		$CmdArgs = $ItemConfig | select -Skip 1
		& (Get-Command $ItemConfig) @CmdArgs $Item
	} elseif ($ItemConfig -is [scriptblock]) {
		& $ItemConfig $Item
	} else {
		throw "Invalid value in config file, must be either command string, argument array, or a scriptblock: $ItemConfig (config file path: '$ConfigPath')"
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
			[switch]
		$Gui
	)

	begin {
		$Config = ReadConfig
	}

	process {
		$Path = Resolve-Path $Path

		if ($Gui) {
			OpenItem $Config.TextEditor.GUI $Path
		} else {
			OpenItem $Config.TextEditor.Terminal $Path
		}
	}
}
