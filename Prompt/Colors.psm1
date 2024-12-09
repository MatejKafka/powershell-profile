Set-StrictMode -Version Latest

# use .ps1 instead of .psd1 to allow deeper customization (e.g. detecting the terminal and changing the the based on it)
$ColorSchemePath = Get-PSDataPath "PromptColorScheme.ps1" `
		-DefaultContentPath $PSScriptRoot\_DefaultPromptColorScheme_DO_NOT_EDIT_SEE_README.ps1

# load colors
$UIColors = & $ColorSchemePath

# run the custom setup script
$null = & $UIColors.SetupScript

Export-ModuleMember -Variable UIColors
