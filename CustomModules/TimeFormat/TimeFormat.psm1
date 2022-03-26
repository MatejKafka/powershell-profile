function Format-TimeSpan {
	param(
			[Parameter(Mandatory)]
			[TimeSpan]
		$TimeSpan
	)

	if ($TimeSpan.TotalDays -ge 1) {
		return $TimeSpan.ToString("c")
	} elseif ($TimeSpan.TotalMinutes -ge 5) {
		return $TimeSpan.ToString("hh\:mm\:ss")
	} elseif ($TimeSpan.TotalSeconds -ge 10) {
		$time = [math]::Round($TimeSpan.TotalSeconds, 1)
		return "{0:N1} s" -f $time
	} else {
		$time = [math]::Round($TimeSpan.TotalMilliseconds, 2)
		return "{0:N2} ms" -f $time
	}
}

function Format-Age {
	param(
			[Parameter(Mandatory)]
			[datetime]
		$When,
			[datetime]
		$ReferenceDate = (Get-Date)
	)

	$TimeSpan = $ReferenceDate - $When

	if ($TimeSpan.TotalDays -ge 2) {
		return $TimeSpan.ToString("%d") + " days, " + $TimeSpan.ToString("%h") + " hours"
	} elseif ($TimeSpan.TotalDays -ge 1) {
		return "1 day, " + $TimeSpan.ToString("%h") + " hours"
	} elseif ($TimeSpan.TotalHours -ge 1) {
		return $TimeSpan.ToString("%h") + " hours"
	} elseif ($TimeSpan.TotalMinutes -ge 1) {
		return $TimeSpan.ToString("%m") + " minutes"
	} elseif ($TimeSpan.TotalSeconds -ge 10) {
		return $TimeSpan.ToString("%s") + " seconds"
	} else {
		return "now"
	}
}