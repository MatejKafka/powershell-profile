@{
	RootModule = 'PSRegioJet.psm1'
	ModuleVersion = '0.1'
	GUID = 'f3fc72a9-7a6a-4456-af03-26d125865f15'
	Author = 'Matej Kafka'

	Description = 'PowerShell client for the RegioJet API.'

	FunctionsToExport = @('Get-RJTrip', 'Get-RJStop')
	CmdletsToExport = @()
	VariablesToExport = @()
	AliasesToExport = @('rj')

	FormatsToProcess = 'PSRegioJet.Format.ps1xml'
}

