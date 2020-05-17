Function Format-TimeSpan {
	param(
			[Parameter(Mandatory)]
			[TimeSpan]
		$timeSpan
	)

	if ($timeSpan.TotalHours -ge 24) {
		return $timeSpan.ToString("c")
	} elseif ($timeSpan.TotalMinutes -ge 5) {
		return $timeSpan.ToString("hh\:mm\:ss")
	} elseif ($timeSpan.TotalSeconds -ge 10) {
		$time = [math]::Round($timeSpan.TotalSeconds, 1)
		return "{0:N1} s" -f $time
	} else {
		$time = [math]::Round($timeSpan.TotalMilliseconds, 2)
		return "{0:N2} ms" -f $time
	}
}