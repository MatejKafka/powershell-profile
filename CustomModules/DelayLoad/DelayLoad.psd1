@{
	RootModule = 'DelayLoad.psm1'
	ModuleVersion = '0.0.1'
	GUID = '5ef90e27-152e-4926-8c23-b42846d9a3fe'
	Author = 'Matej Kafka'

	Description = "Small module to delay-load modules during session startup."

	FunctionsToExport = @('Import-ModuleDelayed', 'Invoke-Delayed')
	CmdletsToExport = @()
	VariablesToExport = @()
	AliasesToExport = @()
}

