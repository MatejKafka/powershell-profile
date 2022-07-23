@{
	RootModule = 'PSLiveEdit.psm1'
	ModuleVersion = '0.1'
	GUID = 'dd86b839-b40c-4415-b183-bc60b2a12da0'
	Author = 'Matej Kafka'

	FunctionsToExport = @("Edit-Command", "Edit-Module")
	CmdletsToExport = @()
	VariablesToExport = @()
	AliasesToExport = @("edit", "editm")
}
