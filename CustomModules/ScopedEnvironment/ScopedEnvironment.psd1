@{
	RootModule = 'ScopedEnvironment.psm1'
	ModuleVersion = '0.1'
	GUID = '7318a81c-00bc-499d-a1ac-e0e3a1493bb9'
	Author = "Matej Kafka"
	
	FunctionsToExport = @("Invoke-WithEnvironment")
	CmdletsToExport = @()
	VariablesToExport = @()
	AliasesToExport = @("env")
}
