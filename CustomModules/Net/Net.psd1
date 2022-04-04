@{
	RootModule = 'Net.psm1'
	ModuleVersion = '0.1'
	GUID = '37b49e02-7b72-45dd-8933-2a4a82fea2e9'
	Author = 'Matej Kafka'

	FunctionsToExport = @(
		"Out-Tcp"
		"Out-Udp"
		"Test-SshConnection"
		"Copy-SshId"
		"Get-IpAddress"
	)
	VariablesToExport = @()
	CmdletsToExport = @()
	AliasesToExport = @("ip")
}
