@{
    RootModule = 'PSWin32.psm1'
    ModuleVersion = '0.1'
    GUID = '8bfaec9f-d77a-4e23-ac0a-5e9abf7a1b69'
    Author = 'Matej Kafka'

    Description = 'PowerShell wrapper for CsWin32.'

    FunctionsToExport = @('Invoke-PSWin32')
    CmdletsToExport = @()
    VariablesToExport = @()
    AliasesToExport = @('win32')
}

