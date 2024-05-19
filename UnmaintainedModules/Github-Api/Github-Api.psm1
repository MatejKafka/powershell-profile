function Get-GitHubRelease {
	[CmdletBinding()]
	param(
			[Parameter(Mandatory, ValueFromPipeline)]
			[ValidatePattern("^[^/\s]+/[^/\s]+$")]
			[string[]]
		$Repository,
			### Retrieves tags instead of releases.
			[switch]
		$Tags
	)

	process {
		foreach ($r in $Repository) {
			$Endpoint = if ($Tags) {"tags"} else {"releases"}
			$Url = "https://api.github.com/repos/$r/$Endpoint"
			Write-Verbose "Listing GitHub releases for '$r'... (URL: $Url)"

			try {
				# piping through Write-Output enumerates the array returned by irm into individual values
				#  (see https://github.com/PowerShell/PowerShell/issues/15280)
				# -FollowRelLink automatically goes through all pages to get older releases
				Invoke-RestMethod -UseBasicParsing -FollowRelLink $Url | Write-Output
			} catch [Microsoft.PowerShell.Commands.HttpResponseException] {
				$e = $_.Exception
				if ($e.StatusCode -eq 404) {
					throw "Cannot list $Endpoint for '$r', GitHub repository does not exist."
				} elseif ($e.StatusCode -eq 403 -and $e.Response.ReasonPhrase -eq "rate limit exceeded") {
					$Limit = try {$e.Response.Headers.GetValues("X-RateLimit-Limit")} catch {}
					$LimitMsg = if ($Limit) {" (at most $Limit requests/hour are allowed)"}
					throw "Cannot list $Endpoint for '$r', GitHub API rate limit exceeded$LimitMsg."
				} else {
					throw
				}
			}
		}
	}
}