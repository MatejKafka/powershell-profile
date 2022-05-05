Set-StrictMode -Version Latest

# I use weird color scheme in my terminal, so that my custom prompt with non-default colors will look good in both dark and light mode.
# These colors will probably look really weird in your terminal.
# I've noted the real colors for dark mode in comments for each value.
# The dark mode colors are designed for the terminal background color #000030.

# These values are used by other modules in the Prompt directory.
# Any value accepted by the Write-HostColor function is OK (in particular, hex-based CSS colors).
$UIColors = @{
	Prompt = @{
		Ok = @{
			Base = "DarkBlue" # real color: #666696
			Highlight = "Blue" # real color: #9999C9
		}
		Error = @{
			Base = "Cyan" # real color: #906060 (this one will look particularly bad with a default color scheme)
			Highlight = "DarkRed" # real color: #C99999
		}
	}
	PowerShellVersion = "DarkBlue" # real color: #666696
	Notebook = "#909060"
}

$global:PSStyle.FileInfo.Directory = $PSStyle.Foreground.BrightBlack


Export-ModuleMember -Variable UIColors
