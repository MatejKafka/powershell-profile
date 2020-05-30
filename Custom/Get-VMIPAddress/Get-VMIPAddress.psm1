function Get-VMIPAddress {
	param(
			[Parameter(Mandatory)]
			[string]
		$VMName
	)

	$mac = (Get-VMNetworkAdapter $VMName).MacAddress -replace '..(?!$)', '$&-'
	return Get-NetNeighbor | ? LinkLayerAddress -eq $mac | Select -ExpandProperty IPAddress
}