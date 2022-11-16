@{
	RootModule = 'PSLiveEdit.psm1'
	ModuleVersion = '0.2'
	GUID = 'dd86b839-b40c-4415-b183-bc60b2a12da0'
	Author = 'Matej Kafka'

	FunctionsToExport = @("Edit-Command", "Edit-Module", "Update-LoadedModule")
	CmdletsToExport = @()
	VariablesToExport = @()
	AliasesToExport = @("edit", "editm", "reloadm")
}
