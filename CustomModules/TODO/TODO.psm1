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


try {
	Initialize-Todo (Get-PSDataPath "TODO.json")
} catch {}
