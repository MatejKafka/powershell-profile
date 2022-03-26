WinGet, windows, list

Loop, %windows%
{
    id := windows%A_Index%
    WinGet, process, ProcessName, ahk_id %id%
    WinGetTitle, title, ahk_id %id%
    FileAppend, %process% %title%`n, *
}

ExitApp