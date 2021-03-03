function Get-GithubRelease {
	param(
			<# Repository name, including org (e.g. "PowerShell/Powershell") #>
			[Parameter(Mandatory)]
			[ValidateScript({$_.Contains("/")})]
			[string]
		$RepositoryName
	)
	
	return Invoke-RestMethod -Uri "https://api.github.com/repos/$RepositoryName/releases"
}