using namespace LockedFile

Set-StrictMode -Version Latest


function WrapWin32($FnName, $Result) {
	if ($Result -ne 0) {
		throw GetException $Result, $FnName
	}
}

function GetException($ReturnStatus, $FnName) {
	$Message = [System.ComponentModel.Win32Exception]::new($ReturnStatus).Message
	return [System.ComponentModel.Win32Exception]::new($ReturnStatus, "${FnName}: ${Message}")
}


function Get-LockingProcess {
	[CmdletBinding()]
	[OutputType([System.Diagnostics.Process])]
	param(
			[Parameter(Mandatory, ValueFromPipelineByPropertyName)]
			[string]
			[ValidateScript({Test-Path -LiteralPath $_})]
		$LiteralPath
	)

	[string[]]$PathArr = [FileUtils]::GetLockedFiles($LiteralPath)

	[uint]$Handle = 0
	[string]$SessionKey = [string]::new(0, [RestartManager]::CCH_RM_SESSION_KEY)
	WrapWin32 "RmStartSession" ([RestartManager]::RmStartSession([ref]$Handle, 0, $SessionKey))

	try {
		# register the list of files we are interested in
		WrapWin32 "RmRegisterResources" ([RestartManager]::RmRegisterResources($Handle, @($PathArr).Count, $PathArr, 0, $null, 0, $null))

		# reserve room for 100 processes; if it's not enough, retry
		[uint]$pnProcInfo = 100
		[uint]$pnProcInfoNeeded = 0
		[uint]$dwRebootReasons = 0
		$rgAffectedApps = [RestartManager+RM_PROCESS_INFO[]]::new($pnProcInfo)

		while ($true) {
			# check for locks
			$Result = [RestartManager]::RmGetList($Handle, [ref]$pnProcInfoNeeded, [ref]$pnProcInfo, $rgAffectedApps, [ref]$dwRebootReasons)
			if ($Result -eq 0) {
				# success, return the list of processes (slicing only the valid entries)
				return $rgAffectedApps | Select -First $pnProcInfoNeeded `
						| % {Get-Process -Id $_.Process.dwProcessId}
			}
			if ($Result -ne [RestartManager+WinErrorCode]::ERROR_MORE_DATA) {
				throw GetException $Result "RmGetList"
			}
			# change buffer size and try again
			$pnProcInfo = $pnProcInfoNeeded
			$rgAffectedApps = [RestartManager+RM_PROCESS_INFO[]]::new($pnProcInfo)
		}
	} finally {
		WrapWin32 "RmEndSession" ([RestartManager]::RmEndSession($Handle))
	}
}
