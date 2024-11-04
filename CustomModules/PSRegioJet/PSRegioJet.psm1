Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

function Invoke-RJApi($ApiPath, $QueryParams = @{}, $Headers = @{}) {
    $Segments = $QueryParams.GetEnumerator() | % {
        foreach ($v in $_.Value) {
            [uri]::EscapeDataString($_.Key) + "=" + [uri]::EscapeDataString($v)
        }
    }

    $Url = "https://brn-ybus-pubapi.sa.cz/restapi" + $ApiPath
    if ($Segments) {
        $Url += "?" + ($Segments -join "&")
    }

    return irm $Url -Headers $Headers | Write-Output
}

# irm https://brn-ybus-pubapi.sa.cz/restapi/consts/tariffs
enum Tariffs {Regular; Student}
$TariffMap = @{
    [Tariffs]::Regular = "REGULAR"
    [Tariffs]::Student = "CZECH_STUDENT_PASS_26"
}

$Stops = $null

function Get-RJStop {
    param(
        $Name = "*",
        $Country = "CZ"
    )

    if (-not $script:Stops) {
        $script:Stops = Invoke-RJApi "/consts/locations" | Write-Output
    }

    return $script:Stops
        | ? code -like $Country `
        | % cities `
        | ? {
            foreach ($n in $Name) {
                if ($_.name -like $n -or $_.aliases -like $n) {
                    return $true
                }
            }
        }
}

$VehicleIconMap = @{
    "BUS" = "🚌"
    "TRAIN" = "🚉"
}

class RJTrip {
    [datetime]$Departure
    [int]$FreeSeats
    [string]$TravelTime
    [int]$TransferCount
    [string[]]$VehicleTypes
    [float]$PriceFrom
    [float]$PriceTo

    [string] Format() {
        $Price = if ($this.PriceFrom -eq $this.PriceTo) {
            "$($this.PriceTo) Kč"
        } else {
            "$($this.PriceFrom)-$($this.PriceTo) Kč"
        }

        $Date = if ($this.Departure.Date -eq [datetime]::Today) {
            $this.Departure.ToString("HH:mm")
        } else {
            $this.Departure.ToString("d. M. HH:mm")
        }

        $Color = ""
        if ($this.FreeSeats -eq 0) {
            $Color = $global:PSStyle.Foreground.Red
            $Info = "full"
        } else {
            $Color = $global:PSStyle.Foreground.BrightGreen
            $Info = "$($this.FreeSeats) free seats, $Price"
        }

        return $Color + (($this.VehicleTypes | % {$VehicleIconMap[$_] ?? $_}) -join ", ") `
            + " $Date ($Info)" + $global:PSStyle.Reset
    }
}

function Get-RJTrip {
    [Alias("rj")]
    [OutputType([RJTrip])]
    param(
            [Parameter(Mandatory)]
            [ArgumentCompleter({
                param($commandName, $parameterName, $wordToComplete, $commandAst, $fakeBoundParameters)
                return Get-RJStop "$wordToComplete*" | % name
            })]
            [string]
        $From,
            [Parameter(Mandatory)]
            [ArgumentCompleter({
                param($commandName, $parameterName, $wordToComplete, $commandAst, $fakeBoundParameters)
                return Get-RJStop "$wordToComplete*" | % name
            })]
            [string]
        $To,
            [datetime]
        $Departure = [datetime]::Today,
            [Tariffs[]]
        $Tariffs = @([Tariffs]::Regular)
    )

    $FromStop = Get-RJStop $From
    if (-not $FromStop) {throw "Could not find -From stop: $From"}
    if (@($FromStop).Count -gt 1) {throw "Ambiguous -From stop: $From"}

    $ToStop = Get-RJStop $To
    if (-not $ToStop) {throw "Could not find -To stop: $To"}
    if (@($ToStop).Count -gt 1) {throw "Ambiguous -To stop: $To"}

    $QueryParams = @{
        tariffs = $TariffMap[$Tariffs]
        toLocationType = "CITY"
        toLocationId = $ToStop.id
        fromLocationType = "CITY"
        fromLocationId = $FromStop.id
        departureDate = $Departure.ToString("yyyy-MM-dd")
    }

    $Response = Invoke-RJApi "/routes/search/simple" $QueryParams @{"X-Currency" = "CZK"}

    return $Response.routes | % {[RJTrip]@{
        Departure = [datetime]$_.departureTime
        FreeSeats = [int]$_.freeSeatsCount
        TravelTime = $_.travelTime
        TransferCount = $_.transfersCount
        VehicleTypes = $_.vehicleTypes
        PriceFrom = [float]$_.priceFrom
        PriceTo = [float]$_.priceTo
    }}
}