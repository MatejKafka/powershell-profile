Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

# unfortunately, this must be global, otherwise the queue
#  wouldn't be accessible from the event handler
$global:_DelayLoad_ScriptQueue = [System.Collections.Generic.Queue[scriptblock]]::new()


function OnIdleEventHandler {
	$Script = $global:_DelayLoad_ScriptQueue.Dequeue()
	# if an exception occurs in an event handler, it is unregistered, so catch it instead
	# if we want to see it, we have to write it out using Write-Host
	$(try {
		$null = & $Script
	} catch {$_}) 2>&1 | Out-String -Stream | Write-Host -ForegroundColor Red

	if ($global:_DelayLoad_ScriptQueue.Count -eq 0) {
		# queue is empty, the event handler will be restarted when more scripts are added
		$Event | Unregister-Event
	}
}

function Invoke-Delayed {
	[CmdletBinding()]
	param(
			[Parameter(Mandatory)]
			[scriptblock]
		$Script
	)

	$global:_DelayLoad_ScriptQueue.Enqueue($Script)
	if ($global:_DelayLoad_ScriptQueue.Count -gt 1) {
		# there are some scripts already in the queue;
		#  therefore, the event handler should be already up
		return
	}

	$null = Register-EngineEvent PowerShell.OnIdle -Action $function:OnIdleEventHandler
}


function Import-ModuleDelayed {
	param(
			[Parameter(Mandatory)]
			[string]
		$Name
	)

	$ParentArgs = $Args
	# 4>$null = silence verbose output
	Invoke-Delayed {Import-Module -Global $Name @ParentArgs 4>$null}.GetNewClosure()
}
