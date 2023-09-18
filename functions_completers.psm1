Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

# do not export anything
Export-ModuleMember


$Flags = [System.Reflection.BindingFlags]"Instance, NonPublic"
$Context = $ExecutionContext.GetType().GetField("_context", $Flags).GetValue($ExecutionContext)
$NativeProp = $Context.GetType().GetProperty("NativeArgumentCompleters", $Flags)

function Set-SubstituteCompleter($CommandName, $CompleterModuleName) {
    $Context = $script:Context
    $NativeProp = $script:NativeProp
    Register-ArgumentCompleter -CommandName $CommandName -ScriptBlock {
        # import the actual completer to replace this one
        Import-Module -Global $CompleterModuleName -ErrorAction Ignore
        # forward it once
        $Completer = $NativeProp.GetValue($Context)[$CommandName]
        return & $Completer @Args
    }.GetNewClosure()
}


# wsl.exe completions
Set-SubstituteCompleter wsl WSLTabCompletion
# completions for git.exe, much faster than posh-git
Set-SubstituteCompleter git PSGitCompletions
# hyperfine
Set-SubstituteCompleter hyperfine D:\_\hyperfine\app\autocomplete\_hyperfine.ps1
# task
Set-SubstituteCompleter task D:\_\Task\app\completion\ps\task.ps1

Set-SubstituteCompleter delta $PSScriptRoot\CustomModules\carapace-completions\carapace.ps1
Set-SubstituteCompleter mpv $PSScriptRoot\CustomModules\carapace-completions\carapace.ps1
Set-SubstituteCompleter nvim $PSScriptRoot\CustomModules\carapace-completions\carapace.ps1
Set-SubstituteCompleter python $PSScriptRoot\CustomModules\carapace-completions\carapace.ps1
Set-SubstituteCompleter ssh $PSScriptRoot\CustomModules\carapace-completions\carapace.ps1
Set-SubstituteCompleter ssh-agent $PSScriptRoot\CustomModules\carapace-completions\carapace.ps1
Set-SubstituteCompleter ssh-keygen $PSScriptRoot\CustomModules\carapace-completions\carapace.ps1