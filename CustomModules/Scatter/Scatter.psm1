Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

function Out-ScatterPlot {
	[CmdletBinding()]
	[Alias("scatter")]
	param(
		[Parameter(ValueFromPipeline)]$InputObject,
		[switch]$Line,
		[switch]$NoPoint
	)

	begin {
		$Args = @()
		if ($Line) {$Args += ("-l")}
		if ($NoPoint) {$Args += @("-p")}

	    # forward input to the Python script
	    $Pipeline = {python $PSScriptRoot/scatter.py @Args}.GetSteppablePipeline($myInvocation.CommandOrigin)
	    $Pipeline.Begin($PSCmdlet)
	}

	process {$Pipeline.Process($_)}
	end {$Pipeline.End()}
}

