@{
	ModuleVersion = '0.1'
	RootModule = 'Net.psm1'
	FunctionsToExport = @(
		"Out-Tcp"
		"Out-Udp"
		"Test-SshConnection"
		"Copy-SshId"
		"Get-IpAddress"
	)
	CmdletsToExport = @()
	AliasesToExport = @("ip")
}
