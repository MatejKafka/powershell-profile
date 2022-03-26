function Invoke-WithAclAccess {
	param(
			[Parameter(Mandatory)]
			[ValidateScript({Test-Path $_})]
		$Target,
			[scriptblock]
		$Fn
	)
	
	$origAcl = Get-Acl $target
	$acl = Get-Acl $target
	$user = [System.Security.Principal.WindowsIdentity]::GetCurrent().User

	$acl.SetOwner($user)
	# disable inheritance
	$acl.SetAccessRuleProtection($true, $false)

	$ace = New-Object Security.AccessControl.FileSystemAccessRule `
		$user, "FullControl", @("ContainerInherit", "ObjectInherit"), "None", "Allow"
	$acl.AddAccessRule($ace)

	try {
		Set-Acl $target $acl
		& $Fn
	} finally {
		if (Test-Path $target) {
			Set-Acl $target $origAcl
		}
	}
}