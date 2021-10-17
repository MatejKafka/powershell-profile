Set-StrictMode -Version Latest

Add-Type -Path $PSScriptRoot\lib\MailKit.dll

function Connect-EmailServer {
	[CmdletBinding(DefaultParameterSetName="Default")]
	param(
			[Parameter(Mandatory, ParameterSetName="Default")]
			[string]
		$HostName,
			[Parameter(Mandatory, ParameterSetName="Default")]
			[UInt16]
		$Port,
			[Parameter(Mandatory, ParameterSetName="Default")]
			[pscredential]
		$Credentials,
			[Parameter(Mandatory, ParameterSetName="File")]
			[string]
			[ValidateScript({Test-Path -LiteralPath $_ -Type Leaf})]
		$FilePath
	)

	if ($PSCmdlet.ParameterSetName -eq "File") {
		$Config = Get-Content $FilePath | ConvertFrom-Json
		$HostName = $Config.HostName
		$Port = $Config.Port
		$Credentials = [pscredential]::new($Config.UserName, ($Config.EncryptedPassword | ConvertTo-SecureString))
	}

	$Client = [MailKit.Net.Imap.ImapClient]::new()
	$Client.Connect($HostName, $Port)
	$Client.Authenticate($Credentials)
	$null = $Client.Inbox.Open([MailKit.FolderAccess]::ReadOnly)
	return $Client
}