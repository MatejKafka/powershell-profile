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
		New-Item -Type Directory $DataRoot
	}
	$script:DataRoot = Resolve-Path $DataRoot
}

function Get-PSDataPath {
	[CmdletBinding()]
	param([Parameter(Mandatory)][string]$Name, [switch]$Directory, [switch]$NoCreate)

	if (-not $script:DataRoot) {
		throw "Get-PSDataPath: PSDataRoot not set, should be initialized in `$PROFILE."
		}

	$Path = Join-Path $DataRoot $Name

	if ($NoCreate) {
		return Resolve-VirtualPath $Path
	}

	if (-not $Directory) {
		if (Test-Path -Type Leaf $Path) {
			return Get-Item $Path
		}
		return New-Item $Path
	} else {
		if (Test-Path -Type Container $Path) {
			return Get-Item $Path
		}
		return New-Item -Type Directory $Path
	}
}
