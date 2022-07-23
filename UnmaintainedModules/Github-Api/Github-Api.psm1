function Get-GithubRelease {
	param(
			<# Repository name, including org (e.g. "PowerShell/Powershell") #>
			[Parameter(Mandatory)]
			[string]
		$RepositoryName
	)
	if ($RepositoryName -notlike "*/*") {
		# if name doesn't have /, assume the Organization and repo name are the same
		$RepositoryName = "$RepositoryName/$RepositoryName"
	}

	$Uri = "https://api.github.com/repos/$RepositoryName/releases"
	Write-Verbose "Listing GitHub releases for '$RepositoryName'... (URL: $Uri)"
	# -FollowRelLink automatically goes through all pages to get older releases
	# | % {$_} flattens the pages to single linear stream of releases
	return Invoke-RestMethod -Uri $Uri -FollowRelLink | % {$_}
}
