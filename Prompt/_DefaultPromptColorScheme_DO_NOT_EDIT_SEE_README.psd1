# This is a dark mode color scheme, designed for #000030 as the terminal background color.
#
# These values are used by modules in the Prompt directory.
# Any value accepted by the Write-HostColor function is OK (in particular, hex-based CSS colors).
@{
	Prompt = @{
		Ok = @{
			Base = "#666696"
			Highlight = "#9999C9"
		}
		Error = @{
			Base = "#906060"
			Highlight = "#C99999"
		}
	}
	# first line of the banner
	PowerShellVersion = "#666696"
	# this color is used to print the contents of the notebook file in the banner
	Notebook = "#909060"

	# script block that is executed when loading color scheme,
	#  use this to e.g. setup custom $PSStyle.Formatting
	# if changing global variables like $PSStyle, you must use $global:PSStyle,
	#  as this scriptblock is invoked inside a module
	SetupScript = {}
}
