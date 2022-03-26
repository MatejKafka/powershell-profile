$script:TODO_PATH = $null
$script:TODOS = $null

class Todo {
	[int]$Index
	[string]$Todo

	Todo([int]$Index, [string]$Todo) {
		$this.Index = $Index
		$this.Todo = $Todo
	}

	[string] ToString() {
		return "($($this.Index)) $($this.Todo)"
	}
}

function CheckInit {
	if ($null -eq $script:TODO_PATH) {
		throw "Called a function from the TODO module without initializing it first"
	}
}

function FlushTodo {
	CheckInit
	ConvertTo-Json $script:TODOS | Set-Content $script:TODO_PATH
}

function Initialize-Todo {
	param(
			[Parameter(Mandatory)]
			[string]
		$TodoFilePath
	)

	if (-not (Test-Path $TodoFilePath)) {
		New-Item $TodoFilePath
	}
	$script:TODO_PATH = Resolve-Path $TodoFilePath
	$script:TODOS = [Collections.ArrayList]@(Get-Content $script:TODO_PATH | ConvertFrom-Json)
}

function New-Todo {
	param(
			[Parameter(Mandatory)]
			[string]
		$TodoText
	)

	CheckInit
	$null = $script:TODOS.add($TodoText)
	FlushTodo

	return "Added TODO (current count: $($script:TODOS.Count))."
}

function Get-Todo {
	CheckInit
	for ($i = 0; $i -lt $script:TODOS.Count; $i++) {
		[Todo]::new($i, $script:Todos[$i])
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
		$Todos = @($Input)
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

	CheckInit
	$Todo = $script:TODOS[$TodoIndex]
	$null = $script:TODOS.RemoveAt($TodoIndex)
	FlushTodo
	echo $Todo
	echo "Removed TODO #${TodoIndex}, $($script:TODOS.Count) remaining."
}
