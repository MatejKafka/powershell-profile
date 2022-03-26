Set-StrictMode -Version Latest

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

	RSSItem($RssItem) {
		$this.RssFeed = $RssItem.RssFeed
		$this.Uri = $RssItem.Uri
		$this.Published = $RssItem.Published
		$this.Author = $RssItem.Author
		$this.Title = $RssItem.Title
	}

	[string] ToString () {
		$FeedTitleStr = if (${this}?.{RssFeed}?.Title) {"  (" + $this.RssFeed.Title + ")"} else {""}
		return $this.Published.ToString("[yyyy-MM-dd] ") + $this.Title + $FeedTitleStr
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
			$Published = if ($PublishedStr) {
				try {
					Get-Date $PublishedStr
				} catch {
					# try removing the day of the week and parsing the rest, in case the parsing
					#  failed due to mismatched day of the week and the rest of the date
					$Parts = $PublishedStr -split ","
					if ($Parts[0] -in @("Mon", "Tue", "Wed", "Thu", "Fri", "Sat", "Sun")) {
						Get-Date $Parts[1].Trim()
					} else {$null}
				}
			} else {$null}

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
		# this opens the URL in a browser
		Start-Process $Item.Uri
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
		$DownloadJobs = @()
	}

	process {
		$DownloadJobs += Start-ThreadJob -ThrottleLimit 50 -ArgumentList $Source, $Since {
			param($Source, $Since)
			$Duration = Measure-Command {$Feed = Get-RSSFeed $Source -Since $Since}
			$VerbosePreference = $using:VerbosePreference
			Write-Verbose "Retrieving RSS feed for '$($Source.Title)' took '$($Duration.TotalMilliseconds) ms'."
			# convert to string, transfering non-primitive types between runspaces seems to behave weirdly
			return $Feed
		}
	}

	end {
		$DownloadJobs | Receive-Job -Wait -AutoRemoveJob
			# clone, as referencing the RSSItem instance from another runspace throws weird errors
			| % {[RSSItem]::new($_)} 
			| sort
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
