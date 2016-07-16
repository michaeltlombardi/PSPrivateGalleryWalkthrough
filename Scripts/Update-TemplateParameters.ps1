[cmdletbinding()]
Param (
    [string]$TenantGuid,
    [string]$ServicePrincipalGuid,
    [string]$UserOrGroupGuid
)
$ModifiedKeyVaultParameters = Get-Content "$(Split-Path -Parent $PSScriptRoot)\Templates\KeyVault\azuredeploy.parameters.json" | 
    ForEach-Object {
        $Processing = $_.Replace('TenantGuid',$TenantGuid) 
        $Processing = $Processing.Replace('ServicePrincipalGuid',$ServicePrincipalGuid)
        $Processing.Replace('UserOrGroupGuid',$UserOrGroupGuid)
    }

$ModifiedKeyVaultParameters | Out-File "$(Split-Path -Parent $PSScriptRoot)\Templates\KeyVault\azuredeploy.parameters.json"