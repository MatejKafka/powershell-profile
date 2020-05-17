Function Assert-Admin {
	$currentPrincipal = [Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()
	$isAdmin = $currentPrincipal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
	
	if (-not $isAdmin) {
		raise "This must be run with administrator privilege."
	}
}
