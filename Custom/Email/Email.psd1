@{
	ModuleVersion = '0.1'
	RootModule = 'Email.psm1'
	FunctionsToExport = @('Connect-EmailServer')
	# https://github.com/jstedfast/MailKit
	RequiredAssemblies = @('.\lib\MailKit.dll')
}