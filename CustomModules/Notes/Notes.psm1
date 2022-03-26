Set-StrictMode -Version Latest

$NOTE_DIR_PATH = Get-PSDataPath "Notes" -Directory


class NoteFile : System.Management.Automation.IValidateSetValuesGenerator {
    [String[]] GetValidValues() {
        return ls $script:NOTE_DIR_PATH -File | % {
			echo $_.Name.Substring(0, $_.Name.LastIndexOf("."))
		}
    }
}


function _Get-NotebookPath {
	param($NotebookName)
	return Join-Path $NOTE_DIR_PATH ("./" + $NotebookName.ToUpper() + ".txt")
}

function Test-Notebook {
	param(
			[Parameter(Mandatory)]
			[string]
		$Name
	)
	return Test-Path (_Get-NotebookPath $Name)
}

function New-Notebook {
	param(
			[Parameter(Mandatory)]
			[ValidateScript({if (Test-Notebook $_) {throw "Notebook already exists: $_"} else {$true}})]
			[string]
		$NotebookName
	)
	$null = New-Item (_Get-NotebookPath $NotebookName)
	echo "Notebook created: $NotebookName"
}

function Set-Notebook {
	param(
			[Parameter(Mandatory)]
			[string]
		$NotebookName,
			[switch]
		$NonModal
	)
	$Path = _Get-NotebookPath $NotebookName
	if (-not (Test-Notebook $NotebookName)) {
		$null = Read-Host "Notebook '$NotebookName' does not exist - press Enter to create it"
		$null = New-Item $Path
	}
	Invoke-Notepad -NonModal:$NonModal $Path
	if (-not $NonModal) {
		# the editor is now closed
		if ((Get-Item $Path).Length -eq 0) {
			# file was emptied, delete the note
			echo "Notebook is empty, deleting..."
			Remove-Item $Path
		}
	}
}

function Get-Notebook {
	param(
		[ValidateSet([NoteFile])]
		[string]
		$NotebookName
	)

	if ("" -eq $NotebookName) {
		ls $NOTE_DIR_PATH -File | % {
			echo ($_.Name.Substring(0, $_.Name.LastIndexOf(".")) + ":")
			echo (Get-Content $_)
			echo ""
		}
		return
	}

	$Path = _Get-NotebookPath $NotebookName
	if (-not (Test-Path $Path)) {
		throw "No such notebook:" + $NotebookName.ToUpper()
	}
	echo ($NotebookName.ToUpper() + ":")
	return Get-Content $Path
}

function Remove-Notebook {
	param(
		[ValidateSet([NoteFile])]
		[string]
		$NotebookName
	)

	Remove-Item (_Get-NotebookPath $NotebookName)
}
