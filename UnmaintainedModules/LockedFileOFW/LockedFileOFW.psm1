# http://www.nirsoft.net/utils/opened_files_view.html
$OpenedFilesViewCmd = Get-Command "OpenedFilesView" -ErrorAction Ignore
# TODO: also check if package_bin dir is in PATH, warn otherwise
if ($null -eq $OpenedFilesViewCmd) {
	throw "Could not find OpenedFilesView (command 'OpenedFilesView'), which is used to list the locked files."
}


class ProcessLocks {
	[string]$ProcessPath
	[string[]]$PIDs
	[string[]]$Files

	ProcessLocks($ProcessPath, $PIDs, $Files) {
		$this.ProcessPath = $ProcessPath
		$this.PIDs = $PIDs
		$this.Files = $Files
	}

	[string]ToString() {
		$out = @()
		$out += "Files locked by '$($this.ProcessPath)' (PID$(if (@($this.PIDs).Count -gt 1) {"s"}): $($this.PIDs -join ", ")):"
		$out += $this.Files | select -First 5 | % {"    $_"}
		if (@($this.Files).Count -gt 5) {
			$out += "   ... ($($this.Files.Count - 5) move)"
		}
		return ($out -join "`n") + "`n"
	}
}

<# Lists processes that have a lock (an open handle without allowed sharing) on a file under $DirPath. #>
function ListProcessesLockingFiles($DirPath) {
	# OpenedFilesView always writes to a file, stdout is not supported (it's a GUI app)
	$OutFile = New-TemporaryFile
	$Procs = [Xml]::new()
	try {
		# arguments with spaces must be manually quoted
		$OFVProc = Start-Process -FilePath $OpenedFilesViewCmd -NoNewWindow -PassThru `
				-ArgumentList /sxml, "`"$OutFile`"", /nosort, /filefilter, "`"$(Resolve-Path $DirPath)`""
		
		# workaround from https://stackoverflow.com/a/23797762
		$null = $OFVProc.Handle
		$OFVProc.WaitForExit()

		if ($OFVProc.ExitCode -ne 0) {
			throw "Could not list processes locking files in '$DirPath' (OpenedFilesView returned exit code '$($Proc.ExitCode)')."
		}
		# the XML generated by OFV contains an invalid XML tag `<%_position>`, replace it
		$OutXmlStr = (Get-Content -Raw $OutFile) -replace '(<|</)%_position>', '$1percentual_position>'
		$Procs.LoadXml($OutXmlStr)
	} finally {
		rm $OutFile -ErrorAction Ignore
	}
	return $Procs.opened_files_list.item | Group-Object process_path | % {[ProcessLocks]::new(
			$_.Name, ($_.Group.process_id | select -Unique | sort), ($_.Group.full_path | select -Unique))}
}

function Get-LockedFile {
	[CmdletBinding()]
	[OutputType([ProcessLocks])]
	param(
			[Parameter(Mandatory)]
			[string]
			[ValidateScript({Test-Path -Type Container $_})]
		$DirectoryPath
	)

	# there are some locked files, find out which and report to the user
	$LockingProcs = ListProcessesLockingFiles $DirectoryPath
	if (@($LockingProcs).Count -eq 0) {
		Write-Information "No locked files found."
		return
	}

	return $LockingProcs
}

function Show-LockedFile {
	[CmdletBinding()]
	[OutputType([string])]
	param(
			[Parameter(Mandatory)]
			[string]
			[ValidateScript({Test-Path -Type Container $_})]
		$DirectoryPath
	)

	Get-LockedFile $DirectoryPath | % ToString
}
