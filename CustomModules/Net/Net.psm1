Set-StrictMode -Version Latest


function Out-Tcp {
	param(
			[Parameter(Mandatory)]
			[string]
		$Host,
			[Parameter(Mandatory)]
			[int]
		$Port,
			[Parameter(Mandatory, ValueFromPipeline)]
			[string]
		$Message
	)

	begin {
		$sock = New-Object System.Net.Sockets.TcpClient
		$enc = New-Object System.Text.UTF8Encoding
		$sock.Connect($Host, $Port)
		$stream = $sock.GetStream()
	}
	process {
		$bytes = $enc.GetBytes($Message)
		[void]$stream.Write($bytes, 0, $bytes.Length)
	}
	end {$sock.Close()}
}

function Out-Udp {
	param(
			[Parameter(Mandatory)]
			[string]
		$Host,
			[Parameter(Mandatory)]
			[int]
		$Port,
			[Parameter(Mandatory, ValueFromPipeline)]
			[string]
		$Message,
			<# Wait for a reply after each sent packet. Only use on reliable networks,
			   as this blocks forever in case the reply packet is lost. #>
			[switch]
		$WaitForReply,
			<# Add a newline (\n) to each outgoing packet, and strip a single trailing newline from incoming packets, if present. #>
			[switch]
		$Newlines
	)

	begin {
		$sock = New-Object System.Net.Sockets.UdpClient
		$enc = New-Object System.Text.UTF8Encoding
		$sock.Connect($Host, $Port)
		# dummy for receiving, not used anywhere
		$remoteHost = New-Object System.Net.IPEndPoint([System.Net.IPAddress]::Any, 0)
	}
	process {
		if ($Newlines) {$Message = $Message + "`n"}
		$bytes = $enc.GetBytes($Message)
		[void]$sock.Send($bytes, $bytes.Length)
		if ($WaitForReply) {
			# TODO: handle decoding error
			$replyStr = $enc.GetString($sock.Receive([ref]$remoteHost))
			if ($Newlines) {
				echo ($replyStr -replace "`n$") # remove trailing newline, if any
			} else {
				echo $replyStr
			}
		}
	}
	end {$sock.Close()}
}


function Test-SshConnection {
	param(
			[Parameter(Mandatory)]
			[string]
		$Login,
			[ValidateScript({Test-Path $_})]
			[string]
		$KeyFilePath
	)

	$OrigLEC = $LastExitCode
	$Arg = if ([string]::IsNullOrEmpty($KeyFilePath)) {@()} else {@("-i", $KeyFilePath)}
	try {
		$null = $(ssh $Login -o PasswordAuthentication=no @Arg exit) 2>&1
		return $LastExitCode -eq 0
	} catch {
		return $False
	} finally {
		$LastExitCode = $OrigLEC
	}
}

function Copy-SshId {
	param(
			[Parameter(Mandatory)]
			[string]
		$Login,
			[Parameter(Mandatory)]
			[ValidateScript({Test-Path $_})]
			[string]
		$KeyFilePath
	)

	$PubKeyPath = if ([IO.Path]::GetExtension($KeyFilePath) -eq "") {
		$KeyFilePath + ".pub"
	} else {
		$KeyFilePath
	}

	$KeyFilePath = Resolve-Path $KeyFilePath

	Write-Verbose "Testing if key is already installed..."
	if (Test-SSHConnection $Login $KeyFilePath) {
		return "Key already installed."
	}

	Write-Verbose "Installing key..."
	Get-Content $PubKeyPath | ssh $Login "mkdir -p ~/.ssh && cat >> ~/.ssh/authorized_keys"
	if ($LastExitCode -gt 0) {
		throw "Could not install public key for '$Login'."
	}
	Write-Verbose "Public key successfully installed for '$Login', trying to log in..."
	if (Test-SSHConnection $Login $KeyFilePath) {
		return "Key successfully installed."
	}
	throw "Key installation failed."
}


function Get-IpAddress {
	Get-NetIPAddress
#		| ? AddressFamily -eq "IPv4"
		| ? SuffixOrigin -in @("Dhcp", "Manual")
		| ? InterfaceAlias -NotLike "vEthernet (*)"
		| ? AddressState -ne "Deprecated"
		| select InterfaceAlias, IPAddress
}

New-Alias ip Get-IpAddress
