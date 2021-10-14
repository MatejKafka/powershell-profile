Set-StrictMode -Version Latest

Import-Module ListChoice



function OpenUri($Uri) {
	Start-Process "D:\_\Firefox\Firefox.lnk" -ArgumentList @($Uri)
}


class RSSSource {
	[string]$Title
	[System.Uri]$Uri
	
	RSSSource($Title, $Uri) {
		$this.Title = $Title
		$this.Uri = $Uri
	}
}

class RSSItem {
	[RSSSource]$RssFeed
	[string]$Title
	[string]$Uri
	[DateTime]$Published
	
	RSSItem($RssFeed, $Title, $Uri, $Published) {
		$this.RssFeed = $RssFeed
		$this.Title = $Title
		$this.Uri = $Uri
		$this.Published = $Published
	}
	
	[string] ToString () {
		$FeedTitleStr = if (${this}?.{RssFeed}?.Title) {$this.RssFeed.Title + ":    "} else {""}
		return $this.Published.ToString("[yyyy-MM-dd] ") + $FeedTitleStr + $this.Title
	}
}


function Get-RSSFeed {
	param(
			[Parameter(Mandatory, ValueFromPipeline)]
			[RSSSource]
		$Source
	)
	
	process {
		Invoke-RestMethod -Uri $Source.Uri | % {
			$i = $_;
			
			$Title = try {
				$t = if ($_.title.GetType() -eq [string]) {$_.title} else {$_.title.'#text'}
				[System.Web.HttpUtility]::HtmlDecode($t)
			} catch {$null}
			$Link = try {
				if ($_.{link}?.GetType() -eq [string]) {$_.link} else {$_.link.href}
			} catch {$null}
			$PublishedStr = try {$_.published} catch {$i.pubDate}
			
			[RSSItem]::new($Source, $Title, $Link, $(if ($PublishedStr) {Get-Date $PublishedStr} else {$null}))
		}
	}
}

function Invoke-RSSItem {
	param(
			[Parameter(Mandatory, ValueFromPipeline)]
			[RSSItem]
		$Item
	)
	
	process {
		OpenUri $Item.Uri
	}
}

function Invoke-RSS {
		param(
			[Parameter(Mandatory, ValueFromPipeline)]
			[RSSSource]
		$Source,
			[DateTime]
		$Since,
			[switch]
		$NoAutoSelect
	)
	
	begin {
		$Items = @()
	}
	
	process {
		$Items += Get-RSSFeed $Source | ? {$Since -eq $null -or $_.Published -gt $Since}
	}
	
	end {
		Read-HostListChoice $Items -Message "Select an article to open:" -NoAutoSelect:$NoAutoSelect `
			| Invoke-RSSItem
	}
}

function Read-RSSFeedFile {
	param(
			[Parameter(Mandatory, ValueFromPipeline)]
			[string]
			[ValidateScript({Test-Path -Type Leaf $_})]
		$FilePath
	)
	
	return Get-Content $FilePath | % {
		$Title, $Uri = $_ -split ":", 2
		[RSSSource]::new($Title.Trim(), $Uri.Trim())
	}

}