@{
	RootModule = 'LockedFile.psm1'
	ModuleVersion = '0.1'
	GUID = 'ff4f7bfe-29ea-472f-9f24-b69fac3c2e58'
	Author = 'Matej Kafka'

	RequiredAssemblies = @('.\lib\RestartManager.dll')

	FunctionsToExport = @('Get-LockingProcess')
	CmdletsToExport = @()
	VariablesToExport = @()
	AliasesToExport = @()
}
