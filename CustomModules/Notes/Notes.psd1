@{
	ModuleVersion = '0.1'
	RootModule = 'Notes.psm1'
	FunctionsToExport = @('New-Notebook', 'Get-Notebook', 'Set-Notebook', 'Remove-Notebook', 'Test-Notebook')
	RequiredModules = @('Invoke-Notepad')
}