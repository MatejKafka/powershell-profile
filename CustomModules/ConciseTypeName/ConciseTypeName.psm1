Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

$ConciseTypeMap = @{
	"System.Object" = "Object"
	"System.Management.Automation.PSObject" = "PSObject"
	"System.String" = "String"
	"string" = "String"
	"System.String[]" = "String[]"
	"System.Int32" = "Int"
	"Int32" = "Int"
	"int" = "Int"
	"System.UInt32" = "UInt"
	"UInt32" = "UInt"
	"uint" = "UInt"
	"System.Management.Automation.PSCredential" = "PSCredential"
	"System.Management.Automation.ScriptBlock" = "ScriptBlock"
	"System.Collections.Hashtable" = "Hashtable"
}

function Get-ConciseTypeName {
	[CmdletBinding(DefaultParameterSetName="TypeName")]
	param(
			[Parameter(Mandatory, Position=0, ParameterSetName="Type")]
			[type]
		$Type,
			[Parameter(Mandatory, Position=0, ParameterSetName="TypeName")]
			[string]
		$TypeName,
			[switch]
		$StripSystem
	)

	if ($Type) {
		$TypeName = $Type.FullName
	}

	$IsArray = $TypeName.EndsWith("[]")
	if ($IsArray) {
		$TypeName = $TypeName.Substring(0, $TypeName.Length - 2)
	}

	# find the concise name
	$ConciseType = if ($ConciseTypeMap.ContainsKey($TypeName)) {
		$ConciseTypeMap[$TypeName]
	} elseif ($StripSystem -and $TypeName.StartsWith("System.")) {
		$TypeName.Substring(7)
	} else {
		$TypeName
	}

	if ($IsArray) {
		$ConciseType += "[]"
	}
	return $ConciseType
}
