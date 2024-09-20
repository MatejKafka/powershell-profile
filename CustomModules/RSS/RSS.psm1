Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

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
	[Nullable[DateTime]]$Published
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
		$FeedTitleStr = if (${this}?.{RssFeed}?.Title) {"  (" + $this.RssFeed.Title + ")"} else {""}
		return $this.Published.ToString("[yyyy-MM-dd] ") + $this.Title + $FeedTitleStr
	}
}


function _ReadRSSFeedSingle {
	[CmdletBinding()]
	param($Source, $Since, $IsInRunspace)

	if ($IsInRunspace) {
		$ErrorActionPreference = "Stop"
		Set-StrictMode -Version Latest
		$VerbosePreference = $using:VerbosePreference
	}

	$Stopwatch = [System.Diagnostics.Stopwatch]::new()
	$Stopwatch.Start()

	foreach ($i in Invoke-RestMethod -Uri $Source.Uri -Verbose:$false) {
		$Title = try {
			$t = if ($i.title -is [string]) {$i.title}
				elseif ($i.title -is [array] -and $i.title[0] -is [string]) {$i.title[0]}
				else {$i.title.'#text'}
			[System.Web.HttpUtility]::HtmlDecode($t)
		} catch {$null}
		$Link = try {
			if ($i.link -is [string]) {$i.link} else {$i.link.href}
		} catch {$null}

		$PublishedStr = try {$i.published} catch {try {$i.pubDate} catch {$i.date}}
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
			if ($IsInRunspace) {
				# see comment in Read-RSSFeed in end {} block
				@{RssFeed=$Source; Title=$Title; Uri=$Link; Published=$Published}
			} else {
				[RSSItem]::new($Source, $Title, $Link, $Published)
			}
		}
	}

	$Stopwatch.Stop()
	Write-Verbose "Retrieving RSS feed for '$($Source.Title)' took '$($Stopwatch.Elapsed.TotalMilliseconds) ms'."
}

function Read-RSSFeed {
	[CmdletBinding()]
	param(
			[Parameter(Mandatory, ValueFromPipeline)]
			[RSSSource]
		$Source,
			[datetime]
		$Since,
			[switch]
		$Parallel
	)

	begin {
		if ($Parallel) {
			$DownloadJobs = @()
		}
	}

	process {
		if ($Parallel) {
			$DownloadJobs += Start-ThreadJob -ThrottleLimit 50 -ArgumentList @($Source, $Since, $true) -ScriptBlock $function:_ReadRSSFeedSingle
		} else {
			_ReadRSSFeedSingle $Source $Since $false -Verbose:$VerbosePreference
		}
	}

	end {
		if ($Parallel) {
			# creating RSSItem instance in another runspace has issues with runspace affinity, instead create it here
			$DownloadJobs | Receive-Job -Wait -AutoRemoveJob | % {[RSSItem]::new($_.RssFeed, $_.Title, $_.Uri, $_.Published)}
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
		if (Get-Command Open-Url -ErrorAction Ignore) {
			Open-Url $Item.Uri
		} else {
			# this opens the URL in a browser
			Start-Process $Item.Uri
		}
	}
}

function Read-RSSFeedFile {
	param(
			[Parameter(ValueFromPipeline)]
			[string]
			[ValidateScript({Test-Path -Type Leaf $_})]
		$FilePath = (Get-PSDataPath "RSS-Feeds.txt")
	)

	return Get-Content $FilePath | % {
		if ($_ -match "\s*#.*") {return} # ignore lines starting with #
		$Title, $Uri = $_ -split ":", 2
		[RSSSource]::new($Title.Trim(), $Uri.Trim())
	}

}

function Read-RSSDefaultFeed {
	[CmdletBinding()]
	[Alias("rss-list")]
	param($DaysSince = 14)

	$Since = [DateTime]::Today.AddDays(-$DaysSince)
	return Read-RSSFeedFile
		| Read-RSSFeed -Parallel -Since $Since -Verbose:$VerbosePreference
		| sort
}

function Edit-RSSDefaultFeedFile {
	[Alias("rss-edit")]
	param()

	$Path = Get-PSDataPath "RSS-Feeds.txt"
	if (Get-Command Open-TextFile -ErrorAction Ignore) {
		Open-TextFile $Path
	} else {
		# this should open the text file in a text editor
		Start-Process $Path
	}
}

