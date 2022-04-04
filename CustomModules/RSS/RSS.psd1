@{
	RootModule = 'RSS.psm1'
	ModuleVersion = '0.1'
	GUID = '36ac4530-94f4-4858-a941-2696c45897ac'
	Author = "Matej Kafka"
	
	FunctionsToExport = @("Get-RSSFeed", "Invoke-RSSItem", "Invoke-RSS", "Read-RSSFeedFile", "Show-RSSItem", "Edit-RSSDefaultFeedFile")
	CmdletsToExport = @()
	VariablesToExport = @()
	AliasesToExport = @("rss", "rss-edit")
}
