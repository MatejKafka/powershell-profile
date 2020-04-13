Function Format-TimeSpan([TimeSpan]$timeSpan) {
	if ($timeSpan.TotalHours -ge 24) {
		return $timeSpan.ToString("c")
	} elseif ($timeSpan.TotalMinutes -ge 5) {
		return $timeSpan.ToString("hh\:mm\:ss")
	} elseif ($timeSpan.TotalSeconds -ge 10) {
		$time = [math]::Round($timeSpan.TotalSeconds, 1)
		return [string]$time + " s"
	} else {
		$time = [math]::Round($timeSpan.TotalMilliseconds, 2)
		return [string]$time + " ms"
	}
}