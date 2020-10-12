Set-StrictMode -Version Latest

$API_URL = "https://oris.orientacnisporty.cz/API/"
$CONFIG_PATH = Join-Path $PSScriptRoot "./config.txt"

if (-not (Test-Path $CONFIG_PATH)) {
	$USER_ID = $null
} else {
	$USER_ID = Get-Content $CONFIG_PATH
}


function Invoke-APIRequest {
	param(
		[Parameter(Mandatory)]
		[hashtable]
		$GetParams
	)
	
	# quick & dirty
	$GetParams.format = "json"
	
	$Result = Invoke-WebRequest $API_URL -Method Get -Body $GetParams
	return (ConvertFrom-Json $Result).Data
}


function Set-OrisUserID {
	param(
			[Parameter(Mandatory)]
			[string]
		$UserID
	)
	
	$script:USER_ID = $UserID
	$USER_ID | Set-Content $CONFIG_PATH
}

function Get-OrisUserID {
	return $USER_ID
}

function _Get-OrisEvents {
	param(
			[Parameter(Mandatory)]
			[string] # DateTime would be cleaner, but this is simpler
		$DateFrom,
			[Parameter(Mandatory)]
			[string] # DateTime would be cleaner, but this is simpler
		$DateTo
	)
	
	return Invoke-APIRequest @{
		method = "getEventList"
		datefrom = $DateFrom
		dateto = $DateTo		
	}
}

function Get-OrisEnrolledEvents {
	if ($null -eq $USER_ID) {
		throw "No Oris user ID is set."
	}

	$Result = Invoke-APIRequest @{
		method = "getUserEventEntries"
		userid = $USER_ID
		datefrom = (Get-Date).ToString("yyyy-MM-dd")	
	}
	
	$EnrolledEvents = $Result | Get-Member -Type NoteProperty | % {$Result.($_.Name)}
	$AllEvents = _Get-OrisEvents $EnrolledEvents[0].EventDate $EnrolledEvents[$EnrolledEvents.Count - 1].EventDate
	
	return $EnrolledEvents | % {
		$e = $AllEvents.("Event_" + $_.EventID)
		return [PSCustomObject]@{
			Date = [DateTime]::ParseExact($e.Date, "yyyy-MM-dd", $null)
			Name = $e.Name + " (" + $e.Place + ")"
			Class = $_.ClassDesc
		}
	}
}

function Format-OrisEnrolledEvents {
	param(
		$Color = $null
	)

	begin {
		Write-Host -ForegroundColor $Color "Enrolled events:"
	}

	process {
		Write-Host -ForegroundColor $Color ($_.Date.ToString("d.M. ") + $_.Name + " - " + $_.Class)
	}
}