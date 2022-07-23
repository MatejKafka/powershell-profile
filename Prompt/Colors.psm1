Set-StrictMode -Version Latest

$ColorSchemePath = Get-PSDataPath "PromptColorScheme.psd1" `
		-DefaultContentPath $PSScriptRoot\_DefaultPromptColorScheme_DO_NOT_EDIT_SEE_README.psd1

# Import-PowerShellDataFile is not used because of https://github.com/PowerShell/PowerShell/issues/12789
$UIColors = Invoke-Expression (Get-Content -Raw $ColorSchemePath)

# run the custom setup script
$null = & $UIColors.SetupScript

Export-ModuleMember -Variable UIColors
