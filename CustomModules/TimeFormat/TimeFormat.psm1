function Format-TimeSpan {
	[CmdletBinding()]
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
	} elseif ($TimeSpan -ne 0) {
		$time = [math]::Round($TimeSpan.TotalMilliseconds, 2)
		return "{0:N2} ms" -f $time
	} else {
		return "0 ms"
	}
}

function Format-Age {
	[CmdletBinding()]
	param(
			[Parameter(Mandatory)]
			[datetime]
		$When,
			[datetime]
		$ReferenceDate = (Get-Date)
	)

	switch ($ReferenceDate - $When) {
		{$_.TotalDays -ge 2} {return $_.ToString("%d") + " days, " + $_.ToString("%h") + " hours"}
		{$_.TotalDays -ge 1} {return "1 day, " + $_.ToString("%h") + " hours"}
		{$_.TotalHours -ge 2} {return $_.ToString("%h") + " hours"}
		{$_.TotalHours -ge 1} {return "1 hour"}
		{$_.TotalMinutes -ge 2} {return $_.ToString("%m") + " minutes"}
		{$_.TotalMinutes -ge 1} {return "1 minute"}
		{$_.TotalSeconds -ge 5} {return $_.ToString("%s") + " seconds"}
		default {return "now"}
	}
}
