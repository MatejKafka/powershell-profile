$VirtualPath = $PSScriptRoot + "\notes"
if (-not (Test-Path $VirtualPath)) {
	New-Item -Type Diretory $VirtualPath
}

$NOTE_DIR_PATH = Resolve-Path $VirtualPath


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

function New-Notebook {
	param(
			[Parameter(Mandatory)]
			[string]
		$NotebookName
	)

	$Path = _Get-NotebookPath $NotebookName
	if (Test-Path $Path) {
		throw "Notebook already exists: " + $NotebookName
	}
	
	$null = New-Item -Type File $Path
	echo ("Notebook created: " + $NotebookName)
}

function Set-Notebook {
	param(
			[Parameter(Mandatory)]
			[ValidateSet([NoteFile])]
			[string]
		$NotebookName,
			[switch]
		$NonModal
	)
	Invoke-Notepad -NonModal:$NonModal (_Get-NotebookPath $NotebookName)
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