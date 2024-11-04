function Show-Markdown {
    [Alias("smd")]
    param([Parameter(Mandatory)][string]$File)

    return (cat $File -Raw) `
        -replace "\[(.+?)\]\((.+?)\)", {$PSStyle.FormatHyperlink($_.Groups[1].Value, $_.Groups[2].Value)} `
        -replace "(?<=^|\n)(#+)(.+?)\n", {$PSStyle.Foreground.Magenta + [string]$_.Groups[1].Value + $_.Groups[2].Value + $PSStyle.Reset}
}
