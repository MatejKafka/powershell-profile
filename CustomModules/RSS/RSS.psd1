@{
	ModuleVersion = '0.1'
	RootModule = 'RSS.psm1'
	
	FunctionsToExport = @("Get-RSSFeed", "Invoke-RSSItem", "Invoke-RSS", "Read-RSSFeedFile", "Show-RSSItem", "Edit-RSSDefaultFeedFile")
	CmdletsToExport = @()
	AliasesToExport = @("rss", "rss-edit")
}
