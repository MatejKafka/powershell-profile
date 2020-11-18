#Requires -Modules Stop-ProcessWithChildren

$SERVER_BIN = $PSScriptRoot + "\usb_webserver\usbwebserver.exe"
$NGROK_CONFIG_FILE = $PSScriptRoot + "\tmp_ngrok.yml"
$WEBSERVER_CONFIG_FILE = $PSScriptRoot + "\usb_webserver\settings\usbwebserver.ini"


$NGROK_CONFIG = @"
region: eu
web_addr: {1}

tunnels:    
    server:
        proto: http
        addr: {0}
        inspect: true
        bind_tls: true
"@

$WEBSERVER_CONFIG = @"
[apache]
port={0}
[mysql]
port=3307
[algemeen]
slocal=0
hide=1
local=0
root={1}
lang=English
"@


function Format-WebServerConfig {
	param($Port, $RootDirectory)
	
	# Apache needs paths in UNIX format
	$FixedRoot = (Resolve-Path $RootDirectory).Path.Replace("\", "/")
	
	# USB Webserver expects .ini to have Windows line-endings
	return $WEBSERVER_CONFIG -f @($Port, $FixedRoot) | % {
		if (-not $_.Contains("`r`n")) {
			$_.Replace("`n", "`r`n")
		}
	}
}


function Invoke-WebServer {
	param(
			[ValidateScript({Test-Path -PathType Container $_})]
			[Parameter(Mandatory)]
			[string]
		$RootDirectory,
			[switch]
		$Public,
			# if True, web interface will be available at localhost:4040
			#  to inspect and modify incoming requests
			[switch]
		$WebInterface,
			[uint16]
		$Port = 8000
	)

	$RootDirectory = Resolve-Path $RootDirectory

	# write webserver config
	Format-WebServerConfig $Port $RootDirectory | Out-File $WEBSERVER_CONFIG_FILE
	
	# start webserver
	$Process = Start-Process -PassThru $SERVER_BIN

	try {
		if ($Public) {
			# write ngrok config
			$WebInterfaceAddr = if ($WebInterface) {"localhost:4040"} else {"false"}
			$NGROK_CONFIG -f @($Port, $WebInterfaceAddr) | Out-File $NGROK_CONFIG_FILE
			# start ngrok
			ngrok start ("-config=" + (Resolve-Path $NGROK_CONFIG_FILE)) server
		} else {
			echo "Server started (port: $Port, root dir: $RootDirectory)"
			echo "Press Ctrl-C to close it"
			while ($true) {
				Start-Sleep (3600 * 24)
			}
		}
	} finally {
		Stop-ProcessWithChildren $Process.ID
		Remove-Item $WEBSERVER_CONFIG_FILE
		if ($Public) {
			Remove-Item $NGROK_CONFIG_FILE
		}
	}
}