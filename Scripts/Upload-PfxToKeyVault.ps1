[cmdletbinding()]
param (
    [string]$FileName,
    [string]$Password,
    [string]$VaultName,
    [string]$SecretName
)
Push-Location $PSScriptRoot
$fileContentBytes = Get-Content $FileName -Encoding Byte
$fileContentEncoded = [System.Convert]::ToBase64String($fileContentBytes)

$jsonObject = @"
{
  "data": "$filecontentencoded",
  "dataType" :"pfx",
  "password": "$Password"
}
"@

$jsonObjectBytes = [System.Text.Encoding]::UTF8.GetBytes($jsonObject)
$jsonEncoded = [System.Convert]::ToBase64String($jsonObjectBytes)

$secret = ConvertTo-SecureString -String $jsonEncoded -AsPlainText -Force
Set-AzureKeyVaultSecret -VaultName $VaultName -Name $SecretName -SecretValue $secret
Pop-Location