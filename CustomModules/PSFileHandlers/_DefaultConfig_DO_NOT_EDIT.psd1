@{
	<# This entry is used to open URLs passed to `Open-Url`. #>
	Browser = "Start-Process" # this opens the URL with the default associated application

	TextEditor = @{
		<# This entry is used when `Open-TextFile` is called without the `-GUI` switch.
		   It should block until user closes the editor, but it doesn't have to be a console application. #>
		Terminal = {param($Path) Start-Process notepad.exe -ArgumentList $Path -Wait}
		<# This entry is used when `Open-TextFile` is called with the `-GUI` switch. #>
		GUI = "notepad.exe"
	}
}
