function Count-Object {
	param(
		[Parameter(Mandatory, ValueFromPipeline)]
		[AllowNull()]
		$Items
	)
	
	begin {
		$UsesParam = $PSBoundParameters.ContainsKey("Items")
		$Counter = 0
	}
	
	process {
		$Counter += 1
	}
	
	end {
		if (-not $UsesParam) {
			return $Counter
		}
	
		if ($null -eq $Items) {
			return 0
		}
		if ($Items.GetType().BaseType -eq [System.Array]) {
			return $Items.Count
		}
		return 1	
	}
}

New-Alias -Name count -Value Count-Object