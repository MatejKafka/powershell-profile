@{
	RootModule = 'Email.psm1'
	ModuleVersion = '0.1'
	GUID = '2baaec4c-dfae-46c5-8204-b7de712b6ba1'
	Author = 'Matej Kafka'

	# https://github.com/jstedfast/MailKit
	RequiredAssemblies = @('.\lib\MailKit.dll')

	FunctionsToExport = @('Connect-EmailServer')
	CmdletsToExport = @()
	VariablesToExport = @()
	AliasesToExport = @()
}
