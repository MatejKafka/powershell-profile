Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

New-Alias edit Edit-Command
New-Alias editm Edit-Module


<# NOTE: this cannot remove itself (this module). #>
function _ReloadModule([psmoduleinfo]$Module) {
	Remove-Module -Force $Module
	Import-Module -Global $Module.Path -DisableNameChecking
}

# I use this instead of $Host.UI.PromptForChoice, because that requires you to press enter after your choice
function _ConfirmAction($Message) {
	$Host.UI.Write("$Message [Y/n]: ")
	$Char = $null
	try {
		while ($true) {
			$Char = $Host.UI.RawUI.ReadKey("NoEcho, IncludeKeyDown").Character
			switch ($Char) {
				{$_ -in 13, "y", "Y"} {return $true} # Enter or y
				{$_ -in "n", "N"} {return $false}
			}
		}
	} finally {
		# echo the entered char and newline
		$Host.UI.WriteLine($Char)
	}
}

class _EditableCommandName : System.Management.Automation.IValidateSetValuesGenerator {
    [String[]] GetValidValues() {
		return Get-Command -Type Alias, Cmdlet, ExternalScript, "Function" | % Name
    }
}

class _ModuleName : System.Management.Automation.IValidateSetValuesGenerator {
    [String[]] GetValidValues() {
		return Get-Module | % Name
    }
}

function Edit-Module {
	[CmdletBinding()]
	param(
			[Parameter(Mandatory)]
			[ValidateSet([_ModuleName])]
			[string]
		$Name,
			[switch]
		$Gui
	)

	$Module = Get-Module $Name
	$OrigWriteTime = (Get-Item $Module.Path).LastWriteTime

	Open-TextFile $Module.Path -Gui:$Gui

	if (-not $Gui -and $OrigWriteTime -eq (Get-Item $Module.Path).LastWriteTime) {
		Write-Host "No change, not reloading."
		return
	}
	if (_ConfirmAction "Reload module?") {
		_ReloadModule $Module
	}
}

function Edit-Command {
	[CmdletBinding()]
	param(
			[Parameter(Mandatory)]
			[ValidateSet([_EditableCommandName])]
			[string]
		$Name,
			[switch]
		$Gui
	)

	$Cmd = Get-Command $Name -Type Alias, Cmdlet, ExternalScript, "Function"
	while ($Cmd.CommandType -eq "Alias") {
		# resolve alias
		$Cmd = $Cmd.ResolvedCommand
	}

	$EditorArgs = switch ($Cmd.CommandType) {
		ExternalScript {$Cmd.Source}
		"Function" {@($Cmd.ScriptBlock.File, $Cmd.ScriptBlock.StartPosition.StartLine)}
		Cmdlet {
			# we cannot edit cmdlet, it's a DLL; instead, open the module directory
			explorer $Cmd.Module.ModuleBase
			return
		}
	}

	if (-not $EditorArgs) {
		throw "Could not find path of the module containing the command '$Name'."
	}

	$OrigWriteTime = (Get-Item $EditorArgs[0]).LastWriteTime
	Open-TextFile @EditorArgs -Gui:$Gui

	if ($Cmd.CommandType -eq "Function") {
		if (-not $Gui -and $OrigWriteTime -eq (Get-Item $EditorArgs[0]).LastWriteTime) {
			Write-Host "No change, not reloading."
			return
		}
		if (_ConfirmAction "Reload module '$($Cmd.Module.Name)'?") {
			_ReloadModule $Cmd.Module
		}
	}
}
