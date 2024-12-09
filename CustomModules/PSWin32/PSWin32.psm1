Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

# load CsWin32
ls $PSScriptRoot\res\CsWin32 -Filter *.dll | Import-Module


function GenerateWin32Function($GeneratedFunctions) {
    $Options = [Microsoft.Windows.CsWin32.GeneratorOptions]::new()
    $Options.EmitSingleFile = $true
    $Options.Public = $true

    $Generator = [Microsoft.Windows.CsWin32.Generator]::new("$PSScriptRoot\res\Windows.Win32.winmd", $null, $Options, $null, $null)

    $GeneratedFunctions | % {
        $Success = $Generator.TryGenerate($_, [ref]$null, [System.Threading.CancellationToken]::None)
        if (-not $Success) {
            throw "Failed to generate '$_'."
        }
    }

    $Files = $Generator.GetCompilationUnits([System.Threading.CancellationToken]::None)
    $GeneratedStr = $Files.'NativeMethods.g.cs'.ToFullString()

    Add-Type $GeneratedStr -CompilerOptions /unsafe
}

function TypeToStr($Type) {
    $Generics = $Type.GetGenericArguments()
    if (-not $Generics) {
        return $Type.Name
    } elseif ($Type.Namespace -eq "System" -and ($Type.Name -eq "Nullable" -or $Type.Name.StartsWith("Nullable``"))) {
        return (TypeToStr $Generics[0]) + "?"
    } else {
        $GenericStr = $Generics | % {TypeToStr $_}
        return $Type.Name + "[" + ($GenericStr -join ", ") + "]"
    }
}


function Invoke-PSWin32 {
    [CmdletBinding()]
    [Alias("win32")]
    param(
        [Parameter(Mandatory, ValueFromRemainingArguments)]
        [string[]]
        $GeneratedFunctions
    )

    GenerateWin32Function $GeneratedFunctions

    [Windows.Win32.PInvoke].GetMethods("DeclaredOnly,Static,Public") | group Name | % {
        $Header = "[Windows.Win32.PInvoke]::" + $_.Name
        Write-Host $Header -ForegroundColor Green
        Write-Host ("-" * $Header.Length) -ForegroundColor Green
        $_.Group | % {
            $Params = $_.GetParameters() | % {
                (TypeToStr $_.ParameterType) + " " + $_.Name
            }
            Write-Host "$(TypeToStr $_.ReturnType) $($_.Name)($($Params -join ", "))"
        }
        Write-Host ""
    }
}