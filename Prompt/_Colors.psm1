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

	#LightTheme = @{
	#	Error = @{
	#		Color = [PoshCode.Pansies.RgbColor]"#F00000"
	#		CwdColor = [PoshCode.Pansies.RgbColor]"#F00000"
	#	}
	#	Ok = @{
	#		Color = [PoshCode.Pansies.RgbColor]"#333363"
	#		CwdColor = [PoshCode.Pansies.RgbColor]"#666696"
	#	}
	#}
	#DarkTheme = @{
	#	Error = @{
	#		Color = [PoshCode.Pansies.RgbColor]"#906060"
	#		CwdColor = [PoshCode.Pansies.RgbColor]"#C99999"
	#	}
	#	Ok = @{
	#		Color = [PoshCode.Pansies.RgbColor]"#666696"
	#		CwdColor = [PoshCode.Pansies.RgbColor]"#9999C9"
	#	}
	#}
}

Export-ModuleMember -Variable UIColors
