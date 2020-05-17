function Stop-ProcessWithChildren {
    param(
			[Parameter(Mandatory=$True)]
			[int]
		$processPid
    )

    Get-CimInstance -ClassName Win32_Process `
		| ? {$_.ParentProcessId -eq $processPid} `
		| % {Stop-ProcessWithChildren $_.ProcessId}
	Stop-Process $processPid
}