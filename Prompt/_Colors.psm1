Set-StrictMode -Version Latest

# RGB colors for Write-Host, not needed now
#Import-Module Pansies

# I use weird color theme in my terminal, so that I can avoid importing Pansies and using full RGB output,
#  so these colors probably won't look right in your terminal
$UIColors = @{
	Prompt = @{
		Ok = @{
			Base = "DarkBlue"
			Highlight = "Blue"
		}
		Error = @{
			Base = "Cyan"
			Highlight = "DarkRed"
		}
	}
	PowerShellVersion = "DarkBlue"
	Notebook = "Cyan"
	TODO = "Yellow"
}


$PSStyle.FileInfo.Directory = $PSStyle.Foreground.BrightBlack


Export-ModuleMember -Variable UIColors
