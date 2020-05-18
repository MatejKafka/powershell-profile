$VirtualPath = $PSScriptRoot + "\todos.json"
if (-not (Test-Path $VirtualPath)) {
	New-Item $VirtualPath
}

$TODO_PATH = Resolve-Path $VirtualPath
$Todos = [Collections.ArrayList]@(Get-Content $TODO_PATH | ConvertFrom-Json)


function Flush-Todo {
	ConvertTo-Json $script:Todos | Set-Content $TODO_PATH
}


function New-Todo {
	param(
			[Parameter(Mandatory)]
			[string]
		$TodoText
	)
	
	$null = $script:Todos.add($TodoText)
	Flush-Todo
	
	return "Added TODO (current count: $($Todos.Count))."
}

function Get-Todo {
	for ($i = 0; $i -lt $script:Todos.Count; $i++) {
		[PSCustomObject]@{
			Index = $i
			Todo = $script:Todos[$i]
		}
	}
}

function Format-Todo {
	param(
			[Parameter(ValueFromPipeline)]
		$Todos,
		$Color
	)

	if ($MyInvocation.ExpectingInput) {
		# to get whole pipeline input as array
		$Todos = @($input)
	}
	
	if ($Todos -eq $null) {
		$Todos = Get-Todo
	}

	if (@($Todos).Count -eq 0) {
		Write-Host "No TODOs." -ForegroundColor $Color
	} else {
		$TodoRows = $Todos | % {"($($_.Index)) " + $_.Todo}
		Write-Host "TODO:" -ForegroundColor $Color
		$TodoRows | % {Write-Host $_ -ForegroundColor $Color}
	}	
}

function Remove-Todo {
	param(
			[Parameter(Mandatory)]
			[int]
		$TodoIndex
	)
	
	$Todo = $script:Todos[$TodoIndex]
	$null = $script:Todos.removerange($TodoIndex, 1)
	Flush-Todo
	echo $Todo
	return "Removed TODO #${TodoIndex}, $($script:Todos.Count) remaining."
}
