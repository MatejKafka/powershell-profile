Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"


rm $PSScriptRoot\tmp -Recurse -ErrorAction Ignore
$null = mkdir $PSScriptRoot\tmp -Force

iwr https://www.nuget.org/api/v2/package/Microsoft.Windows.CsWin32/ -OutFile $PSScriptRoot\tmp\cswin32.zip
iwr https://www.nuget.org/api/v2/package/Microsoft.Windows.SDK.Win32Metadata/63.0.31-preview -OutFile $PSScriptRoot\tmp\metadata.zip

Expand-Archive $PSScriptRoot\tmp\cswin32.zip -Destination $PSScriptRoot\tmp\cswin32
Expand-Archive $PSScriptRoot\tmp\metadata.zip -Destination $PSScriptRoot\tmp\metadata

rm $PSScriptRoot\res -Recurse -ErrorAction Ignore
$null = mkdir $PSScriptRoot\res -Force

mv $PSScriptRoot\tmp\metadata\Windows.Win32.winmd $PSScriptRoot\res
mv $PSScriptRoot\tmp\cswin32\analyzers\cs $PSScriptRoot\res\CsWin32

rm $PSScriptRoot\tmp -Recurse