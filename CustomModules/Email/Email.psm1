Set-StrictMode -Version Latest

class EmailServer {
	[MailKit.Net.Imap.ImapClient]$Client
	[MailKit.Net.Imap.ImapFolder]$Emails

	hidden [string]$HostName
	hidden [UInt16]$Port

	[void] Reconnect() {
		$this.Client.Connect($this.HostName, $this.Port)
	}
}

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
			[Parameter(ParameterSetName="Default")]
			[AllowNull()]
			[string]
		$Folder = "Inbox",
			[Parameter(Mandatory, ParameterSetName="File")]
			[string]
			[ValidateScript({Test-Path -LiteralPath $_ -Type Leaf})]
		$FilePath
	)

	if ($PSCmdlet.ParameterSetName -eq "File") {
		$Config = Get-Content $FilePath | ConvertFrom-Json -AsHashtable
		$Config.Credentials = [pscredential]::new($Config.UserName, ($Config.EncryptedPassword | ConvertTo-SecureString))
		$Config.Remove("UserName")
		$Config.Remove("EncryptedPassword")
		return Connect-EmailServer @Config
	}

	$Server = [EmailServer]::new()
	$Server.HostName = $HostName
	$Server.Port = $Port
	$Server.Client = [MailKit.Net.Imap.ImapClient]::new()
	$Server.Reconnect()
	$Server.Client.Authenticate($Credentials)

	# returning the folder from `if` and assigning it outside causes collection enumeration,
	#  which fails, because the folder is not open yet
	if ([string]::IsNullOrEmpty($Folder)) {
		$Server.Emails = $null
	} elseif ($Folder -eq "Inbox") {
		$Server.Emails = $Server.Client.Inbox
	} else {
		$Server.Emails = $Server.Client.GetFolder($Folder)
	}

	if ($Server.Emails) {
		$null = $Server.Emails.Open([MailKit.FolderAccess]::ReadOnly)
	}

	return $Server
}
