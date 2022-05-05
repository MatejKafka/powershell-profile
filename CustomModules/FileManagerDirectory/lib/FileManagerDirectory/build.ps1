Push-Location $PSScriptRoot
try {
	dotnet build --configuration Release
	if ($LastExitCode -ne 0) {
		throw "Build failed (see above)."
	}
	cp .\bin\Release\netstandard2.1\*.dll .. -Force
} catch {
	pause
	throw
} finally {
	Pop-Location
}
