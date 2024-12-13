Set-StrictMode -Version Latest

[string][AllowNull()]$script:DataRoot = $null


function Resolve-VirtualPath {
	param([Parameter(Mandatory)]$Path)
	return $ExecutionContext.SessionState.Path.GetUnresolvedProviderPathFromPSPath($Path)
}

function Set-PSDataRoot {
	[CmdletBinding()]
	param([Parameter(Mandatory)][string]$DataRoot)

	if (-not (Test-Path -Type Container $DataRoot)) {
		throw "Set-PSDataRoot: Tried to set PSDataRoot to a non-existent directory: $DataRoot"
	}
	$script:DataRoot = Resolve-Path $DataRoot
}

function Get-PSDataPath {
	[CmdletBinding()]
	param([Parameter(Mandatory)][string]$Name, [switch]$Directory, [switch]$NoCreate, [string]$DefaultContentPath)

	if ($DefaultContentPath) {
		if (-not (Test-Path $DefaultContentPath)) {
			throw "-DefaultContentPath path must exist: $DefaultContentPath"
		}
		if (-not (Test-Path $DefaultContentPath -Type $(if ($Directory) {"Container"} else {"Leaf"}))) {
			# TODO: better error messages
			throw "-DefaultContentPath has incorrect type (file/directory) - does not match the -Directory switch value"
		}
	}

	if (-not $script:DataRoot) {
		throw "Get-PSDataPath: PSDataRoot not set, should be initialized in `$PROFILE during PowerShell startup by calling 'Set-PSDataRoot <path>'."
	}

	$Path = Join-Path $DataRoot $Name

	if ($NoCreate) {
		return Resolve-VirtualPath $Path
	}

	if (Test-Path $Path) {
		return Get-Item $Path
	}

	if ($DefaultContentPath) {
		$null = New-Item -Type Directory -Force (Split-Path $Path)
		return Copy-Item -Recurse $DefaultContentPath $Path -PassThru
	}

	if (-not $Directory) {
		return New-Item $Path
	} else {
		return New-Item -Type Directory $Path
	}
}
