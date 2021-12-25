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
	hidden [RSSSource]$RssFeed
	hidden [string]$Uri
	[DateTime]$Published
	[string]$Author
	[string]$Title

	RSSItem($RssFeed, $Title, $Uri, $Published) {
		$this.RssFeed = $RssFeed
		$this.Uri = $Uri
		$this.Published = $Published
		$this.Author = ${RssFeed}?.Title ? $RssFeed.Title : ""
		$this.Title = $Title
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
		$Source,
			[datetime]
		$Since
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
			$Published = $PublishedStr ? (Get-Date $PublishedStr) : $null

			if ($null -eq $Since -or $Published -gt $Since) {
				[RSSItem]::new($Source, $Title, $Link, $Published)
			}
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
		$Items += Get-RSSFeed $Source -Since $Since
	}

	end {
		$Items
			| sort -Property Published
			| Read-HostListChoice -Message "Select an article to open:" -NoAutoSelect:$NoAutoSelect
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
		if ($_ -match "\s*#.*") {return} # ignore lines starting with #
		$Title, $Uri = $_ -split ":", 2
		[RSSSource]::new($Title.Trim(), $Uri.Trim())
	}

}