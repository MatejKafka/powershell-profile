Set-StrictMode -Version Latest

Import-Module ListChoice



function OpenUri($Uri) {
	Start-Process "D:\_\Firefox\Firefox.lnk" -ArgumentList @($Uri)
}



class RSSItem {
	[string]$Title
	[string]$Uri
	[DateTime]$Published
	
	RSSItem($Title, $Uri, $Published) {
		$this.Title = $Title
		$this.Uri = $Uri
		$this.Published = $Published
	}
	
	[string] ToString () {
		return $this.Published.ToString("[yyyy-MM-dd] ") + $this.Title
	}
}


function Get-RSSFeed {
	param(
			[Parameter(Mandatory, ValueFromPipeline)]
			[System.Uri]
		$Uri
	)
	
	process {
		Invoke-RestMethod -Uri $Uri | % {
			$i = $_;
			
			$Title = try {
				$t = if ($_.title.GetType() -eq [string]) {$_.title} else {$_.title.'#text'}
				[System.Web.HttpUtility]::HtmlDecode($t)
			} catch {$null}
			$Link = try {
				if ($_.{link}?.GetType() -eq [string]) {$_.link} else {$_.link.href}
			} catch {$null}
			$PublishedStr = try {$_.published} catch {$i.pubDate}
			
			[RSSItem]::new($Title, $Link, $(if ($PublishedStr) {Get-Date $PublishedStr} else {$null}))
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
			[System.Uri]
		$Uri,
			[DateTime]
		$Since,
			[switch]
		$NoAutoSelect
	)
	
	begin {
		$Items = @()
	}
	
	process {
		$Items += Get-RSSFeed $Uri | ? {$Since -eq $null -or $_.Published -gt $Since}
	}
	
	end {
		Read-HostListChoice $Items -Message "Select an article to open:" -NoAutoSelect:$NoAutoSelect `
			| Invoke-RSSItem
	}
}