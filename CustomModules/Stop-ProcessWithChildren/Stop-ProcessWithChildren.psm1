function Stop-ProcessWithChildren {
    param(
    		[Parameter(Mandatory, Position=0, ParameterSetName="Process", ValueFromPipeline)]
    		[System.Diagnostics.Process]
    	$Process,
    		[Alias("ProcessId")]
			[Parameter(Mandatory, Position=0, ParameterSetName="Id", ValueFromPipeline, ValueFromPipelineByPropertyName)]
			[int]
		$Id
    )

    if (-not $Process) {
		$Process = Get-Process -Id $Id
    }

    $Process.Kill($true)
}