using module ConciseTypeName

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

# === utility functions =================================================================
function has($obj, $Property) {
	return $null -ne $obj.psobject.Properties[$Property]
}

function title($Text) {
	echo "`n$($PSStyle.Underline)$($PSStyle.Foreground.Red)$Text$($PSStyle.Reset)"
}

function writeWrappedText($str, $width, $indent = 0) {
	$indentStr = " " * $indent
	$width -= $indent
	$str = ($str -replace "\s+", " ").Trim()
	while ($str.Length -ge $width) {
		$i = $str.LastIndexOf(" ", $width)
		if ($i -ge 0) {
			echo ($indentStr + $str.Substring(0, $i))
			$str = $str.Substring($i + 1)
		} else {
			echo ($indentStr + $str.Substring(0, $width))
			$str = $str.Substring($width)
		}
	}
	if ($str.Length -gt 0) {
		echo ($indentStr + $str)
	}
}
# =======================================================================================


function renderHelp($Help, [switch]$Description) {
	$MAX_TEXT_WIDTH = [math]::Min(110, $Host.UI.RawUI.BufferSize.Width)

	echo "`n$($PSStyle.Underline)$($Help.Name)$($PSStyle.Reset)"

	if ((has $Help synopsis) -and $Help.synopsis -and (has $Help.details description)) {
		title "SYNOPSIS"
		writeWrappedText $Help.synopsis $MAX_TEXT_WIDTH
	}

	if ($Description -and (has $Help description) -and $Help.description) {
		title "DESCRIPTION"
		$First = $true
		foreach ($d in $Help.description) {
			if ($First) {$First = $false} else {echo ""}
			writeWrappedText $d.text $MAX_TEXT_WIDTH
		}
	}

	title "PARAMETERS"
	if (-not $Help.parameters.parameter) {
		echo "   No parameters"
	} else {
		$SortedParams = $Help.parameters.parameter | sort required -Descending -Stable
		foreach ($p in $SortedParams) {
			$IsLastParam = $p -eq $SortedParams[$SortedParams.Count - 1]

			$str = $p.name
			if ($p.required -ieq "true") {
				$str = $PSStyle.Underline + $str + $PSStyle.UnderlineOff
			}
			if ($Description) {
				$str = $PSStyle.Foreground.Red + $str + $PSStyle.Reset
			}
			$str = "-$str"

			if ((has $p parameterValue) -and $p.parameterValue -notin @("System.Management.Automation.SwitchParameter", "SwitchParameter")) {
				$str += $PSStyle.Foreground.FromRgb(128, 128, 128)
				$str += " <$(Get-ConciseTypeName $p.parameterValue)>"
				if ((has $p defaultValue) -and $p.defaultValue -and $p.defaultValue -ine "none") {
					$str += " = " + $p.defaultValue
				}
				$str += $PSStyle.Reset
			}

			$extraInfo = @()
			if ((has $p aliases) -and $p.aliases -and $p.aliases -ine "none") {
				$extraInfo += @("Alias: " + ($p.aliases -split "," | % {"-$($_.Trim())"} | Join-String -Separator "/"))
			}
			if ((has $p pipelineInput) -and $p.pipelineInput -ine "false") {
				$extraInfo += @("Pipeline: " + $p.pipelineInput)
			}
			if ($extraInfo) {
				$str += " ($($extraInfo -join ", "))"
			}

			echo "   $str"
			if ($Description -and (has $p description) -and $p.description) {
				foreach ($d in $p.description) {
					writeWrappedText $d.text $MAX_TEXT_WIDTH 6
					if (-not $IsLastParam) {
						echo ""
					}
				}
			}
		}
	}

	if ((has $Help returnValues) -and $help.returnValues) {
		$rv = $Help.returnValues
		if ($rv -is [string]) {
			title "RETURN VALUE"
			echo $rv
		} elseif ($rv.returnValue.Count -eq 1 -and $rv.returnValue[0].type.name -eq "System.Object") {
			# don't show, this is the default when no output is indicated
		} else {
			title "RETURN VALUE"
			foreach ($r in $rv.returnValue) {
				$descr = if ((has $r description) -and $r.description[0].text) {
					" - " + ($r.description | % text | Join-String -Separator " ")
				}
				echo ((Get-ConciseTypeName $r.type.name) + $descr)
			}
		}
	}
}

function renderTopicList($Query, $Help) {
	title "Did not find exact match for '$Query'."
	echo ""
	echo "Possible matches:"
	foreach ($h in $Help) {
		echo " - $($h.Name)"
	}
}

function Get-ConciseHelp {
	### .SYNOPSIS
	### Displays concise information about PowerShell commands and concepts.
	[CmdletBinding()]
	param(
		### Gets help about the specified command or concept. Enter the name of a cmdlet, function, provider,
		### script, or workflow, such as `Get-Member`, a conceptual article name, such as `about_Objects`, or an
		### alias, such as `ls`. Wildcard characters are permitted in cmdlet and provider names, but you can't use
		### wildcard characters to find the names of function help and script help articles.
			[Parameter(Mandatory)]
			[string]
			[ArgumentCompleter({
            	param($commandName, $parameterName, $wordToComplete,
                    $commandAst, $fakeBoundParameters)
            	$Cmds = Get-Command "$wordToComplete*" -CommandType Alias, Application, Cmdlet, ExternalScript, Function, Script
            	return $Cmds | % Name
        	})]
		$Name,
		### Show command and parameter description.
		[switch]$Description,
		### Displays the online version of a help article in the default browser. This parameter is valid only for
		### cmdlet, function, workflow, and script help articles. You can't use the Online parameter with `Get-Help`
		### in a remote session.
		[switch]$Online,
		### Returns output directly, without invoking a pager.
		[switch]$NoPager,
		### Always invokes a pager. `less`, `more.com` and `Out-Host -Paging` are used, in this order of preference.
		### By default, a pager is used for about_... help topics and when `-Description` is passed.
		[switch]$Pager
	)

	if ([bool]$Pager + [bool]$NoPager + [bool]$Online -gt 1) {
		throw "At most one of '-Pager', '-NoPager' or '-Online' may be passed."
	}

	if ($Online) {
		return Get-Help $Name -Online
	}

	$ShouldUsePager = $false

	$Help = Get-Help $Name
	if (-not $Help) {
		# this happens e.g. with `Get-AppPackage` (at least for me)
		return
	}

	$Output = if ($Help -is [array]) {
		# we did not get an exact match, and Get-Help returned a list of matching topics
		$o = renderTopicList $Name $Help
		$ShouldUsePager = @($o).Count -gt 20
		$o
	} elseif ($Help -is [string]) {
		# common for about_... help topics
		# these are typically long, so we use a pager
		$ShouldUsePager = $true
		$Help
	} else {
		# use pager if -Description is set
		$ShouldUsePager = [bool]$Description
		renderHelp $Help -Description:$Description
	}

	# overrides
	if ($Pager) {$ShouldUsePager = $true}
	if ($NoPager) {$ShouldUsePager = $false}


	if (-not $ShouldUsePager) {
		return $Output
	}

	$PagerCmd = gcm less, more -ErrorAction Ignore | select -First 1
	if (-not $PagerCmd) {
		# use the built-in pager
		$Output | Out-Host -Paging
	} elseif ($PagerCmd.Name -like "less*") {
		# less -r
		$Output | & $PagerCmd -r
	} else {
		# more.com
		$Output | & $PagerCmd
	}
}